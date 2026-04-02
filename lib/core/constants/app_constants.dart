class AppConstants {
  AppConstants._();

  static const String appName = 'SecuroApp';
  static const int autoLockSeconds = 300;
  static const int clipboardClearSeconds = 30;
  static const int maxImportFileSizeMb = 10;

  static const List<String> defaultGroups = [
    'Social Media',
    'Work',
    'OTT Platforms',
    'Music',
    'Academics',
    'Personal',
    'Finance',
  ];

  static const List<String> blockedFileExtensions = [
    '.exe', '.apk', '.js', '.bat', '.sh', '.ps1',
    '.cmd', '.msi', '.dmg', '.pkg',
  ];

  static const List<String> platformIcons = [
    '🔑', '📧', '💼', '🎵', '🎬', '🏦', '🛒', '🎮',
    '📱', '💻', '🌐', '📚', '🏥', '✈️', '🏠', '⚙️',
    '🗄️', '📑', '💾', '☁️', '🎮', '⚡', '🤖', '⚛️',
  ];

  static String getLogoForPlatform(String platformName) {
    final lower = platformName.toLowerCase();
    if (lower.contains('google')) return 'G';
    if (lower.contains('netflix')) return 'N';
    if (lower.contains('prime')) return 'P';
    if (lower.contains('amazon')) return 'A';
    if (lower.contains('github')) return '💻';
    return '';
  }
}
