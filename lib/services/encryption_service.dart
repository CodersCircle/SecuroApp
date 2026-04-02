import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  late Key _key;
  bool _initialized = false;

  // ✅ SECURITY FIX: Derive key using PBKDF2 instead of raw vault key
  Future<void> initialize(String vaultKey) async {
    final keyBytes = deriveKey(vaultKey);
    _key = Key(keyBytes);
    _initialized = true;
  }

  /// Initialize using already derived key bytes (e.g. from storage)
  Future<void> initializeFromDerived(Uint8List derivedKey) async {
    _key = Key(derivedKey);
    _initialized = true;
  }

  /// PBKDF2-SHA256 key derivation — 100,000 iterations
  static Uint8List deriveKey(String password) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(
      // ✅ Static salt tied to app — prevents cross-app attacks
      utf8.encode('securo_app_vault_salt_v1'),
      100000,
      32,
    ));
    return pbkdf2.process(utf8.encode(password));
  }

  /// Returns a hash of the master password for verification
  String hashMasterPassword(String password) {
    return base64.encode(deriveKey(password));
  }

  /// ✅ SECURITY FIX: Random IV per encryption — never reuse IV
  String encrypt(String plainText) {
    assert(_initialized, 'EncryptionService not initialized');
    // Generate fresh random IV for every encryption call
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // ✅ Store IV alongside ciphertext: base64(iv):base64(ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  /// ✅ Decrypts using stored IV extracted from ciphertext
  String decrypt(String cipherText) {
    assert(_initialized, 'EncryptionService not initialized');
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return '';
      final iv        = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return '';
    }
  }

  bool get isInitialized => _initialized;
}
