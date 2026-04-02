import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'encryption_service.dart';

class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  final _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);

  Future<bool> backupToDrive() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final client = _AuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);

      // Build encrypted backup payload
      final passwords = await appDatabase.getAllPasswords();
      final payload = passwords
          .map((p) => {
        'platform': p.platformName,
        'username': p.username,
        'ep': p.encryptedPassword, // already encrypted
        'group': p.groupName,
        'notes': p.notes,
      })
          .toList();

      final json = jsonEncode(payload);
      final encrypted = EncryptionService.instance.encrypt(json);

      final dir = await getTemporaryDirectory();
      final file =
      await File('${dir.path}/securo_backup.enc').writeAsString(encrypted);

      final driveFile = drive.File()
        ..name = 'securo_backup_${DateTime.now().millisecondsSinceEpoch}.enc'
        ..mimeType = 'application/octet-stream';

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), await file.length()),
      );

      client.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
