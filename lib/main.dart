import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securo_app/services/notification_service.dart';
import 'package:securo_app/services/theme_service.dart';
import 'app.dart';
import 'database/app_database.dart';

late AppDatabase appDatabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  appDatabase = AppDatabase();
  await NotificationService.instance.initialize();
  await ThemeService.instance.initialize();
  runApp(const SecuroApp());
}
