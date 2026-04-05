import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_theme.dart';
import '../services/link_service.dart';

/// Mobile-only screen — scan the web QR code and send vault data.
/// Opened via the Link Device button in the TopBar.
class LinkDeviceScreen extends StatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final _link = LinkService.instance;
  final _auth = LocalAuthentication();

  // ── page index: 0 = scan, 1 = status ──────────────────────
  int _page = 0;

  // ── scanner ────────────────────────────────────────────────
  MobileScannerController? _scanCtrl;
  bool _scanning = false;
  bool _processing = false;

  // ── link state ─────────────────────────────────────────────
  StreamSubscription<LinkState>? _stateSub;
  StreamSubscription<String>? _errorSub;
  LinkState _state = LinkState.idle;
  String? _errorMsg;
  bool _dismissed = false; // guard: only pop once

  @override
  void initState() {
    super.initState();
    _stateSub = _link.stateStream.listen(_onState);
    _errorSub = _link.errorStream.listen(_onError);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _errorSub?.cancel();
    _scanCtrl?.dispose();
    super.dispose();
  }

  void _onState(LinkState s) {
    if (!mounted || _dismissed) return;
    setState(() => _state = s);
    if (s == LinkState.connected) {
      // Start vault send in background, then dismiss this screen
      // HomeScreen will show a banner while sync is in progress
      _sendVaultAndDismiss();
    }
  }

  Future<void> _sendVaultAndDismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    // Fire-and-forget: kick off the send, then pop immediately
    // so the user is back on the normal app UI
    unawaited(_link.sendVaultData());
    if (mounted) Navigator.of(context).pop();
  }

  void _onError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _processing = false;
    });
  }

  // ── scan flow ──────────────────────────────────────────────

  void _startScan() {
    _scanCtrl = MobileScannerController();
    setState(() {
      _scanning = true;
      _errorMsg = null;
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() {
      _processing = true;
    });
    _scanCtrl?.stop();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final sessionId = json['session_id'] as String?;
      final qrToken = json['qr_token'] as String?;
      final server = json['server'] as String?;

      if (sessionId == null || qrToken == null || server == null) {
        throw Exception('Invalid QR — not a SecuroApp code');
      }

      // Biometric check before sharing vault data
      final canCheck =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        final ok = await _auth.authenticate(
          localizedReason:
              'Verify your identity to share vault with web browser',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (!ok) {
          setState(() {
            _processing = false;
            _scanning = false;
          });
          _showSnack('Authentication cancelled');
          return;
        }
      }

      // Join the session
      final joined = await _link.joinSession(
        sessionId: sessionId,
        qrToken: qrToken,
        serverUrl: server,
        deviceName: _deviceLabel(),
      );

      if (!joined && mounted) {
        setState(() {
          _processing = false;
          _scanning = false;
        });
        _showSnack(_errorMsg ?? 'Could not join session');
        return;
      }

      // Switch to status page
      if (mounted) {
        setState(() {
          _page = 1;
          _processing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _scanning = false;
      });
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _deviceLabel() {
    // Simple platform label — could use device_info_plus for real names
    return 'Mobile Device';
  }

  Future<void> _disconnect() async {
    final nav = Navigator.of(context);
    await _link.disconnect();
    if (mounted) nav.pop();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Device'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            if (_state == LinkState.connected || _state == LinkState.syncing) {
              await _link.disconnect();
            }
            if (mounted) nav.pop();
          },
        ),
      ),
      body: _page == 0 ? _buildScanPage() : _buildStatusPage(),
    );
  }

  // ── Scan page ──────────────────────────────────────────────

  Widget _buildScanPage() {
    if (!_scanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppTheme.primary, size: 46),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan QR on Web',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Open SecuroApp in a browser, then scan the QR code with this button.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 12),
              _infoRow(Icons.timer_off_rounded, 'QR expires in 60 s'),
              const SizedBox(height: 6),
              _infoRow(Icons.lock_rounded, 'End-to-end encrypted'),
              const SizedBox(height: 6),
              _infoRow(
                  Icons.visibility_off_rounded, 'Web browser is read-only'),
              const SizedBox(height: 36),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _startScan,
                icon: const Icon(Icons.camera_alt_rounded),
                label:
                    const Text('Open Camera', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    // Camera active
    return Stack(
      children: [
        MobileScanner(
          controller: _scanCtrl,
          onDetect: _handleBarcode,
        ),
        // Overlay frame
        Positioned.fill(
          child: CustomPaint(painter: _ScannerOverlayPainter()),
        ),
        if (_processing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Joining session…',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        // Cancel button
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black45),
              onPressed: () {
                _scanCtrl?.dispose();
                setState(() {
                  _scanning = false;
                  _scanCtrl = null;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  // ── Status page ────────────────────────────────────────────

  Widget _buildStatusPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StateIcon(state: _state),
            const SizedBox(height: 24),
            Text(_stateTitle(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_stateSubtitle(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55))),
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(_errorMsg!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 36),
            if (_state == LinkState.syncing ||
                _state == LinkState.connected) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Disconnect'),
              ),
            ] else if (_state == LinkState.disconnected ||
                _state == LinkState.error) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() {
                  _page = 0;
                  _scanning = false;
                }),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stateTitle() => switch (_state) {
        LinkState.connecting => 'Connecting…',
        LinkState.connected => 'Connected',
        LinkState.syncing => 'Sending Vault…',
        LinkState.disconnected => 'Disconnected',
        LinkState.error => 'Connection Error',
        _ => 'Linking…',
      };

  String _stateSubtitle() => switch (_state) {
        LinkState.connecting => 'Joining the relay session',
        LinkState.connected => 'Verifying with web browser',
        LinkState.syncing => 'Encrypting and sending your vault data',
        LinkState.disconnected => 'The session has ended',
        LinkState.error => _errorMsg ?? 'Something went wrong',
        _ => '',
      };
}

// ── State Icon ────────────────────────────────────────────────

class _StateIcon extends StatelessWidget {
  final LinkState state;
  const _StateIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      LinkState.connected => (Icons.check_circle_rounded, AppTheme.success),
      LinkState.syncing => (Icons.cloud_upload_rounded, AppTheme.primary),
      LinkState.disconnected => (Icons.link_off_rounded, Colors.grey),
      LinkState.error => (Icons.error_outline_rounded, AppTheme.error),
      _ => (Icons.sync_rounded, AppTheme.primary),
    };

    final isAnimating =
        state == LinkState.connecting || state == LinkState.syncing;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: isAnimating
          ? Stack(alignment: Alignment.center, children: [
              SizedBox(
                  width: 80,
                  height: 80,
                  child:
                      CircularProgressIndicator(color: color, strokeWidth: 3)),
              Icon(icon, color: color, size: 40),
            ])
          : Icon(icon, color: color, size: 52),
    );
  }
}

// ── Scanner Overlay Painter ───────────────────────────────────

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cut = size.width * 0.65;
    final l = (size.width - cut) / 2;
    final t = (size.height - cut) / 2;
    final rect = Rect.fromLTWH(l, t, cut, cut);

    // dim outside scan area
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // corner markers
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    final r = rect;
    // top-left
    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), paint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), paint);
    // top-right
    canvas.drawLine(
        Offset(r.right - len, r.top), Offset(r.right, r.top), paint);
    canvas.drawLine(
        Offset(r.right, r.top), Offset(r.right, r.top + len), paint);
    // bottom-left
    canvas.drawLine(
        Offset(r.left, r.bottom - len), Offset(r.left, r.bottom), paint);
    canvas.drawLine(
        Offset(r.left, r.bottom), Offset(r.left + len, r.bottom), paint);
    // bottom-right
    canvas.drawLine(
        Offset(r.right - len, r.bottom), Offset(r.right, r.bottom), paint);
    canvas.drawLine(
        Offset(r.right, r.bottom), Offset(r.right, r.bottom - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
