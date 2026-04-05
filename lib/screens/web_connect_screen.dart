import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/app_theme.dart';
import '../services/link_service.dart';
import 'web_vault_screen.dart';

/// ──────────────────────────────────────────────────────────────
/// Web App Shell — single screen for the entire web experience.
///
/// Layout (large screens ≥ 900 px wide):
///   ┌──────────────────┬───────────────────────────────────────┐
///   │  Left panel      │  Right panel                          │
///   │  (QR / status)   │  (vault dashboard OR welcome hint)    │
///   └──────────────────┴───────────────────────────────────────┘
///
/// Small screens: show "Open on desktop" message only.
/// ──────────────────────────────────────────────────────────────
/// Shown automatically on web (see app.dart). No login. No signup.
class WebConnectScreen extends StatefulWidget {
  const WebConnectScreen({super.key});

  @override
  State<WebConnectScreen> createState() => _WebConnectScreenState();
}

class _WebConnectScreenState extends State<WebConnectScreen> {
  final _link = LinkService.instance;

  StreamSubscription<LinkState>? _stateSub;
  StreamSubscription<Map<String, dynamic>>? _dataSub;
  StreamSubscription<String>? _errorSub;

  LinkState _state = LinkState.idle;
  SessionInfo? _session;
  Map<String, dynamic>? _vaultData; // non-null once synced
  String? _error;

  Timer? _qrTimer;
  int _qrSecondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _stateSub = _link.stateStream.listen(_onState);
    _dataSub = _link.dataStream.listen(_onData);
    _errorSub = _link.errorStream.listen(_onError);
    _requestSession();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _stateSub?.cancel();
    _dataSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  // ── session management ─────────────────────────────────────

  Future<void> _requestSession() async {
    setState(() {
      _error = null;
      _session = null;
    });
    await _link.createSession();
  }

  void _onState(LinkState s) {
    if (!mounted) return;
    setState(() => _state = s);
    switch (s) {
      case LinkState.waitingForMobile:
        _session = _link.currentSession;
        _startQrCountdown();
      case LinkState.connected:
      case LinkState.syncing:
      case LinkState.error:
      case LinkState.disconnected:
        _qrTimer?.cancel();
      default:
        break;
    }
    // Mobile disconnected mid-session → reset vault, go back to QR
    if (s == LinkState.disconnected && _vaultData != null) {
      setState(() => _vaultData = null);
      _requestSession();
    }
  }

  void _onData(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _vaultData = data); // right panel switches to vault view
  }

  void _onError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }

  void _startQrCountdown() {
    _qrTimer?.cancel();
    _qrSecondsLeft = 60;
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _qrSecondsLeft--);
      if (_qrSecondsLeft <= 0) {
        _qrTimer?.cancel();
        _requestSession();
      }
    });
  }

  Future<void> _disconnect() async {
    await _link.disconnect();
    if (!mounted) return;
    setState(() {
      _vaultData = null;
      _error = null;
    });
    _requestSession();
  }

  // ── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // Small screens → desktop-only guard
    if (w < 900) return const _MobileGuard();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Row(
        children: [
          // ── Left panel: fixed 360 px ─────────────────
          SizedBox(
            width: 360,
            child: _LeftPanel(
              state: _state,
              session: _session,
              qrSecondsLeft: _qrSecondsLeft,
              error: _error,
              vaultData: _vaultData,
              onRefresh: _requestSession,
              onDisconnect: _disconnect,
            ),
          ),

          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // ── Right panel: fills remaining width ───────
          Expanded(
            child: _vaultData != null
                ? WebVaultScreen(vaultData: _vaultData!)
                : _RightWelcome(state: _state),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LEFT PANEL — QR + Status
// ═══════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  final LinkState state;
  final SessionInfo? session;
  final int qrSecondsLeft;
  final String? error;
  final Map<String, dynamic>? vaultData;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;

  const _LeftPanel({
    required this.state,
    required this.session,
    required this.qrSecondsLeft,
    required this.error,
    required this.vaultData,
    required this.onRefresh,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // ── Brand header ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SecuroApp',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Web Vault',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45))),
                  ],
                ),
                const Spacer(),
                _StatusDot(state: state),
              ],
            ),
          ),

          // ── Main content ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _StatusChip(state: state),
                  const SizedBox(height: 20),

                  // QR card
                  _QrCard(
                    state: state,
                    session: session,
                    qrSecondsLeft: qrSecondsLeft,
                    error: error,
                    vaultData: vaultData,
                    onRefresh: onRefresh,
                  ),

                  const SizedBox(height: 24),

                  // Instructions or connected info
                  if (vaultData != null)
                    _ConnectedInfo(
                        device: LinkService.instance.connectedDevice,
                        onDisconnect: onDisconnect)
                  else if (state == LinkState.waitingForMobile ||
                      state == LinkState.connecting ||
                      state == LinkState.idle)
                    const _Steps(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RIGHT WELCOME (shown before vault data arrives)
// ═══════════════════════════════════════════════════════════════

class _RightWelcome extends StatelessWidget {
  final LinkState state;
  const _RightWelcome({required this.state});

  @override
  Widget build(BuildContext context) {
    final isSyncing = state == LinkState.syncing;
    final isConnected = state == LinkState.connected;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero badge ──────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 28),

              // ── Headline ────────────────────────────────────
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isSyncing
                    ? 'Receiving your encrypted vault data…'
                    : isConnected
                        ? 'Mobile connected — waiting for vault data…'
                        : 'Your secure vault is one scan away.\nNo passwords. No credentials. Just your phone.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      height: 1.6,
                    ),
              ),

              // ── Syncing indicator ───────────────────────────
              if (isSyncing) ...[
                const SizedBox(height: 28),
                Row(children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Syncing vault…',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ]),
              ],

              const SizedBox(height: 44),
              Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5)),
              const SizedBox(height: 32),

              // ── Feature pills ───────────────────────────────
              Text(
                'What you can do here',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              const _FeatureRow(
                icon: Icons.password_rounded,
                color: Color(0xFF6C63FF),
                title: 'View Passwords',
                subtitle: 'Browse & copy all your saved credentials',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.qr_code_2_rounded,
                color: Color(0xFF00BFA5),
                title: 'TOTP Codes',
                subtitle: 'Live two-factor authentication codes',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.lock_rounded,
                color: Color(0xFFFF6B6B),
                title: 'End-to-End Encrypted',
                subtitle: 'AES-256-GCM — your data never leaves unencrypted',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.link_off_rounded,
                color: Color(0xFFFFB300),
                title: 'Zero Credentials',
                subtitle: 'No username, no password — scan & done',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature row helper ─────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureRow(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45))),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MOBILE GUARD
