import 'dart:math';
import 'package:flutter/material.dart';
import 'package:securo_app/screens/post_signup_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _vaultKeyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _vaultKeyCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() => _passwordCtrl.text = _randomStrong(16));
  }

  void _generateVaultKey() {
    setState(() => _vaultKeyCtrl.text = _randomStrong(24));
  }

  String _randomStrong(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
        '0123456789!@#\$%^&*';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);

    await AuthService.instance.register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      vaultKey: _vaultKeyCtrl.text,
    );

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const PostSignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Responsive.formMaxWidth),
              child: ListView(
                padding: Responsive.pagePadding(context),
                children: [
                  const SizedBox(height: 16),
                  const _SignupHeader(),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Username',
                    controller: _usernameCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) return 'Min 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _GeneratableField(
                    label: 'Password',
                    controller: _passwordCtrl,
                    obscure: true,
                    onGenerate: _generatePassword,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'Min 8 characters';
                      return null;
                    },
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordCtrl,
                    builder: (_, val, __) =>
                        PasswordStrengthIndicator(password: val.text),
                  ),
                  const SizedBox(height: 16),
                  const _VaultKeyInfo(),
                  const SizedBox(height: 8),
                  _GeneratableField(
                    label: 'Vault Key',
                    controller: _vaultKeyCtrl,
                    obscure: true,
                    onGenerate: _generateVaultKey,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 12) return 'Min 12 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ], // ListView children
              ), // ListView
            ), // ConstrainedBox
          ), // Center
        ), // Form
      ), // SafeArea
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 48),
        const SizedBox(height: 12),
        Text(
          'Create Account',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up your secure vault',
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 14),
        ),
      ],
    );
  }
}

class _VaultKeyInfo extends StatelessWidget {
  const _VaultKeyInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vault Key encrypts all your passwords. '
              'Store it safely — it cannot be recovered.',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratableField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onGenerate;
  final String? Function(String?)? validator;

  const _GeneratableField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onGenerate,
    this.validator,
  });

  @override
  State<_GeneratableField> createState() => _GeneratableFieldState();
}

class _GeneratableFieldState extends State<_GeneratableField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high_rounded,
                  size: 18, color: AppTheme.primary),
              tooltip: 'Generate',
              onPressed: widget.onGenerate,
            ),
          ],
        ),
      ),
    );
  }
}
