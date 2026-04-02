import 'package:drift/drift.dart';

class TotpAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get issuer => text().withLength(min: 1, max: 100)();
  TextColumn get accountName => text().withLength(min: 1, max: 200)();
  TextColumn get secretKey => text()();
  TextColumn get iconEmoji => text().withDefault(const Constant('🔐'))();
  IntColumn get digits => integer().withDefault(const Constant(6))();
  IntColumn get period => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TotpEntry {
  final int? id;
  final String issuer;
  final String accountName;
  final String secretKey;
  final String iconEmoji;
  final int digits;
  final int period;

  const TotpEntry({
    this.id,
    required this.issuer,
    required this.accountName,
    required this.secretKey,
    this.iconEmoji = '🔐',
    this.digits = 6,
    this.period = 30,
  });
}