// ═══════════════════════════════════════════════════════════════

class _MobileGuard extends StatelessWidget {
  const _MobileGuard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.desktop_mac_rounded,
                    color: AppTheme.primary, size: 46),
              ),
              const SizedBox(height: 24),
              Text('Open on Desktop',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'SecuroApp Web is designed for desktop browsers.\n'
                'Please open this page on a computer or laptop.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text('Use SecuroApp mobile to manage your vault',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  QR CARD
// ═══════════════════════════════════════════════════════════════

class _QrCard extends StatelessWidget {
  final LinkState state;
  final SessionInfo? session;
  final int qrSecondsLeft;
  final String? error;
  final Map<String, dynamic>? vaultData;
  final VoidCallback onRefresh;

  const _QrCard({
    required this.state,
    required this.session,
    required this.qrSecondsLeft,
    required this.error,
    required this.vaultData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR / status visual
            SizedBox(
              width: 220,
              height: 220,
              child: _buildQrContent(context),
            ),

            // Countdown bar (waiting state only)
            if (state == LinkState.waitingForMobile) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: qrSecondsLeft / 60,
                      minHeight: 4,
                      backgroundColor:
                          Theme.of(context).colorScheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation(qrSecondsLeft <= 10
                          ? AppTheme.error
                          : AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${qrSecondsLeft}s',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: qrSecondsLeft <= 10
                            ? AppTheme.error
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45))),
              ]),
            ],

            // Error message
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrContent(BuildContext context) {
    // Connected + vault loaded
    if (vaultData != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.success, size: 42),
          ),
          const SizedBox(height: 12),
          const Text('Vault Loaded',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.success)),
          const SizedBox(height: 4),
          const Text('Viewing on the right →', style: TextStyle(fontSize: 12)),
        ]),
      );
    }

    if (state == LinkState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == LinkState.syncing) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          const Text('Syncing vault…',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      );
    }

    if (state == LinkState.connected) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.smartphone_rounded,
                color: AppTheme.success, size: 40),
          ),
          const SizedBox(height: 12),
          const Text('Mobile Connected',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.success)),
          const SizedBox(height: 4),
          const Text('Waiting for vault data…', style: TextStyle(fontSize: 12)),
        ]),
      );
    }

    // Idle / error / disconnected
    if (state == LinkState.error ||
        state == LinkState.disconnected ||
        state == LinkState.idle) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.qr_code_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Generate QR'),
          ),
        ]),
      );
    }

    // waitingForMobile — show actual QR
    final qrData = session?.toQrString();
    if (qrData == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square, color: Color(0xFF1A1A2E)),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF1A1A2E)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STATUS CHIP
// ═══════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final LinkState state;
  const _StatusChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      LinkState.connecting => (
          'Connecting…',
          Colors.amber.shade700,
          Icons.sync_rounded
        ),
      LinkState.waitingForMobile => (
          'Waiting for scan',
          AppTheme.primary,
          Icons.qr_code_scanner_rounded
        ),
      LinkState.connected => (
          'Mobile connected',
          AppTheme.success,
          Icons.smartphone_rounded
        ),
      LinkState.syncing => (
          'Syncing vault…',
          AppTheme.primary,
          Icons.cloud_sync_rounded
        ),
      LinkState.disconnected => (
          'Disconnected',
          AppTheme.error,
          Icons.link_off_rounded
        ),
      LinkState.error => ('Error', AppTheme.error, Icons.error_outline_rounded),
      _ => ('Starting…', Colors.grey, Icons.circle_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Status dot in top-right of left panel header ──────────────

class _StatusDot extends StatelessWidget {
  final LinkState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      LinkState.connected || LinkState.syncing => AppTheme.success,
      LinkState.error || LinkState.disconnected => AppTheme.error,
      _ => Colors.amber.shade600,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEPS (instructions while waiting)
// ═══════════════════════════════════════════════════════════════

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Step(n: '1', text: 'Open SecuroApp on your phone'),
        SizedBox(height: 10),
        _Step(n: '2', text: 'Tap the Link Device icon in the top bar'),
        SizedBox(height: 10),
        _Step(n: '3', text: 'Point your camera at the QR code'),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(n,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CONNECTED INFO (shown after vault loads)
// ═══════════════════════════════════════════════════════════════

class _ConnectedInfo extends StatelessWidget {
  final ConnectedDevice? device;
  final VoidCallback onDisconnect;
  const _ConnectedInfo({this.device, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smartphone_rounded,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device?.name ?? 'Mobile Device',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      'Connected ${_timeAgo(device?.connectedAt)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: AppTheme.error,
            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onDisconnect,
          icon: const Icon(Icons.link_off_rounded, size: 18),
          label: const Text('Disconnect'),
        ),
      ],
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
