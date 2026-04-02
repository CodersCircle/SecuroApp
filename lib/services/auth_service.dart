import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'encryption_service.dart';

class UserProfile {
  final String username;
  final String email;
  final String? avatarPath;

  const UserProfile({
    required this.username,
    required this.email,
    this.avatarPath,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage  = FlutterSecureStorage();
  final _localAuth        = LocalAuthentication();

  static const _kUsername     = 'user_username';
  static const _kEmail        = 'user_email';
  static const _kPasswordHash = 'user_password_hash';
  static const _kVaultKeyHash = 'user_vault_key_hash';
  // ✅ SECURITY FIX: Store derived key bytes, NOT plain vault key
  static const _kVaultKeyDerived = 'user_vault_key_derived';
  static const _kMpin         = 'user_mpin_hash';
  static const _kBioEnabled   = 'user_bio_enabled';
  static const _kAvatarPath   = 'user_avatar_path';
  static const _kIsRegistered = 'user_registered';

  // ── Registration ───────────────────────────────────────────

  Future<bool> get isRegistered async {
    final val = await _storage.read(key: _kIsRegistered);
    return val == 'true';
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String vaultKey,
  }) async {
    // ✅ Use central derivation and store derived bytes
    final derived = EncryptionService.deriveKey(vaultKey);
    final derivedB64 = base64.encode(derived);

    await Future.wait([
      _storage.write(key: _kUsername,        value: username),
      _storage.write(key: _kEmail,           value: email),
      _storage.write(key: _kPasswordHash,    value: _hash(password)),
      _storage.write(key: _kVaultKeyHash,    value: _hash(vaultKey)),
      _storage.write(key: _kVaultKeyDerived, value: derivedB64),
      _storage.write(key: _kIsRegistered,    value: 'true'),
    ]);

    await EncryptionService.instance.initializeFromDerived(derived);
  }

  // ── Login ──────────────────────────────────────────────────

  Future<bool> usernameExists(String username) async {
    final stored = await _storage.read(key: _kUsername);
    return stored?.toLowerCase() == username.toLowerCase();
  }

  /// ✅ Unlocks vault using stored derived key — no plain key stored
  Future<void> unlockVault() async {
    final derivedB64 = await _storage.read(key: _kVaultKeyDerived);
    if (derivedB64 == null) return;
    // Re-initialize with a sentinel so EncryptionService has the key bytes
    // We pass derived bytes directly via a separate init method
    await EncryptionService.instance.initializeFromDerived(
      base64.decode(derivedB64),
    );
  }

  // ── Biometric ──────────────────────────────────────────────

  Future<bool> get isBioAvailable async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('isBioAvailable error: ${e.code}');
      return false;
    }
  }

  Future<bool> verifyBiometric() async {
    try {
      final available = await isBioAvailable;
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Unlock SecuroApp',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled  ||
          e.code == auth_error.lockedOut    ||
          e.code == auth_error.permanentlyLockedOut) {
        debugPrint('Biometric: ${e.code}');
      }
      return false;
    }
  }

  Future<void> setBioEnabled(bool enabled) async =>
      _storage.write(key: _kBioEnabled, value: enabled.toString());

  Future<bool> get isBioEnabled async {
    final val = await _storage.read(key: _kBioEnabled);
    return val == 'true';
  }

  // ── MPIN & Security Updates ──────────────────────────────────────────

  Future<void> saveMpin(String mpin) async =>
      _storage.write(key: _kMpin, value: _hash(mpin));

  Future<bool> get hasMpin async =>
      (await _storage.read(key: _kMpin)) != null;

  Future<bool> verifyMpin(String mpin) async {
    final stored = await _storage.read(key: _kMpin);
    if (stored == null) return false;
    return stored == _hash(mpin);
  }
  
  Future<void> updateMasterPassword(String newPassword) async {
     await _storage.write(key: _kPasswordHash, value: _hash(newPassword));
  }

  // ── Profile ────────────────────────────────────────────────

  Future<UserProfile?> getProfile() async {
    final username = await _storage.read(key: _kUsername);
    if (username == null) return null;
    final email      = await _storage.read(key: _kEmail) ?? '';
    final avatarPath = await _storage.read(key: _kAvatarPath);
    return UserProfile(
      username: username,
      email: email,
      avatarPath: (avatarPath ?? '').isEmpty ? null : avatarPath,
    );
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    String? avatarPath,
  }) async {
    await _storage.write(key: _kUsername, value: username);
    await _storage.write(key: _kEmail,    value: email);
    if (avatarPath != null) {
      await _storage.write(key: _kAvatarPath, value: avatarPath);
    }
  }

  Future<void> updateAvatarPath(String path) async =>
      _storage.write(key: _kAvatarPath, value: path);

  Future<String> get username async =>
      await _storage.read(key: _kUsername) ?? '';

  Future<String> get email async =>
      await _storage.read(key: _kEmail) ?? '';

  // ── Helpers ────────────────────────────────────────────────

  String _hash(String input) {
    final bytes = utf8.encode('${input}securo_auth_salt');
    return sha256.convert(bytes).toString();
  }
}
