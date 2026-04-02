import 'dart:async';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class ClipboardUtil {
  ClipboardUtil._();

  static Timer? _clearTimer;

  /// Copy to clipboard and auto-clear after [AppConstants.clipboardClearSeconds]
  static Future<void> copyAndAutoClear(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
          () => Clipboard.setData(const ClipboardData(text: '')),
    );
  }

  static void cancelTimer() => _clearTimer?.cancel();
}
