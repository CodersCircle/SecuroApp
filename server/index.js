/**
 * SecuroApp WebSocket Signaling Server
 * Handles QR-based device linking: Web ↔ Mobile
 *
 * Session lifecycle:
 *   1. Web  → create_session  → server issues session_id + qr_token (60s TTL)
 *   2. QR shown on web contains: { session_id, qr_token, server_url }
 *   3. Mobile scans QR → join_session  → server links both clients
 *   4. Server → both: connected
 *   5. Mobile → sync_data (encrypted)  → server forwards to web as update_data
 *   6. Either side → disconnect_session → server ends session
 */

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const http = require('http');

const PORT = process.env.PORT || 8080;
const QR_TTL_MS = 60_000;      // QR expires after 60 s
const SESSION_TTL_MS = 30 * 60_000; // Idle session cleanup after 30 min

// ── Session store ────────────────────────────────────────────
// Map<sessionId, SessionRecord>
const sessions = new Map();

// Map<wsClient, sessionId>  — reverse lookup
const clientSession = new Map();

function makeSession(webWs) {
  const sessionId = uuidv4();
  const qrToken   = uuidv4().replace(/-/g, '').substring(0, 24);
  const expiresAt  = Date.now() + QR_TTL_MS;

  const record = {
    sessionId,
    qrToken,
    expiresAt,
    webWs,       // web client socket
    mobileWs: null,
    linked: false,
    cleanupTimer: null,
  };

  // Auto-expire QR
  record.cleanupTimer = setTimeout(() => {
    if (!record.linked) {
      sendSafe(webWs, { event: 'qr_expired', session_id: sessionId });
      destroySession(sessionId);
    }
  }, QR_TTL_MS);

  sessions.set(sessionId, record);
  clientSession.set(webWs, sessionId);

  return record;
}

function destroySession(sessionId) {
  const rec = sessions.get(sessionId);
  if (!rec) return;

  clearTimeout(rec.cleanupTimer);

  sendSafe(rec.webWs,    { event: 'session_ended', session_id: sessionId });
  sendSafe(rec.mobileWs, { event: 'session_ended', session_id: sessionId });

  clientSession.delete(rec.webWs);
  clientSession.delete(rec.mobileWs);
  sessions.delete(sessionId);
}

function sendSafe(ws, payload) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

// ── HTTP health check ─────────────────────────────────────────
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', sessions: sessions.size }));
    return;
  }
  res.writeHead(404);
  res.end();
});

// ── WebSocket server ──────────────────────────────────────────
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
  const ip = req.socket.remoteAddress;
  console.log(`[+] Client connected: ${ip}`);

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }

    const { event } = msg;

    // ── create_session (Web) ───────────────────────────
    if (event === 'create_session') {
      // Cleanup any previous session for this socket
      const prev = clientSession.get(ws);
      if (prev) destroySession(prev);

      const rec = makeSession(ws);
      sendSafe(ws, {
        event:      'session_created',
        session_id: rec.sessionId,
        qr_token:   rec.qrToken,
        expires_in: QR_TTL_MS / 1000,
      });
      console.log(`[S] Session created: ${rec.sessionId}`);
      return;
    }

    // ── join_session (Mobile) ──────────────────────────
    if (event === 'join_session') {
      const { session_id, qr_token, device_name, public_key } = msg;

      const rec = sessions.get(session_id);
      if (!rec) {
        sendSafe(ws, { event: 'error', code: 'SESSION_NOT_FOUND' });
        return;
      }
      if (rec.qrToken !== qr_token) {
        sendSafe(ws, { event: 'error', code: 'INVALID_TOKEN' });
        return;
      }
      if (Date.now() > rec.expiresAt) {
        sendSafe(ws, { event: 'error', code: 'QR_EXPIRED' });
        destroySession(session_id);
        return;
      }
      if (rec.linked) {
        sendSafe(ws, { event: 'error', code: 'SESSION_TAKEN' });
        return;
      }

      // Link mobile to session
      rec.mobileWs = ws;
      rec.linked = true;
      clearTimeout(rec.cleanupTimer);
      clientSession.set(ws, session_id);

      // Reset cleanup timer for idle session
      rec.cleanupTimer = setTimeout(() => destroySession(session_id), SESSION_TTL_MS);

      // Notify both sides
      sendSafe(rec.webWs, {
        event:      'connected',
        session_id,
        device_name: device_name || 'Mobile Device',
        public_key:  public_key || null,
      });
      sendSafe(rec.mobileWs, {
        event:      'connected',
        session_id,
        message:    'Session established',
      });

      console.log(`[L] Session linked: ${session_id} ← ${device_name || ip}`);
      return;
    }

    // ── sync_data (Mobile → Web) ───────────────────────
    if (event === 'sync_data') {
      const sessionId = clientSession.get(ws);
      const rec = sessions.get(sessionId);

      if (!rec || rec.mobileWs !== ws) {
        sendSafe(ws, { event: 'error', code: 'NOT_AUTHORIZED' });
        return;
      }

      // Forward encrypted payload to web verbatim
      sendSafe(rec.webWs, {
        event:      'update_data',
        session_id: sessionId,
        payload:    msg.payload,   // opaque encrypted blob
        timestamp:  Date.now(),
      });

      // Ack to mobile
      sendSafe(ws, { event: 'sync_ack', session_id: sessionId });
      console.log(`[D] Data forwarded: ${sessionId}`);
      return;
    }

    // ── disconnect_session (either side) ──────────────
    if (event === 'disconnect_session') {
      const sessionId = clientSession.get(ws) || msg.session_id;
      if (sessionId) destroySession(sessionId);
      return;
    }

    // ── ping / keepalive ───────────────────────────────
    if (event === 'ping') {
      sendSafe(ws, { event: 'pong', ts: Date.now() });
      return;
    }
  });

  ws.on('close', () => {
    const sessionId = clientSession.get(ws);
    if (sessionId) {
      const rec = sessions.get(sessionId);
      if (rec) {
        if (rec.webWs === ws) {
          // Web disconnected — end session entirely
          destroySession(sessionId);
        } else if (rec.mobileWs === ws) {
          // Mobile disconnected — notify web
          rec.mobileWs = null;
          rec.linked = false;
          sendSafe(rec.webWs, { event: 'mobile_disconnected', session_id: sessionId });
          clientSession.delete(ws);
          // Give web 30s to reconnect before destroying
          rec.cleanupTimer = setTimeout(() => destroySession(sessionId), 30_000);
        }
      }
    }
    console.log(`[-] Client disconnected: ${ip}`);
  });

  ws.on('error', (err) => console.error(`[!] WS error: ${err.message}`));
});

server.listen(PORT, () => {
  console.log(`🔐 SecuroApp Signaling Server running on ws://localhost:${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down...');
  sessions.forEach((_, id) => destroySession(id));
  wss.close(() => server.close(() => process.exit(0)));
});
