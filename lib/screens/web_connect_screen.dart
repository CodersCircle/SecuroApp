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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SecuroApp',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Web Vault',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                ]),
              ]),
              const SizedBox(height: 40),
              Container(
                width: 320,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _WcsStatusChip(state: _state),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: _WcsQrArea(
                        state: _state,
                        session: _session,
                        error: _error,
                        onRefresh: _requestSession),
                  ),
                  if (_state == LinkState.waitingForMobile) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _qrSecondsLeft / 60,
                            minHeight: 4,
                            backgroundColor:
                                Theme.of(context).colorScheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation(
                                _qrSecondsLeft <= 10
                                    ? AppTheme.error
                                    : AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_qrSecondsLeft}s',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _qrSecondsLeft <= 10
                                  ? AppTheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45))),
                    ]),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton.icon(
                        onPressed: _requestSession,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Try Again')),
                  ],
                ]),
              ),
              const SizedBox(height: 28),
              if (_state == LinkState.waitingForMobile ||
                  _state == LinkState.idle ||
                  _state == LinkState.connecting)
                const SizedBox(
                    width: 320,
                    child: Column(children: [
                      _WcsStep(n: '1', text: 'Open SecuroApp on your phone'),
                      SizedBox(height: 8),
                      _WcsStep(
                          n: '2', text: 'Tap the Link Device icon in top bar'),
                      SizedBox(height: 8),
                      _WcsStep(
                          n: '3', text: 'Point your camera at the QR code'),
                    ])),
            ],
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
    if (state == LinkState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state == LinkState.syncing) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 3)),
        SizedBox(height: 16),
        Text('Syncing vault...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]));
    }
    if (state == LinkState.connected) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.smartphone_rounded,
                color: AppTheme.success, size: 42)),
        const SizedBox(height: 14),
        const Text('Mobile Connected',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.success)),
        const SizedBox(height: 4),
        Text('Waiting for vault data...',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.withValues(alpha: 0.7))),
      ]));
    }
    if (state == LinkState.error || state == LinkState.disconnected) {
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
            label: const Text('Generate QR')),
      ]));
    }
    final qrData = session?.toQrString();
    if (qrData == null) return const Center(child: CircularProgressIndicator());
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 240,
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
    final (label, color, icon) = switch (state) {
      LinkState.connecting => (
          'Connecting...',
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
          'Syncing vault...',
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
      _ => ('Starting...', Colors.grey, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
    return Row(children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Center(
            child: Text(n,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary))),
      ),
      const SizedBox(width: 10),
      Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)))),
    ]);
  }
}
