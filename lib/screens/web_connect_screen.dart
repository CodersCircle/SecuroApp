import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/app_theme.dart';
import '../services/link_service.dart';
import 'web_home_screen.dart';

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
    if (s == LinkState.waitingForMobile) {
      _session = _link.currentSession;
      _startQrCountdown();
    } else {
      _qrTimer?.cancel();
    }
  }

  void _onData(Map<String, dynamic> data) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => WebHomeScreen(initialVaultData: data),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand row ────────────────────────────────
                Row(children: [
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
                            style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        Text('Web Vault',
                            style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.45),
                                letterSpacing: 0.4)),
                      ]),
                ]),

                const SizedBox(height: 32),

                // ── Card ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                        width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status chip — left aligned
                      _WcsStatusChip(state: _state),
                      const SizedBox(height: 20),

                      // QR area — centred within card
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: _WcsQrArea(
                              state: _state,
                              session: _session,
                              error: _error,
                              onRefresh: _requestSession),
                        ),
                      ),

                      // Countdown bar
                      if (_state == LinkState.waitingForMobile) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _qrSecondsLeft / 60,
                                minHeight: 4,
                                backgroundColor: cs.outlineVariant,
                                valueColor: AlwaysStoppedAnimation(
                                    _qrSecondsLeft <= 10
                                        ? AppTheme.error
                                        : AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${_qrSecondsLeft}s',
                              style: tt.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _qrSecondsLeft <= 10
                                      ? AppTheme.error
                                      : cs.onSurface.withValues(alpha: 0.45))),
                        ]),
                      ],

                      // Error row
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 14, color: AppTheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!,
                                style: tt.labelSmall
                                    ?.copyWith(color: AppTheme.error)),
                          ),
                          TextButton(
                              onPressed: _requestSession,
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Retry')),
                        ]),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Steps ─────────────────────────────────────
                if (_state == LinkState.waitingForMobile ||
                    _state == LinkState.idle ||
                    _state == LinkState.connecting) ...[
                  Text('How to connect',
                      style: tt.labelMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  const _WcsStep(n: '1', text: 'Open SecuroApp on your phone'),
                  const SizedBox(height: 10),
                  const _WcsStep(
                      n: '2', text: 'Tap the Link Device icon in top bar'),
                  const SizedBox(height: 10),
                  const _WcsStep(
                      n: '3', text: 'Point your camera at the QR code'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WcsQrArea extends StatelessWidget {
  final LinkState state;
  final SessionInfo? session;
  final String? error;
  final VoidCallback onRefresh;
  const _WcsQrArea(
      {required this.state,
      required this.session,
      required this.error,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (state == LinkState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state == LinkState.syncing) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 3)),
        const SizedBox(height: 16),
        Text('Syncing vault…',
            style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.primary)),
      ]));
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
                color: AppTheme.success, size: 38)),
        const SizedBox(height: 12),
        Text('Mobile connected',
            style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.success)),
        const SizedBox(height: 4),
        Text('Waiting for vault data…',
            style: tt.bodySmall
                ?.copyWith(color: AppTheme.success.withValues(alpha: 0.6))),
      ]));
    }
    if (state == LinkState.error || state == LinkState.disconnected) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.qr_code_rounded,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.12)),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRefresh,
          child: const Text('Generate QR'),
        ),
      ]));
    }
    final qrData = session?.toQrString();
    if (qrData == null) return const Center(child: CircularProgressIndicator());
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

class _WcsStatusChip extends StatelessWidget {
  final LinkState state;
  const _WcsStatusChip({required this.state});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (label, color, icon) = switch (state) {
      LinkState.connecting => (
          'Connecting…',
          Colors.amber.shade700,
          Icons.sync_rounded
        ),
      LinkState.waitingForMobile => (
          'Scan to unlock',
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
      LinkState.error => (
          'Connection error',
          AppTheme.error,
          Icons.error_outline_rounded
        ),
      _ => ('Starting…', Colors.grey, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600, color: color, letterSpacing: 0.1)),
      ]),
    );
  }
}

class _WcsStep extends StatelessWidget {
  final String n;
  final String text;
  const _WcsStep({required this.n, required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(n,
              style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text,
            style: tt.bodyMedium
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.65))),
      ),
    ]);
  }
}
