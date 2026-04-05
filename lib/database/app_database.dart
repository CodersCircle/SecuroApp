import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/password_item.dart';
import '../models/totp_account.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [PasswordItems, TotpAccounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'securo_vault',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
              onResult: (result) {
                if (result.missingFeatures.isNotEmpty) {
                  // Web storage falling back gracefully
                }
              },
            )
          : null,
    );
  }

  // ── Password CRUD ──────────────────────────────────────────
  Future<List<PasswordItem>> getAllPasswords() => select(passwordItems).get();

  Stream<List<PasswordItem>> watchAllPasswords() =>
      select(passwordItems).watch();

  Future<List<PasswordItem>> getPasswordsByGroup(String group) =>
      (select(passwordItems)..where((t) => t.groupName.equals(group))).get();

  Future<int> insertPassword(PasswordItemsCompanion entry) =>
      into(passwordItems).insert(entry);

  Future<bool> updatePassword(PasswordItemsCompanion entry) =>
      update(passwordItems).replace(entry);

  Future<int> deletePassword(int id) =>
      (delete(passwordItems)..where((t) => t.id.equals(id))).go();

  Future<List<PasswordItem>> searchPasswords(
          String query) =>
      (select(passwordItems)
            ..where((t) =>
                t.platformName.contains(query) | t.username.contains(query)))
          .get();

  // ── TOTP CRUD ──────────────────────────────────────────────
  Stream<List<TotpAccount>> watchAllTotp() => select(totpAccounts).watch();

  Future<int> insertTotp(TotpAccountsCompanion entry) =>
      into(totpAccounts).insert(entry);

  Future<int> deleteTotp(int id) =>
      (delete(totpAccounts)..where((t) => t.id.equals(id))).go();
}
