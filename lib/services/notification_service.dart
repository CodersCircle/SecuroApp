import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  int _idCounter = 0;
  bool _enabled = true;

  bool get isEnabled => _enabled;

  static const _androidDetails = AndroidNotificationDetails(
    'securo_channel',
    'SecuroApp Alerts',
    channelDescription: 'SecuroApp vault activity notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('notifications_enabled') ?? true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    // ✅ Windows initialization with required parameters
    const windowsSettings = WindowsInitializationSettings(
      appName: 'SecuroApp',
      appUserModelId: 'com.securoapp.securo_app',
      guid: '12345678-1234-1234-1234-123456789abc',
    );

    // ✅ Fix: Use named parameter 'settings' as required by the plugin version
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        windows: windowsSettings,
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (_enabled && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
    _enabled = val;

    if (val && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _onResponse(NotificationResponse response) {}

  Future<void> show(String title, String body) async {
    if (!_enabled) return;

    // ✅ Fix: Use named arguments for _plugin.show as required
    await _plugin.show(
      id: _idCounter++,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
  }

  Future<void> notifyPasswordAdded(String platform) =>
      show('Password Saved', '$platform added to vault.');

  Future<void> notifyPasswordUpdated(String platform) =>
      show('Password Updated', '$platform updated in vault.');

  Future<void> notifyPasswordDeleted(String platform) =>
      show('Password Deleted', '$platform removed from vault.');

  Future<void> notifyImportComplete(int count) =>
      show('Import Complete', '$count passwords imported successfully.');

  Future<void> notifyBackupComplete() =>
      show('Backup Complete', 'Vault backed up to Google Drive.');

  Future<void> notifyTotpAdded(String issuer) =>
      show('2FA Account Added', '$issuer added to Authenticator.');

  Future<void> notifyTotpUpdated(String issuer) =>
      show('2FA Account Updated', '$issuer updated in Authenticator.');

  Future<void> notifyTotpDeleted(String issuer) =>
      show('2FA Account Deleted', '$issuer removed from Authenticator.');
}
