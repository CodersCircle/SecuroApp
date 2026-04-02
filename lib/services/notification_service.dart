import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    if (_enabled) {
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

    if (val) {
      // Re-request permissions if toggled on
      await _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _onResponse(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> show(String title, String body) async {
    if (!_enabled) return; // ✅ Block if disabled

    await _plugin.show(
      id: _idCounter++,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
  }

  // ── Convenience methods ────────────────────────────────────

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
