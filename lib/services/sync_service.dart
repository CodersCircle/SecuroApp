import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../main.dart' show appDatabase;
import '../services/encryption_service.dart';

/// mDNS service type for Securo sync discovery
const _mdnsServiceType = '_securosync._tcp.';
const _mdnsServiceName = 'Securo-Sync';

class DiscoveredDevice {
  final String name;
  final String ip;
  final String port;
  final String? token;

  const DiscoveredDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.token,
  });

  String get address => 'http://$ip:$port';
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  // ── Server state ────────────────────────────────────────────
  HttpServer? _server;
  String? _currentToken;
  String? _wifiIP;
  final String _port = '8765';
  bool _isRunning = false;
  String _serverId = '';

  // ── mDNS advertising ────────────────────────────────────────
  BonsoirBroadcast? _mdnsBroadcast;

  // ── mDNS discovery (browser) ────────────────────────────────
  BonsoirDiscovery? _mdnsDiscovery;

  final _devicesStreamController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final List<DiscoveredDevice> _discoveredDevices = [];

  Stream<List<DiscoveredDevice>> get discoveredDevices =>
      _devicesStreamController.stream;

  String? get currentIP => _wifiIP;
  bool get isServerRunning => _isRunning;
  String? get currentToken => _currentToken;
  String get serverPort => _port;

  // ── Network helpers ─────────────────────────────────────────
  Future<String?> getWifiIP() async {
    if (_wifiIP != null) return _wifiIP;
    final info = NetworkInfo();
    _wifiIP = await info.getWifiIP();
    return _wifiIP;
  }

  /// Start the HTTP sync server (native only — web has no HttpServer).
  /// Returns JSON connection info or null.
  Future<String?> startServer() async {
    if (kIsWeb) {
      debugPrint('Sync server not available on web');
      return null;
    }

    await stopServer(); // clean restart

    _currentToken = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    _serverId = const Uuid().v4().substring(0, 8);

    final ip = await getWifiIP() ?? '127.0.0.1';

    // Build shelf router
    final router = Router();

    router.get('/', (shelf.Request request) {
      final checkToken = request.url.queryParameters['token'];
      final valid = checkToken == _currentToken && _isRunning;
      return shelf.Response.ok(
        jsonEncode(
            {'status': valid ? 'valid' : 'invalid', 'server': _mdnsServiceName}),
        headers: {'content-type': 'application/json'},
      );
    });

    router.get('/api/status', (shelf.Request request) => shelf.Response.ok(
          jsonEncode({
            'server': _mdnsServiceName,
            'id': _serverId,
            'token': _currentToken,
            'running': _isRunning,
          }),
          headers: {'content-type': 'application/json'},
        ));

    // Export vault data to connected client (for web/remote clients)
    router.post('/api/export', _handleExportRequest);

    router.post('/sync', _handleSyncRequest);

    // Start shelf HTTP server
    _server = await io.serve(
      router.call,
      InternetAddress.anyIPv4,
      int.parse(_port),
    );

    _isRunning = true;
    debugPrint('📡 Sync server running on $ip:$_port');

    // Advertise via mDNS so other devices can discover us
    await _startMdnsAdvertising(ip);

    return jsonEncode({
      'ip': ip,
      'port': _port,
      'token': _currentToken,
    });
  }

  /// Stop server + mDNS advertising
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
    }
    await _stopMdnsAdvertising();
    _currentToken = null;
    _wifiIP = null;
    debugPrint('🔌 Sync server stopped');
  }

  // ── mDNS Advertising ────────────────────────────────────────
  Future<void> _startMdnsAdvertising(String ip) async {
    try {
      await _stopMdnsAdvertising();

      final service = BonsoirService(
        name: '$_mdnsServiceName-$_serverId',
        type: _mdnsServiceType,
        port: int.parse(_port),
        attributes: {
          'token': _currentToken ?? '',
          'ip': ip,
          'port': _port,
        },
      );

      _mdnsBroadcast = BonsoirBroadcast(service: service);
      await _mdnsBroadcast!.initialize();
      await _mdnsBroadcast!.start();
      debugPrint('📡 mDNS advertised: $ip:$_port');
    } catch (e) {
      debugPrint('⚠️ mDNS advertising failed: $e');
    }
  }

  Future<void> _stopMdnsAdvertising() async {
    try {
      await _mdnsBroadcast?.stop();
      _mdnsBroadcast = null;
    } catch (_) {}
  }

  // ── mDNS Discovery (Browser) ────────────────────────────────
  Future<void> startDiscovery() async {
    if (kIsWeb) return;

    _discoveredDevices.clear();
    _devicesStreamController.add([]);

    try {
      _mdnsDiscovery = BonsoirDiscovery(type: _mdnsServiceType);
      await _mdnsDiscovery!.initialize();
      await _mdnsDiscovery!.start();

      _mdnsDiscovery!.eventStream?.listen((event) {
        if (event is! BonsoirDiscoveryServiceFoundEvent) return;

        final service = event.service;
        final attrs = service.attributes;
        final ip = attrs['ip'];
        final port = attrs['port'];
        final token = attrs['token'];

        if (ip != null && port != null) {
          // Don't discover self
          if (ip == _wifiIP && port == _port) return;

          _addDiscoveredDevice(DiscoveredDevice(
            name: service.name,
            ip: ip,
            port: port,
            token: token,
          ));
        }
      });
    } catch (e) {
      debugPrint('⚠️ mDNS discovery failed: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _mdnsDiscovery?.stop();
      _mdnsDiscovery = null;
    } catch (_) {}
  }

  void _addDiscoveredDevice(DiscoveredDevice device) {
    final exists = _discoveredDevices.any((d) => d.ip == device.ip);
    if (!exists) {
      _discoveredDevices.add(device);
      _devicesStreamController.add([..._discoveredDevices]);
      debugPrint('📱 Discovered: ${device.name} at ${device.address}');
    }
  }

  // ── Connection & Sync ──────────────────────────────────────
  /// Connect to a discovered device and sync data.
  Future<Map<String, dynamic>> connectToDevice(DiscoveredDevice device) async {
    return _connectAndSync(device.ip, device.port, device.token ?? '');
  }

  /// Connect via manual IP + token (web fallback, or when mDNS unavailable)
  Future<Map<String, dynamic>> connectViaIP(
      String ip, String port, String token) async {
    return _connectAndSync(ip, port, token);
  }

  /// Core sync logic — send all local data to peer server.
  Future<Map<String, dynamic>> _connectAndSync(
      String ip, String port, String token) async {
    try {
      final url = 'http://$ip:$port';

      // Validate token
      final check = await http.get(Uri.parse('$url?token=$token'));
      if (check.statusCode != 200) {
        return {'error': 'Server not reachable', 'success': false};
      }

      final checkData = jsonDecode(check.body) as Map<String, dynamic>;
      if (checkData['status'] != 'valid') {
        return {'error': 'Token rejected', 'success': false};
      }

      // Build payload: all passwords (decrypted)
      final allPasswords = await appDatabase.getAllPasswords();
      final List<Map<String, String>> passwords = [];
      for (final item in allPasswords) {
        final dec = EncryptionService.instance.decrypt(item.encryptedPassword);
        passwords.add({
          'platform': item.platformName,
          'username': item.username,
          'password': dec,
          'group': item.groupName,
          'iconEmoji': item.iconEmoji,
          'websiteUrl': item.websiteUrl,
        });
      }

      // Build payload: all TOTP accounts
      final List<Map<String, String>> totp = [];
      final allTotp = await appDatabase.select(appDatabase.totpAccounts).get();
      for (final entry in allTotp) {
        totp.add({
          'issuer': entry.issuer,
          'accountName': entry.accountName,
          'secretKey': entry.secretKey,
          'iconEmoji': entry.iconEmoji,
          'digits': entry.digits.toString(),
          'period': entry.period.toString(),
        });
      }

      // Send payload to peer
      final response = await http.post(
        Uri.parse('$url/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'passwords': passwords,
          'totp': totp,
        }),
      );

      if (response.statusCode == HttpStatus.ok) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint(
            '✅ Synced: ${result['passwords']} passwords, ${result['totp']} 2FA');
        return {
          'success': true,
          'passwords': result['passwords'],
          'totp': result['totp'],
        };
      } else {
        return {
          'success': false,
          'error': 'Sync failed (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ Connect & sync error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Shelf request handler for incoming sync data.
  Future<shelf.Response> _handleSyncRequest(shelf.Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['token'] != _currentToken || !_isRunning) {
        return shelf.Response.unauthorized(
          jsonEncode({'error': 'Invalid token'}),
          headers: {'content-type': 'application/json'},
        );
      }

      int importedPasswords = 0;
      int imported2FA = 0;

      if (data['passwords'] is List) {
        for (final entry in data['passwords'] as List) {
          final enc = EncryptionService.instance
              .encrypt(entry['password'] as String);
          await appDatabase.insertPassword(PasswordItemsCompanion.insert(
            platformName: entry['platform'] as String? ?? 'Imported',
            username: entry['username'] as String? ?? '',
            encryptedPassword: enc,
            notes: Value(entry['notes'] as String? ?? ''),
            groupName: Value(entry['group'] as String? ?? 'Imported'),
            iconEmoji: Value(entry['iconEmoji'] as String? ?? '🔑'),
            websiteUrl: Value(entry['websiteUrl'] as String? ?? ''),
          ));
          importedPasswords++;
        }
      }

      if (data['totp'] is List) {
        for (final entry in data['totp'] as List) {
          await appDatabase.insertTotp(TotpAccountsCompanion.insert(
            issuer: entry['issuer'] as String? ?? '',
            accountName: entry['accountName'] as String? ?? '',
            secretKey: entry['secretKey'] as String? ?? '',
            iconEmoji: Value(entry['iconEmoji'] as String? ?? '🔐'),
          ));
          imported2FA++;
        }
      }

      _currentToken = null;

      debugPrint(
          '✅ Sync complete: $importedPasswords passwords, $imported2FA 2FA');
      return shelf.Response.ok(
        jsonEncode({
          'success': true,
          'passwords': importedPasswords,
          'totp': imported2FA,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Export vault data to a connected client (web, remote).
  /// Token must be valid; client authenticates with it.
  Future<shelf.Response> _handleExportRequest(
      shelf.Request request) async {
    try {
      final body = await request.readAsString();
      final data = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : {};
      final checkToken = data['token'] as String? ??
          request.url.queryParameters['token'];

      if (checkToken != _currentToken || !_isRunning) {
        return shelf.Response.unauthorized(
          jsonEncode({'error': 'Invalid token'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Build export payload
      int passwordCount = 0;
      int totpCount = 0;

      final List<Map<String, String>> passwords = [];
      final allPasswords = await appDatabase.getAllPasswords();
      for (final item in allPasswords) {
        final dec = EncryptionService.instance.decrypt(item.encryptedPassword);
        passwords.add({
          'platform': item.platformName,
          'username': item.username,
          'password': dec,
          'group': item.groupName,
          'iconEmoji': item.iconEmoji,
          'websiteUrl': item.websiteUrl,
        });
        passwordCount++;
      }

      final List<Map<String, String>> totp = [];
      final allTotp = await appDatabase.select(appDatabase.totpAccounts).get();
      for (final entry in allTotp) {
        totp.add({
          'issuer': entry.issuer,
          'accountName': entry.accountName,
          'secretKey': entry.secretKey,
          'iconEmoji': entry.iconEmoji,
          'digits': entry.digits.toString(),
          'period': entry.period.toString(),
        });
        totpCount++;
      }

      debugPrint('📤 Exporting: $passwordCount passwords, $totpCount 2FA');
      return shelf.Response.ok(
        jsonEncode({
          'success': true,
          'passwords': passwords,
          'totp': totp,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ Export error: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Connect to a server and REQUEST data from it (client download mode).
  /// Used by web to pull vault data from mobile.
  Future<Map<String, dynamic>> requestVaultData(
      String ip, String port, String token) async {
    try {
      final url = 'http://$ip:$port';

      // Validate token
      final check = await http.get(Uri.parse('$url?token=$token'));
      if (check.statusCode != 200) {
        return {'error': 'Server not reachable', 'success': false};
      }

      final checkData = jsonDecode(check.body) as Map<String, dynamic>;
      if (checkData['status'] != 'valid') {
        return {'error': 'Token rejected', 'success': false};
      }

      // Request export
      final response = await http.post(
        Uri.parse('$url/api/export'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == HttpStatus.ok) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          return {
            'success': true,
            'passwords': result['passwords'] ?? [],
            'totp': result['totp'] ?? [],
          };
        }
      }

      return {
        'success': false,
        'error': 'Export failed (${response.statusCode})',
      };
    } catch (e) {
      debugPrint('❌ Request vault error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
