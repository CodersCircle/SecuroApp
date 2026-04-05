import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../main.dart' show appDatabase;
import 'encryption_service.dart';

// ── Server URL ────────────────────────────────────────────────
// Change to your deployed server or local dev address.
const _kServerWs =
    String.fromEnvironment('SECURO_WS', defaultValue: 'ws://localhost:8080');

// ── Session State ─────────────────────────────────────────────
enum LinkState {
  idle,
  connecting,
  waitingForMobile, // web: QR shown, waiting for mobile to scan
  connected,
  syncing,
  disconnected,
  error,
}

class SessionInfo {
  final String sessionId;
  final String qrToken;
  final int expiresIn; // seconds
  final String serverUrl;

  const SessionInfo({
    required this.sessionId,
    required this.qrToken,
    required this.expiresIn,
    required this.serverUrl,
  });

  /// The JSON payload embedded in the QR code.
  Map<String, dynamic> toQrPayload() => {
        'session_id': sessionId,
        'qr_token': qrToken,
        'server': serverUrl,
        'v': 1,
      };

  String toQrString() => jsonEncode(toQrPayload());
}

class ConnectedDevice {
  final String name;
  final String sessionId;
  final DateTime connectedAt;

  const ConnectedDevice({
    required this.name,
    required this.sessionId,
    required this.connectedAt,
  });
}

// ── Link Service ──────────────────────────────────────────────
/// Singleton that manages the WebSocket connection to the signaling server
/// for BOTH web and mobile.
///
/// Web flow  : createSession() → state=waitingForMobile → connected → data arrives
/// Mobile flow: joinSession()  → state=connected → sendVaultData()
class LinkService {
  LinkService._();
  static final LinkService instance = LinkService._();

  // ── State streams ─────────────────────────────────────────
  final _stateCtrl = StreamController<LinkState>.broadcast();
  final _dataCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();

  Stream<LinkState> get stateStream => _stateCtrl.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataCtrl.stream;
  Stream<String> get errorStream => _errorCtrl.stream;

  LinkState _state = LinkState.idle;
  LinkState get state => _state;

  SessionInfo? _session;
  ConnectedDevice? _connectedDevice;

  SessionInfo? get currentSession => _session;
  ConnectedDevice? get connectedDevice => _connectedDevice;

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // E2EE: AES-256-GCM symmetric key derived per session
  List<int>? _sessionKey;

  // ── Public API ────────────────────────────────────────────

  /// [Web only] Open a session and get a SessionInfo to render as QR.
  Future<SessionInfo?> createSession() async {
    _reconnectAttempts = 0;
    await _disconnect(notify: false);
    _setState(LinkState.connecting);

    try {
      await _connect();
      _send({'event': 'create_session'});
      // Response handled in _onMessage
      return null; // will be delivered via stateStream + currentSession
    } catch (e) {
      _setError('Failed to connect to relay server: $e');
      return null;
    }
  }

  /// [Mobile only] Scan QR → join an existing session and push vault data.
  /// [payload] = { session_id, qr_token, server }
  Future<bool> joinSession({
    required String sessionId,
    required String qrToken,
    required String serverUrl,
    required String deviceName,
  }) async {
    await _disconnect(notify: false);
    _setState(LinkState.connecting);

    try {
      await _connect(serverUrl: serverUrl);

      // Generate session key: sha256(qrToken + sessionId)
      _sessionKey = _deriveKey(qrToken + sessionId);

      _send({
        'event': 'join_session',
        'session_id': sessionId,
        'qr_token': qrToken,
        'device_name': deviceName,
      });

      return true;
    } catch (e) {
      _setError('Failed to join session: $e');
      return false;
    }
  }

