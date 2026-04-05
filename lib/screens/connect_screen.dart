import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/app_theme.dart';
import '../services/sync_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    SyncService.instance.stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Connect'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Show QR'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scan'),
            Tab(icon: Icon(Icons.computer_rounded), text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [_ShowQRTab(), _ScanTab(), _ManualTab()],
      ),
    );
  }
}

// ── Show QR Tab (Start server, show QR code) ─────────────────

class _ShowQRTab extends StatefulWidget {
  const _ShowQRTab();

  @override
  State<_ShowQRTab> createState() => _ShowQRTabState();
}

class _ShowQRTabState extends State<_ShowQRTab> {
  String? _qrData;
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final result = await SyncService.instance.startServer();
      if (mounted) setState(() => _qrData = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start server: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    await SyncService.instance.stopServer();
    if (mounted) setState(() => _qrData = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_qrData != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan this QR with another device',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Open SecuroApp → Sync & Connect → Scan QR',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const _TokenDisplay(),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _stop,
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text('Stop Server'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broadcast_on_personal_rounded,
              size: 80,
              color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Start Sync Server',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your device will be discoverable\non the local network',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _starting ? null : _start,
            icon: _starting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.power_settings_new_rounded),
            label: Text(_starting ? 'Starting...' : 'Start Server'),
          ),
        ],
      ),
    );
  }
}

class _TokenDisplay extends StatefulWidget {
  const _TokenDisplay();

  @override
  State<_TokenDisplay> createState() => _TokenDisplayState();
}

class _TokenDisplayState extends State<_TokenDisplay> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ip = SyncService.instance.currentIP ?? 'unknown';
    final port = SyncService.instance.serverPort;
    final token = SyncService.instance.currentToken ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IP:', style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
              SelectableText(ip,
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Port:', style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
              SelectableText(port,
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Token:', style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  token,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Scan Tab (Scan QR to connect and sync TO server) ─────────

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  MobileScannerController? _ctrl;
  bool _scanning = false;
  bool _connecting = false;

  void _startScanning() {
    if (kIsWeb) return;
    _ctrl = MobileScannerController(
      torchEnabled: true,
    );
    setState(() => _scanning = true);
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_connecting) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    if (!mounted) return;

    setState(() {
      _ctrl?.stop();
      _connecting = true;
    });

    try {
      final data = Map<String, dynamic>.from(jsonDecode(code));
      final ip = data['ip'] as String?;
      final port = data['port'] as String? ?? '8765';
      final token = data['token'] as String?;

      if (ip == null || token == null) {
        throw Exception('Invalid QR data');
      }

      final result = await SyncService.instance.connectViaIP(ip, port, token);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Synced: ${result['passwords']} passwords, ${result['totp']} 2FA'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Sync failed'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
          _ctrl?.start();
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: Text('Camera scanning not available on web.\nUse Auto or Manual tab instead.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    if (!_scanning) {
      return Center(
        child: FilledButton.icon(
          onPressed: _startScanning,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Start Scanner'),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: _handleBarcode,
        ),
        if (_connecting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text('Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Manual Tab (Auto-discovery + manual IP entry) ────────────

class _ManualTab extends StatefulWidget {
  const _ManualTab();

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8765');
  final _tokenCtrl = TextEditingController();
  bool _connecting = false;

  Stream<List<DiscoveredDevice>>? _devices;

  @override
  void initState() {
    super.initState();
    SyncService.instance.startDiscovery();
    _devices = SyncService.instance.discoveredDevices;
  }

  @override
  void dispose() {
    SyncService.instance.stopDiscovery();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectManual() async {
    final ip = _ipCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final token = _tokenCtrl.text.trim();

    if (ip.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter IP and Token')),
      );
      return;
    }

    setState(() => _connecting = true);

    try {
      final result = await SyncService.instance.connectViaIP(ip, port, token);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Synced: ${result['passwords']} passwords, ${result['totp']} 2FA'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Sync failed'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connectDiscovery(DiscoveredDevice device) async {
    setState(() => _connecting = true);

    try {
      final result = await SyncService.instance.connectToDevice(device);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Synced: ${result['passwords']} passwords, ${result['totp']} 2FA'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Sync failed'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Auto-discovered devices ────────────────────────
        Text('Nearby Devices', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<DiscoveredDevice>>(
          stream: _devices,
          initialData: const [],
          builder: (context, snapshot) {
            final devices = snapshot.data ?? [];
            if (devices.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('Searching for devices...',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            }

            return Column(
              children: devices
                  .map((d) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.devices_rounded,
                                color: AppTheme.primary),
                          ),
                          title: Text(d.name),
                          subtitle: Text(d.ip),
                          trailing: _connecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : IconButton.filled(
                                  icon: const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                  onPressed: () => _connectDiscovery(d),
                                ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        // ── Manual entry ───────────────────────────────────
        Text('Manual Connection',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _ipCtrl,
          decoration: const InputDecoration(
            labelText: 'IP Address',
            hintText: '192.168.1.5',
            prefixIcon: Icon(Icons.computer_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _portCtrl,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8765',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tokenCtrl,
          decoration: const InputDecoration(
            labelText: 'Token',
            hintText: '12-character token',
            prefixIcon: Icon(Icons.key_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _connecting ? null : _connectManual,
            icon: _connecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link_rounded),
            label: Text(_connecting ? 'Connecting...' : 'Connect & Sync'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
