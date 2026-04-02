import '../constants/app_constants.dart';

class FileSecurity {
  FileSecurity._();

  static const int _maxBytes = AppConstants.maxImportFileSizeMb * 1024 * 1024;

  static ({bool valid, String? error}) validate(
      String fileName, int fileSizeBytes) {
    final lower = fileName.toLowerCase();

    for (final ext in AppConstants.blockedFileExtensions) {
      if (lower.endsWith(ext)) {
        return (valid: false, error: 'Blocked file type: $ext');
      }
    }

    if (fileSizeBytes > _maxBytes) {
      return (
      valid: false,
      error:
      'File too large. Max ${AppConstants.maxImportFileSizeMb}MB allowed.'
      );
    }

    final allowedExtensions = ['.csv', '.txt', '.json', '.xlsx', '.xls'];
    final hasAllowed = allowedExtensions.any((e) => lower.endsWith(e));
    if (!hasAllowed) {
      return (valid: false, error: 'Unsupported file type.');
    }

    return (valid: true, error: null);
  }

  /// Scan text content for suspicious patterns
  static bool containsMaliciousPatterns(String content) {
    final patterns = [
      '<script',
      'javascript:',
      'eval(',
      'exec(',
      'cmd.exe',
      '/bin/sh',
    ];
    final lower = content.toLowerCase();
    return patterns.any((p) => lower.contains(p));
  }
}