  /// [Mobile only] Encrypt and send vault data to the linked web client.
  Future<void> sendVaultData() async {
    if (_state != LinkState.connected || _channel == null) return;
    _setState(LinkState.syncing);

    try {
      // Build data payload
      final passwords = await appDatabase.getAllPasswords();
      final totpList = await appDatabase.select(appDatabase.totpAccounts).get();

      final pwMaps = passwords
          .map((p) => {
                'platform': p.platformName,
                'username': p.username,
                'password':
                    EncryptionService.instance.decrypt(p.encryptedPassword),
                'group': p.groupName,
                'iconEmoji': p.iconEmoji,
                'websiteUrl': p.websiteUrl,
                'notes': p.notes,
              })
          .toList();

      final totpMaps = totpList
          .map((t) => {
                'issuer': t.issuer,
                'accountName': t.accountName,
                'secretKey': t.secretKey,
                'iconEmoji': t.iconEmoji,
                'digits': t.digits.toString(),
                'period': t.period.toString(),
              })
          .toList();

      final plain = jsonEncode({'passwords': pwMaps, 'totp': totpMaps});

      // E2EE encrypt
      final encrypted = _encrypt(plain);

      _send({
        'event': 'sync_data',
        'payload': encrypted,
      });
    } catch (e) {
      _setError('Failed to sync data: $e');
      _setState(LinkState.connected);
    }
  }

  /// Disconnect and clean up.
  Future<void> disconnect() => _disconnect(notify: true);

  // ── Internal ──────────────────────────────────────────────

  Future<void> _connect({String? serverUrl}) async {
    final uri = Uri.parse(serverUrl ?? _kServerWs);
    _channel = WebSocketChannel.connect(uri);

    // Start listening
    _channel!.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
    );

    _startPing();
    debugPrint('[Link] Connected to relay: $uri');
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> msg;
    try {
      msg = Map<String, dynamic>.from(jsonDecode(raw as String));
    } catch (e) {
      return;
    }

    final event = msg['event'] as String?;
    debugPrint('[Link] ← $event');

