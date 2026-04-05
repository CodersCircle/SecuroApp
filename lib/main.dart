import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securo_app/services/notification_service.dart';
import 'package:securo_app/services/theme_service.dart';
import 'app.dart';
import 'database/app_database.dart';
import 'services/encryption_service.dart';

late AppDatabase appDatabase;

bool get _isDesktopOrWeb {
  if (kIsWeb) return true;
  try {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Platform-specific orientation lock (mobile only) ──────
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  appDatabase = AppDatabase();

  // ── EncryptionService bootstrap ───────────────────────────
  // On web/desktop there is no user-vault-key (no login flow).
  // Initialise with a fixed app-level key so encrypt/decrypt work
  // for the ephemeral session database.
  if (_isDesktopOrWeb) {
    await EncryptionService.instance.initialize('securo_web_session_key_v1');
  }

  await NotificationService.instance.initialize();
  await ThemeService.instance.initialize();
  runApp(const SecuroApp());
}
