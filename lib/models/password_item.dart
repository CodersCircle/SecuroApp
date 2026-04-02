import 'package:drift/drift.dart';

class PasswordItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get platformName => text().withLength(min: 1, max: 100)();
  TextColumn get username => text().withLength(min: 1, max: 200)();
  TextColumn get encryptedPassword => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get groupName => text().withDefault(const Constant('Personal'))();
  TextColumn get iconEmoji => text().withDefault(const Constant('🔑'))();
  TextColumn get websiteUrl => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Plain model for UI usage
class PasswordEntry {
  final int? id;
  final String platformName;
  final String username;
  String encryptedPassword;
  final String notes;
  final String groupName;
  final String iconEmoji;
  final String websiteUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry({
    this.id,
    required this.platformName,
    required this.username,
    required this.encryptedPassword,
    this.notes = '',
    this.groupName = 'Personal',
    this.iconEmoji = '🔑',
    this.websiteUrl = '',
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'platform': platformName,
    'username': username,
    'password': encryptedPassword,
    'group': groupName,
    'notes': notes,
    'website': websiteUrl,
  };
}
