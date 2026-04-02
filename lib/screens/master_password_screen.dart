import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/theme/app_theme.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

class MasterPasswordScreen extends StatefulWidget {
  const MasterPasswordScreen({super.key});

  @override
  State<MasterPasswordScreen> createState() => _MasterPasswordScreenState();
}

class _MasterPasswordScreenState extends State<MasterPasswordScreen> {
  static const _storage = FlutterSecureStorage();
  static const _hashKey = 'master_password_hash';

  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isNewUser = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final hash = await _storage.read(key: _hashKey);
    setState(() {
      _isNewUser = hash == null;
      _loading = false;
    });
    if (hash != null) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return;
      final authenticated = await auth.authenticate(
        localizedReason: 'Unlock SecuroApp',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (authenticated && mounted) await _unlockWithBiometric();
    } catch (_) {}
  }

  Future<void> _unlockWithBiometric() async {
    // ✅ Removed unused `stored` variable — only masterPwd is needed
    final masterPwd = await _storage.read(key: 'master_plain') ?? '';
    if (masterPwd.isNotEmpty) {
      await EncryptionService.instance.initialize(masterPwd);
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final password = _ctrl.text;

    if (_isNewUser) {
      final hash =
      EncryptionService.instance.hashMasterPassword(password);
      await _storage.write(key: _hashKey, value: hash);
      await _storage.write(key: 'master_plain', value: password);
      await EncryptionService.instance.initialize(password);
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      final storedHash = await _storage.read(key: _hashKey) ?? '';
      final inputHash =
      EncryptionService.instance.hashMasterPassword(password);
      if (inputHash == storedHash) {
        await EncryptionService.instance.initialize(password);
        if (mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        setState(() => _error = 'Incorrect master password');
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppTheme.primary, size: 52),
                const SizedBox(height: 16),
                Text(
                  _isNewUser ? 'Create Master Password' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isNewUser
                      ? 'This password encrypts your entire vault.\nMake it strong and memorable.'
                      : 'Enter your master password to unlock SecuroApp.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Master Password',
                  controller: _ctrl,
                  obscureText: true,
                  showToggle: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (_isNewUser && v.length < 8) {
                      return 'Minimum 8 characters';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isNewUser ? 'Create Vault' : 'Unlock'),
                ),
                if (!_isNewUser) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use Biometrics'),
                      onPressed: _tryBiometric,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
