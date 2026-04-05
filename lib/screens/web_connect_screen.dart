import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/app_theme.dart';
import '../services/link_service.dart';
import 'web_vault_screen.dart';

/// Web-only entry screen — WhatsApp Web–style QR linking.
/// Shown automatically on web (see app.dart).
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
    } else if (s == LinkState.connected ||
        s == LinkState.error ||
        s == LinkState.disconnected) {
      _qrTimer?.cancel();
    }
  }

  void _onData(Map<String, dynamic> data) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => WebVaultScreen(vaultData: data),
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AppTheme.primary, size: 38),
                ),
                const SizedBox(height: 20),
                Text('SecuroApp Web',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Scan with your phone to connect',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 32),
                _QrCard(
                  state: _state,
                  session: _session,
                  qrSecondsLeft: _qrSecondsLeft,
                  error: _error,
                  onRefresh: _requestSession,
                ),
                const SizedBox(height: 32),
                if (_state == LinkState.waitingForMobile ||
                    _state == LinkState.connecting ||
                    _state == LinkState.idle)
                  const _Steps(),
                if (_state == LinkState.connected)
                  _ConnectedBanner(device: _link.connectedDevice),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── QR Card ───────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final LinkState state;
  final SessionInfo? session;
  final int qrSecondsLeft;
  final String? error;
  final VoidCallback onRefresh;

  const _QrCard({
    required this.state,
    required this.session,
    required this.qrSecondsLeft,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(state: state),
            const SizedBox(height: 20),
            SizedBox(width: 240, height: 240, child: _buildQrContent(context)),
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
                const SizedBox(width: 12),
                Text('${qrSecondsLeft}s',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: qrSecondsLeft <= 10
                            ? AppTheme.error
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5))),
              ]),
            ],
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
    if (state == LinkState.connecting) {
      return const Center(child: CircularProgressIndicator());
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
            child: const Icon(Icons.check_rounded,
                color: AppTheme.success, size: 42),
          ),
          const SizedBox(height: 12),
          const Text('Connected!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.success)),
          const SizedBox(height: 4),
          const Text('Receiving vault data…', style: TextStyle(fontSize: 12)),
        ]),
      );
    }
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
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Generate QR'),
          ),
        ]),
      );
    }
    // waitingForMobile
    final qrData = session?.toQrString();
    if (qrData == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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

// ── Status Chip ───────────────────────────────────────────────

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
          'Connected',
          AppTheme.success,
          Icons.check_circle_rounded
        ),
      LinkState.syncing => (
          'Syncing…',
          AppTheme.primary,
          Icons.cloud_sync_rounded
        ),
      LinkState.disconnected => (
          'Disconnected',
          AppTheme.error,
          Icons.link_off_rounded
        ),
      LinkState.error => ('Error', AppTheme.error, Icons.error_outline_rounded),
      _ => ('Ready', Colors.grey, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

// ── Steps ─────────────────────────────────────────────────────

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Step(n: '1', text: 'Open SecuroApp on your phone'),
        SizedBox(height: 10),
        _Step(n: '2', text: 'Tap the Link Device button in the top bar'),
        SizedBox(height: 10),
        _Step(n: '3', text: 'Point the camera at this QR code'),
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
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

// ── Connected Banner ──────────────────────────────────────────

class _ConnectedBanner extends StatelessWidget {
  final ConnectedDevice? device;
  const _ConnectedBanner({this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.smartphone_rounded,
              color: AppTheme.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device?.name ?? 'Mobile Device',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const Text('Receiving data…', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.success)),
        ],
      ),
    );
  }
}
