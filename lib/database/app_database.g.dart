// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PasswordItemsTable extends PasswordItems
    with TableInfo<$PasswordItemsTable, PasswordItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PasswordItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _platformNameMeta =
      const VerificationMeta('platformName');
  @override
  late final GeneratedColumn<String> platformName = GeneratedColumn<String>(
      'platform_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _encryptedPasswordMeta =
      const VerificationMeta('encryptedPassword');
  @override
  late final GeneratedColumn<String> encryptedPassword =
      GeneratedColumn<String>('encrypted_password', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Personal'));
  static const VerificationMeta _iconEmojiMeta =
      const VerificationMeta('iconEmoji');
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
      'icon_emoji', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('🔑'));
  static const VerificationMeta _websiteUrlMeta =
      const VerificationMeta('websiteUrl');
  @override
  late final GeneratedColumn<String> websiteUrl = GeneratedColumn<String>(
      'website_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        platformName,
        username,
        encryptedPassword,
        notes,
        groupName,
        iconEmoji,
        websiteUrl,
        isFavorite,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'password_items';
  @override
  VerificationContext validateIntegrity(Insertable<PasswordItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('platform_name')) {
      context.handle(
          _platformNameMeta,
          platformName.isAcceptableOrUnknown(
              data['platform_name']!, _platformNameMeta));
    } else if (isInserting) {
      context.missing(_platformNameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('encrypted_password')) {
      context.handle(
          _encryptedPasswordMeta,
          encryptedPassword.isAcceptableOrUnknown(
              data['encrypted_password']!, _encryptedPasswordMeta));
    } else if (isInserting) {
      context.missing(_encryptedPasswordMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(_iconEmojiMeta,
          iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta));
    }
    if (data.containsKey('website_url')) {
      context.handle(
          _websiteUrlMeta,
          websiteUrl.isAcceptableOrUnknown(
              data['website_url']!, _websiteUrlMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PasswordItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PasswordItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      platformName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform_name'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      encryptedPassword: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_password'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name'])!,
      iconEmoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_emoji'])!,
      websiteUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}website_url'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PasswordItemsTable createAlias(String alias) {
    return $PasswordItemsTable(attachedDatabase, alias);
  }
}

class PasswordItem extends DataClass implements Insertable<PasswordItem> {
  final int id;
  final String platformName;
  final String username;
  final String encryptedPassword;
  final String notes;
  final String groupName;
  final String iconEmoji;
  final String websiteUrl;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PasswordItem(
      {required this.id,
      required this.platformName,
      required this.username,
      required this.encryptedPassword,
      required this.notes,
      required this.groupName,
      required this.iconEmoji,
      required this.websiteUrl,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['platform_name'] = Variable<String>(platformName);
    map['username'] = Variable<String>(username);
    map['encrypted_password'] = Variable<String>(encryptedPassword);
    map['notes'] = Variable<String>(notes);
    map['group_name'] = Variable<String>(groupName);
    map['icon_emoji'] = Variable<String>(iconEmoji);
    map['website_url'] = Variable<String>(websiteUrl);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PasswordItemsCompanion toCompanion(bool nullToAbsent) {
    return PasswordItemsCompanion(
      id: Value(id),
      platformName: Value(platformName),
      username: Value(username),
      encryptedPassword: Value(encryptedPassword),
      notes: Value(notes),
      groupName: Value(groupName),
      iconEmoji: Value(iconEmoji),
      websiteUrl: Value(websiteUrl),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PasswordItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PasswordItem(
      id: serializer.fromJson<int>(json['id']),
      platformName: serializer.fromJson<String>(json['platformName']),
      username: serializer.fromJson<String>(json['username']),
      encryptedPassword: serializer.fromJson<String>(json['encryptedPassword']),
      notes: serializer.fromJson<String>(json['notes']),
      groupName: serializer.fromJson<String>(json['groupName']),
      iconEmoji: serializer.fromJson<String>(json['iconEmoji']),
      websiteUrl: serializer.fromJson<String>(json['websiteUrl']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'platformName': serializer.toJson<String>(platformName),
      'username': serializer.toJson<String>(username),
      'encryptedPassword': serializer.toJson<String>(encryptedPassword),
      'notes': serializer.toJson<String>(notes),
      'groupName': serializer.toJson<String>(groupName),
      'iconEmoji': serializer.toJson<String>(iconEmoji),
      'websiteUrl': serializer.toJson<String>(websiteUrl),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PasswordItem copyWith(
          {int? id,
          String? platformName,
          String? username,
          String? encryptedPassword,
          String? notes,
          String? groupName,
          String? iconEmoji,
          String? websiteUrl,
          bool? isFavorite,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PasswordItem(
        id: id ?? this.id,
        platformName: platformName ?? this.platformName,
        username: username ?? this.username,
        encryptedPassword: encryptedPassword ?? this.encryptedPassword,
        notes: notes ?? this.notes,
        groupName: groupName ?? this.groupName,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        websiteUrl: websiteUrl ?? this.websiteUrl,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PasswordItem copyWithCompanion(PasswordItemsCompanion data) {
    return PasswordItem(
      id: data.id.present ? data.id.value : this.id,
      platformName: data.platformName.present
          ? data.platformName.value
          : this.platformName,
      username: data.username.present ? data.username.value : this.username,
      encryptedPassword: data.encryptedPassword.present
          ? data.encryptedPassword.value
          : this.encryptedPassword,
      notes: data.notes.present ? data.notes.value : this.notes,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
      websiteUrl:
          data.websiteUrl.present ? data.websiteUrl.value : this.websiteUrl,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PasswordItem(')
          ..write('id: $id, ')
          ..write('platformName: $platformName, ')
          ..write('username: $username, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('notes: $notes, ')
          ..write('groupName: $groupName, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      platformName,
      username,
      encryptedPassword,
      notes,
      groupName,
      iconEmoji,
      websiteUrl,
      isFavorite,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PasswordItem &&
          other.id == this.id &&
          other.platformName == this.platformName &&
          other.username == this.username &&
          other.encryptedPassword == this.encryptedPassword &&
          other.notes == this.notes &&
          other.groupName == this.groupName &&
          other.iconEmoji == this.iconEmoji &&
          other.websiteUrl == this.websiteUrl &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PasswordItemsCompanion extends UpdateCompanion<PasswordItem> {
  final Value<int> id;
  final Value<String> platformName;
  final Value<String> username;
  final Value<String> encryptedPassword;
  final Value<String> notes;
  final Value<String> groupName;
  final Value<String> iconEmoji;
  final Value<String> websiteUrl;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PasswordItemsCompanion({
    this.id = const Value.absent(),
    this.platformName = const Value.absent(),
    this.username = const Value.absent(),
    this.encryptedPassword = const Value.absent(),
    this.notes = const Value.absent(),
    this.groupName = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.websiteUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PasswordItemsCompanion.insert({
    this.id = const Value.absent(),
    required String platformName,
    required String username,
    required String encryptedPassword,
    this.notes = const Value.absent(),
    this.groupName = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.websiteUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : platformName = Value(platformName),
        username = Value(username),
        encryptedPassword = Value(encryptedPassword);
  static Insertable<PasswordItem> custom({
    Expression<int>? id,
    Expression<String>? platformName,
    Expression<String>? username,
    Expression<String>? encryptedPassword,
    Expression<String>? notes,
    Expression<String>? groupName,
    Expression<String>? iconEmoji,
    Expression<String>? websiteUrl,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (platformName != null) 'platform_name': platformName,
      if (username != null) 'username': username,
      if (encryptedPassword != null) 'encrypted_password': encryptedPassword,
      if (notes != null) 'notes': notes,
      if (groupName != null) 'group_name': groupName,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
      if (websiteUrl != null) 'website_url': websiteUrl,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PasswordItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? platformName,
      Value<String>? username,
      Value<String>? encryptedPassword,
      Value<String>? notes,
      Value<String>? groupName,
      Value<String>? iconEmoji,
      Value<String>? websiteUrl,
      Value<bool>? isFavorite,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PasswordItemsCompanion(
      id: id ?? this.id,
      platformName: platformName ?? this.platformName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      notes: notes ?? this.notes,
      groupName: groupName ?? this.groupName,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (platformName.present) {
      map['platform_name'] = Variable<String>(platformName.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (encryptedPassword.present) {
      map['encrypted_password'] = Variable<String>(encryptedPassword.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    if (websiteUrl.present) {
      map['website_url'] = Variable<String>(websiteUrl.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PasswordItemsCompanion(')
          ..write('id: $id, ')
          ..write('platformName: $platformName, ')
          ..write('username: $username, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('notes: $notes, ')
          ..write('groupName: $groupName, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TotpAccountsTable extends TotpAccounts
    with TableInfo<$TotpAccountsTable, TotpAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TotpAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
      'issuer', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _accountNameMeta =
      const VerificationMeta('accountName');
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
      'account_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _secretKeyMeta =
      const VerificationMeta('secretKey');
  @override
  late final GeneratedColumn<String> secretKey = GeneratedColumn<String>(
      'secret_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconEmojiMeta =
      const VerificationMeta('iconEmoji');
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
      'icon_emoji', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('🔐'));
  static const VerificationMeta _digitsMeta = const VerificationMeta('digits');
  @override
  late final GeneratedColumn<int> digits = GeneratedColumn<int>(
      'digits', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(6));
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
      'period', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        issuer,
        accountName,
        secretKey,
        iconEmoji,
        digits,
        period,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'totp_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<TotpAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('issuer')) {
      context.handle(_issuerMeta,
          issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta));
    } else if (isInserting) {
      context.missing(_issuerMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
          _accountNameMeta,
          accountName.isAcceptableOrUnknown(
              data['account_name']!, _accountNameMeta));
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('secret_key')) {
      context.handle(_secretKeyMeta,
          secretKey.isAcceptableOrUnknown(data['secret_key']!, _secretKeyMeta));
    } else if (isInserting) {
      context.missing(_secretKeyMeta);
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(_iconEmojiMeta,
          iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta));
    }
    if (data.containsKey('digits')) {
      context.handle(_digitsMeta,
          digits.isAcceptableOrUnknown(data['digits']!, _digitsMeta));
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TotpAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TotpAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      issuer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issuer'])!,
      accountName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_name'])!,
      secretKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}secret_key'])!,
      iconEmoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_emoji'])!,
      digits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}digits'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TotpAccountsTable createAlias(String alias) {
    return $TotpAccountsTable(attachedDatabase, alias);
  }
}

class TotpAccount extends DataClass implements Insertable<TotpAccount> {
  final int id;
  final String issuer;
  final String accountName;
  final String secretKey;
  final String iconEmoji;
  final int digits;
  final int period;
  final DateTime createdAt;
  const TotpAccount(
      {required this.id,
      required this.issuer,
      required this.accountName,
      required this.secretKey,
      required this.iconEmoji,
      required this.digits,
      required this.period,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['issuer'] = Variable<String>(issuer);
    map['account_name'] = Variable<String>(accountName);
    map['secret_key'] = Variable<String>(secretKey);
    map['icon_emoji'] = Variable<String>(iconEmoji);
    map['digits'] = Variable<int>(digits);
    map['period'] = Variable<int>(period);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TotpAccountsCompanion toCompanion(bool nullToAbsent) {
    return TotpAccountsCompanion(
      id: Value(id),
      issuer: Value(issuer),
      accountName: Value(accountName),
      secretKey: Value(secretKey),
      iconEmoji: Value(iconEmoji),
      digits: Value(digits),
      period: Value(period),
      createdAt: Value(createdAt),
    );
  }

  factory TotpAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TotpAccount(
      id: serializer.fromJson<int>(json['id']),
      issuer: serializer.fromJson<String>(json['issuer']),
      accountName: serializer.fromJson<String>(json['accountName']),
      secretKey: serializer.fromJson<String>(json['secretKey']),
      iconEmoji: serializer.fromJson<String>(json['iconEmoji']),
      digits: serializer.fromJson<int>(json['digits']),
      period: serializer.fromJson<int>(json['period']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'issuer': serializer.toJson<String>(issuer),
      'accountName': serializer.toJson<String>(accountName),
      'secretKey': serializer.toJson<String>(secretKey),
      'iconEmoji': serializer.toJson<String>(iconEmoji),
      'digits': serializer.toJson<int>(digits),
      'period': serializer.toJson<int>(period),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TotpAccount copyWith(
          {int? id,
          String? issuer,
          String? accountName,
          String? secretKey,
          String? iconEmoji,
          int? digits,
          int? period,
          DateTime? createdAt}) =>
      TotpAccount(
        id: id ?? this.id,
        issuer: issuer ?? this.issuer,
        accountName: accountName ?? this.accountName,
        secretKey: secretKey ?? this.secretKey,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        digits: digits ?? this.digits,
        period: period ?? this.period,
        createdAt: createdAt ?? this.createdAt,
      );
  TotpAccount copyWithCompanion(TotpAccountsCompanion data) {
    return TotpAccount(
      id: data.id.present ? data.id.value : this.id,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      accountName:
          data.accountName.present ? data.accountName.value : this.accountName,
      secretKey: data.secretKey.present ? data.secretKey.value : this.secretKey,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
      digits: data.digits.present ? data.digits.value : this.digits,
      period: data.period.present ? data.period.value : this.period,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TotpAccount(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('accountName: $accountName, ')
          ..write('secretKey: $secretKey, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('digits: $digits, ')
          ..write('period: $period, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, issuer, accountName, secretKey, iconEmoji, digits, period, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TotpAccount &&
          other.id == this.id &&
          other.issuer == this.issuer &&
          other.accountName == this.accountName &&
          other.secretKey == this.secretKey &&
          other.iconEmoji == this.iconEmoji &&
          other.digits == this.digits &&
          other.period == this.period &&
          other.createdAt == this.createdAt);
}

class TotpAccountsCompanion extends UpdateCompanion<TotpAccount> {
  final Value<int> id;
  final Value<String> issuer;
  final Value<String> accountName;
  final Value<String> secretKey;
  final Value<String> iconEmoji;
  final Value<int> digits;
  final Value<int> period;
  final Value<DateTime> createdAt;
  const TotpAccountsCompanion({
    this.id = const Value.absent(),
    this.issuer = const Value.absent(),
    this.accountName = const Value.absent(),
    this.secretKey = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.digits = const Value.absent(),
    this.period = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TotpAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String issuer,
    required String accountName,
    required String secretKey,
    this.iconEmoji = const Value.absent(),
    this.digits = const Value.absent(),
    this.period = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : issuer = Value(issuer),
        accountName = Value(accountName),
        secretKey = Value(secretKey);
  static Insertable<TotpAccount> custom({
    Expression<int>? id,
    Expression<String>? issuer,
    Expression<String>? accountName,
    Expression<String>? secretKey,
    Expression<String>? iconEmoji,
    Expression<int>? digits,
    Expression<int>? period,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (issuer != null) 'issuer': issuer,
      if (accountName != null) 'account_name': accountName,
      if (secretKey != null) 'secret_key': secretKey,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
      if (digits != null) 'digits': digits,
      if (period != null) 'period': period,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TotpAccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? issuer,
      Value<String>? accountName,
      Value<String>? secretKey,
      Value<String>? iconEmoji,
      Value<int>? digits,
      Value<int>? period,
      Value<DateTime>? createdAt}) {
    return TotpAccountsCompanion(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      secretKey: secretKey ?? this.secretKey,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (secretKey.present) {
      map['secret_key'] = Variable<String>(secretKey.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    if (digits.present) {
      map['digits'] = Variable<int>(digits.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TotpAccountsCompanion(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('accountName: $accountName, ')
          ..write('secretKey: $secretKey, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('digits: $digits, ')
          ..write('period: $period, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PasswordItemsTable passwordItems = $PasswordItemsTable(this);
  late final $TotpAccountsTable totpAccounts = $TotpAccountsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [passwordItems, totpAccounts];
}

typedef $$PasswordItemsTableCreateCompanionBuilder = PasswordItemsCompanion
    Function({
  Value<int> id,
  required String platformName,
  required String username,
  required String encryptedPassword,
  Value<String> notes,
  Value<String> groupName,
  Value<String> iconEmoji,
  Value<String> websiteUrl,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PasswordItemsTableUpdateCompanionBuilder = PasswordItemsCompanion
    Function({
  Value<int> id,
  Value<String> platformName,
  Value<String> username,
  Value<String> encryptedPassword,
  Value<String> notes,
  Value<String> groupName,
  Value<String> iconEmoji,
  Value<String> websiteUrl,
  Value<bool> isFavorite,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PasswordItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PasswordItemsTable> {
  $$PasswordItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platformName => $composableBuilder(
      column: $table.platformName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedPassword => $composableBuilder(
      column: $table.encryptedPassword,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconEmoji => $composableBuilder(
      column: $table.iconEmoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get websiteUrl => $composableBuilder(
      column: $table.websiteUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PasswordItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PasswordItemsTable> {
  $$PasswordItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platformName => $composableBuilder(
      column: $table.platformName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedPassword => $composableBuilder(
      column: $table.encryptedPassword,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
      column: $table.iconEmoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get websiteUrl => $composableBuilder(
      column: $table.websiteUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PasswordItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PasswordItemsTable> {
  $$PasswordItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get platformName => $composableBuilder(
      column: $table.platformName, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get encryptedPassword => $composableBuilder(
      column: $table.encryptedPassword, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);

  GeneratedColumn<String> get websiteUrl => $composableBuilder(
      column: $table.websiteUrl, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PasswordItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PasswordItemsTable,
    PasswordItem,
    $$PasswordItemsTableFilterComposer,
    $$PasswordItemsTableOrderingComposer,
    $$PasswordItemsTableAnnotationComposer,
    $$PasswordItemsTableCreateCompanionBuilder,
    $$PasswordItemsTableUpdateCompanionBuilder,
    (
      PasswordItem,
      BaseReferences<_$AppDatabase, $PasswordItemsTable, PasswordItem>
    ),
    PasswordItem,
    PrefetchHooks Function()> {
  $$PasswordItemsTableTableManager(_$AppDatabase db, $PasswordItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PasswordItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PasswordItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PasswordItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> platformName = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> encryptedPassword = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> groupName = const Value.absent(),
            Value<String> iconEmoji = const Value.absent(),
            Value<String> websiteUrl = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PasswordItemsCompanion(
            id: id,
            platformName: platformName,
            username: username,
            encryptedPassword: encryptedPassword,
            notes: notes,
            groupName: groupName,
            iconEmoji: iconEmoji,
            websiteUrl: websiteUrl,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String platformName,
            required String username,
            required String encryptedPassword,
            Value<String> notes = const Value.absent(),
            Value<String> groupName = const Value.absent(),
            Value<String> iconEmoji = const Value.absent(),
            Value<String> websiteUrl = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PasswordItemsCompanion.insert(
            id: id,
            platformName: platformName,
            username: username,
            encryptedPassword: encryptedPassword,
            notes: notes,
            groupName: groupName,
            iconEmoji: iconEmoji,
            websiteUrl: websiteUrl,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PasswordItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PasswordItemsTable,
    PasswordItem,
    $$PasswordItemsTableFilterComposer,
    $$PasswordItemsTableOrderingComposer,
    $$PasswordItemsTableAnnotationComposer,
    $$PasswordItemsTableCreateCompanionBuilder,
    $$PasswordItemsTableUpdateCompanionBuilder,
    (
      PasswordItem,
      BaseReferences<_$AppDatabase, $PasswordItemsTable, PasswordItem>
    ),
    PasswordItem,
    PrefetchHooks Function()>;
typedef $$TotpAccountsTableCreateCompanionBuilder = TotpAccountsCompanion
    Function({
  Value<int> id,
  required String issuer,
  required String accountName,
  required String secretKey,
  Value<String> iconEmoji,
  Value<int> digits,
  Value<int> period,
  Value<DateTime> createdAt,
});
typedef $$TotpAccountsTableUpdateCompanionBuilder = TotpAccountsCompanion
    Function({
  Value<int> id,
  Value<String> issuer,
  Value<String> accountName,
  Value<String> secretKey,
  Value<String> iconEmoji,
  Value<int> digits,
  Value<int> period,
  Value<DateTime> createdAt,
});

class $$TotpAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $TotpAccountsTable> {
  $$TotpAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuer => $composableBuilder(
      column: $table.issuer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secretKey => $composableBuilder(
      column: $table.secretKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconEmoji => $composableBuilder(
      column: $table.iconEmoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get digits => $composableBuilder(
      column: $table.digits, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TotpAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $TotpAccountsTable> {
  $$TotpAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuer => $composableBuilder(
      column: $table.issuer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secretKey => $composableBuilder(
      column: $table.secretKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
      column: $table.iconEmoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get digits => $composableBuilder(
      column: $table.digits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TotpAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TotpAccountsTable> {
  $$TotpAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
      column: $table.accountName, builder: (column) => column);

  GeneratedColumn<String> get secretKey =>
      $composableBuilder(column: $table.secretKey, builder: (column) => column);

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);

  GeneratedColumn<int> get digits =>
      $composableBuilder(column: $table.digits, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TotpAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TotpAccountsTable,
    TotpAccount,
    $$TotpAccountsTableFilterComposer,
    $$TotpAccountsTableOrderingComposer,
    $$TotpAccountsTableAnnotationComposer,
    $$TotpAccountsTableCreateCompanionBuilder,
    $$TotpAccountsTableUpdateCompanionBuilder,
    (
      TotpAccount,
      BaseReferences<_$AppDatabase, $TotpAccountsTable, TotpAccount>
    ),
    TotpAccount,
    PrefetchHooks Function()> {
  $$TotpAccountsTableTableManager(_$AppDatabase db, $TotpAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TotpAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TotpAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TotpAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> issuer = const Value.absent(),
            Value<String> accountName = const Value.absent(),
            Value<String> secretKey = const Value.absent(),
            Value<String> iconEmoji = const Value.absent(),
            Value<int> digits = const Value.absent(),
            Value<int> period = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TotpAccountsCompanion(
            id: id,
            issuer: issuer,
            accountName: accountName,
            secretKey: secretKey,
            iconEmoji: iconEmoji,
            digits: digits,
            period: period,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String issuer,
            required String accountName,
            required String secretKey,
            Value<String> iconEmoji = const Value.absent(),
            Value<int> digits = const Value.absent(),
            Value<int> period = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              TotpAccountsCompanion.insert(
            id: id,
            issuer: issuer,
            accountName: accountName,
            secretKey: secretKey,
            iconEmoji: iconEmoji,
            digits: digits,
            period: period,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TotpAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TotpAccountsTable,
    TotpAccount,
    $$TotpAccountsTableFilterComposer,
    $$TotpAccountsTableOrderingComposer,
    $$TotpAccountsTableAnnotationComposer,
    $$TotpAccountsTableCreateCompanionBuilder,
    $$TotpAccountsTableUpdateCompanionBuilder,
    (
      TotpAccount,
      BaseReferences<_$AppDatabase, $TotpAccountsTable, TotpAccount>
    ),
    TotpAccount,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PasswordItemsTableTableManager get passwordItems =>
      $$PasswordItemsTableTableManager(_db, _db.passwordItems);
  $$TotpAccountsTableTableManager get totpAccounts =>
      $$TotpAccountsTableTableManager(_db, _db.totpAccounts);
}
