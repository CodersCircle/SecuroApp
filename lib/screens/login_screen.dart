import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final exists = await AuthService.instance
        .usernameExists(_usernameCtrl.text.trim());

    if (!mounted) return;
    setState(() => _checking = false);

    if (!exists) {
      setState(() => _error = 'Username not found');
      return;
    }

    // Show unlock popup
    final unlocked = await _showUnlockDialog();
    if (unlocked == true && mounted) {
      await AuthService.instance.unlockVault();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    }
  }

  Future<bool?> _showUnlockDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _UnlockDialog(
        username: _usernameCtrl.text.trim(),
        onUnlocked: () => Navigator.pop(dialogCtx, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LoginHeader(),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon:
                        Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _proceed(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _checking ? null : _proceed,
                      child: _checking
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 52),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your username to unlock SecuroApp',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
        ),
      ],
    );
  }
}

// ── Unlock Dialog ──────────────────────────────────────────────────────────

class _UnlockDialog extends StatefulWidget {
  final String username;
  final VoidCallback onUnlocked;

  const _UnlockDialog({
    required this.username,
    required this.onUnlocked,
  });

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _mpinCtrl = TextEditingController();
  bool _hasMpin = false;
  bool _bioEnabled = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasMpin = await AuthService.instance.hasMpin;
    final bioEnabled = await AuthService.instance.isBioEnabled;
    if (mounted) {
      setState(() {
        _hasMpin = hasMpin;
        _bioEnabled = bioEnabled;
        _loading = false;
      });
      if (bioEnabled) _tryBio();
    }
  }

  Future<void> _tryBio() async {
    final ok = await AuthService.instance.verifyBiometric();
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _verifyMpin() async {
    final ok =
    await AuthService.instance.verifyMpin(_mpinCtrl.text);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Incorrect MPIN';
        _mpinCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _mpinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView( // Added scroll view to prevent overflow
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _loading
              ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()))
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  children: [
                    const TextSpan(text: 'Unlock as\n'),
                    TextSpan(
                      text: widget.username,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_bioEnabled) ...[
                _UnlockOption(
                  icon: Icons.fingerprint_rounded,
                  label: 'Use Biometrics',
                  color: AppTheme.secondary,
                  onTap: _tryBio,
                ),
                if (_hasMpin) ...[
                  const SizedBox(height: 24),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: AppTheme.onSurfaceMuted,
                              fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 24),
                ],
              ],
              if (_hasMpin) ...[
                Text(
                  'Enter MPIN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _error != null
                            ? AppTheme.error
                            : AppTheme.primary.withValues(alpha: 0.4),
                        width: 1.5),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  ),
                  child: TextField(
                    controller: _mpinCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    obscureText: true,
                    obscuringCharacter: '●',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, letterSpacing: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '●●●●●●',
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) {
                      if (_error != null) setState(() => _error = null);
                      if (v.length == 6) _verifyMpin();
                    },
                    onSubmitted: (_) => _verifyMpin(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _mpinCtrl.text.length == 6 ? _verifyMpin : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Unlock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
              if (!_hasMpin && !_bioEnabled)
                const Text(
                  'No unlock method set.\nPlease re-register.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onSurfaceMuted),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UnlockOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