    switch (event) {
      // ── Web: session created ────────────────────────
      case 'session_created':
        final sessionId = msg['session_id'] as String;
        final qrToken = msg['qr_token'] as String;
        final expiresIn = (msg['expires_in'] as num).toInt();
        // Server sends its LAN IP so the QR works from a phone on the same network
        final serverUrl = (msg['server_url'] as String?) ?? _kServerWs;

        // Derive session key from qrToken + sessionId
        _sessionKey = _deriveKey(qrToken + sessionId);

        _session = SessionInfo(
          sessionId: sessionId,
          qrToken: qrToken,
          expiresIn: expiresIn,
          serverUrl: serverUrl, // ← LAN IP, not localhost
        );
        _setState(LinkState.waitingForMobile);
        break;

      // ── Both: session linked ────────────────────────
      case 'connected':
        final deviceName = msg['device_name'] as String? ?? 'Mobile Device';
        _connectedDevice = ConnectedDevice(
          name: deviceName,
          sessionId: msg['session_id'] as String? ?? '',
          connectedAt: DateTime.now(),
        );
        _setState(LinkState.connected);
        break;

      // ── Web: receive encrypted vault data ───────────
      case 'update_data':
        final cipherBlob = msg['payload'] as String?;
        if (cipherBlob != null) {
          try {
            final plain = _decrypt(cipherBlob);
            final data = Map<String, dynamic>.from(jsonDecode(plain));
            _dataCtrl.add(data);
          } catch (e) {
            _setError('Decryption failed: $e');
          }
        }
        break;

      // ── Mobile: sync acknowledged ───────────────────
      case 'sync_ack':
        _setState(LinkState.connected);
        break;

      // ── QR expired (web) ────────────────────────────
      case 'qr_expired':
        _setState(LinkState.idle);
        _session = null;
        break;

      // ── Mobile disconnected (web) ───────────────────
      case 'mobile_disconnected':
        _connectedDevice = null;
        _setState(LinkState.waitingForMobile);
        break;

      // ── Session ended ───────────────────────────────
      case 'session_ended':
        _connectedDevice = null;
        _session = null;
        _setState(LinkState.disconnected);
        break;

      // ── Errors ─────────────────────────────────────
      case 'error':
        final code = msg['code'] as String? ?? 'UNKNOWN';
        _setError(_errorCodeToMessage(code));
        _setState(LinkState.error);
        break;

      case 'pong':
        // keepalive ok
        break;
    }
  }

  void _onError(Object err) {
    debugPrint('[Link] WS error: $err');
    _setError('Connection error: $err');
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[Link] WS closed');
    if (_state == LinkState.connected || _state == LinkState.syncing) {
      _scheduleReconnect();
    } else {
      _setState(LinkState.disconnected);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setState(LinkState.disconnected);
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: min(2 << _reconnectAttempts, 30));
    debugPrint(
        '[Link] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () {
      if (_state != LinkState.disconnected) return;
      _connect();
    });
  }

  Future<void> _disconnect({required bool notify}) async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer = null;

    if (notify && _channel != null) {
      _send({'event': 'disconnect_session'});
    }

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _sessionKey = null;

    if (notify) {
      _connectedDevice = null;
      _session = null;
      _setState(LinkState.idle);
    }
  }

  void _send(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[Link] Send error: $e');
    }
  }

  void _setState(LinkState s) {
    if (_state == s) return;
    _state = s;
    _stateCtrl.add(s);
    debugPrint('[Link] State → $s');
  }

  void _setError(String msg) {
    debugPrint('[Link] Error: $msg');
    _errorCtrl.add(msg);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'event': 'ping'});
    });
  }

  String _errorCodeToMessage(String code) => switch (code) {
        'SESSION_NOT_FOUND' => 'Session not found. Please refresh QR.',
        'INVALID_TOKEN' => 'Invalid QR token. Please refresh.',
        'QR_EXPIRED' => 'QR code has expired. Refreshing...',
        'SESSION_TAKEN' => 'Session already linked to another device.',
        'NOT_AUTHORIZED' => 'Not authorized to send data.',
        _ => 'Unknown error: $code',
      };

  // ── E2EE: AES-256-GCM ────────────────────────────────────

  /// Derive a 32-byte key from a passphrase using SHA-256.
  List<int> _deriveKey(String passphrase) {
    final digest = pc.SHA256Digest();
    final bytes = utf8.encode(passphrase);
    return digest.process(Uint8List.fromList(bytes)).toList();
  }

  /// Encrypt plain text to base64-encoded "iv:ciphertext" using AES-256-GCM.
  String _encrypt(String plain) {
    if (_sessionKey == null) return plain; // fallback (should not happen)

    final key = Uint8List.fromList(_sessionKey!);
    final iv = _randomBytes(12); // 96-bit IV for GCM
    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params =
        pc.AEADParameters(pc.KeyParameter(key), 128, iv, Uint8List(0));
    cipher.init(true, params);

    final plainBytes = Uint8List.fromList(utf8.encode(plain));
    final cipherBytes = cipher.process(plainBytes);

    // Encode as base64(iv) + '.' + base64(ciphertext+tag)
    return '${base64Url.encode(iv)}.${base64Url.encode(cipherBytes)}';
  }

  /// Decrypt a "iv:ciphertext" base64 string back to plain text.
  String _decrypt(String encoded) {
    if (_sessionKey == null) return encoded;

    final parts = encoded.split('.');
    if (parts.length != 2) throw const FormatException('Invalid cipher format');

    final key = Uint8List.fromList(_sessionKey!);
    final iv = base64Url.decode(parts[0]);
    final cipher = Uint8List.fromList(base64Url.decode(parts[1]));

    final gcm = pc.GCMBlockCipher(pc.AESEngine());
    final params =
        pc.AEADParameters(pc.KeyParameter(key), 128, iv, Uint8List(0));
    gcm.init(false, params);

    final plainBytes = gcm.process(cipher);
    return utf8.decode(plainBytes);
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  void dispose() {
    _disconnect(notify: false);
    _stateCtrl.close();
    _dataCtrl.close();
    _errorCtrl.close();
  }
}
