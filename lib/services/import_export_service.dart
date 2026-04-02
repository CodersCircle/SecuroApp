import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:securo_app/database/app_database.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils/file_security.dart';
import 'encryption_service.dart';

class ImportExportService {
  ImportExportService._();
  static final ImportExportService instance = ImportExportService._();

  // ── EXPORT ─────────────────────────────────────────────────

  Future<void> exportAsCSV(List<PasswordItem> items) async {
    final rows = [
      ['platform', 'username', 'password', 'group', 'notes']
    ];
    for (final item in items) {
      rows.add([
        item.platformName,
        item.username,
        EncryptionService.instance.decrypt(item.encryptedPassword),
        item.groupName,
        item.notes,
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    await _shareFile(utf8.encode(csv), 'securo_vault.csv');
  }

  Future<void> exportAsJSON(List<PasswordItem> items) async {
    final data = items
        .map((i) => {
      'platform': i.platformName,
      'username': i.username,
      'password':
      EncryptionService.instance.decrypt(i.encryptedPassword),
      'group': i.groupName,
      'notes': i.notes,
    })
        .toList();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await _shareFile(utf8.encode(json), 'securo_vault.json');
  }

  Future<void> exportAsTXT(List<PasswordItem> items) async {
    final buffer = StringBuffer('SecuroApp Vault Export\n${'─' * 40}\n\n');
    for (final item in items) {
      buffer
        ..writeln('Platform : ${item.platformName}')
        ..writeln('Username : ${item.username}')
        ..writeln(
            'Password : ${EncryptionService.instance.decrypt(item.encryptedPassword)}')
        ..writeln('Group    : ${item.groupName}')
        ..writeln('Notes    : ${item.notes}')
        ..writeln('─' * 40)
        ..writeln();
    }
    await _shareFile(utf8.encode(buffer.toString()), 'securo_vault.txt');
  }

  // ── IMPORT ─────────────────────────────────────────────────

  Future<List<Map<String, String>>?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json', 'txt'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final validation = FileSecurity.validate(
      file.name,
      file.size,
    );

    if (!validation.valid) {
      throw Exception(validation.error);
    }

    final path = file.path;
    if (path == null) throw Exception('Cannot read file path.');

    final content = await File(path).readAsString();

    if (FileSecurity.containsMaliciousPatterns(content)) {
      throw Exception('File contains suspicious content and was rejected.');
    }

    final lower = file.name.toLowerCase();
    if (lower.endsWith('.csv')) return _parseCSV(content);
    if (lower.endsWith('.json')) return _parseJSON(content);
    return null;
  }

  List<Map<String, String>> _parseCSV(String content) {
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) return [];
    final headers =
    rows.first.map((h) => h.toString().toLowerCase()).toList();
    return rows.skip(1).map((row) {
      final map = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = i < row.length ? row[i].toString() : '';
      }
      return map;
    }).toList();
  }

  List<Map<String, String>> _parseJSON(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! List) throw Exception('Invalid JSON format.');
    return decoded
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v.toString())))
        .toList();
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'SecuroApp Export');
  }
}
