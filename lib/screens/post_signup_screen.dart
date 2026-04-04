import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class PostSignupScreen extends StatefulWidget {
  const PostSignupScreen({super.key});

  @override
  State<PostSignupScreen> createState() => _PostSignupScreenState();
}

class _PostSignupScreenState extends State<PostSignupScreen> {
  final _mpinCtrl = TextEditingController();
  final _mpinConfirmCtrl = TextEditingController();
  bool _bioEnabled = false;
  bool _bioAvailable = false;
  bool _saving = false;
  String? _mpinError;

  @override
  void initState() {
    super.initState();
    _checkBio();
  }

  Future<void> _checkBio() async {
    final available = await AuthService.instance.isBioAvailable;
    if (mounted) setState(() => _bioAvailable = available);
  }

  @override
  void dispose() {
    _mpinCtrl.dispose();
    _mpinConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final mpin = _mpinCtrl.text;
    if (mpin.isNotEmpty) {
      if (mpin.length != 6) {
        setState(() => _mpinError = 'MPIN must be 6 digits');
        return;
      }
      if (mpin != _mpinConfirmCtrl.text) {
        setState(() => _mpinError = 'MPINs do not match');
        return;
      }
    }

    setState(() => _saving = true);
    final navigator = Navigator.of(context);

    if (mpin.isNotEmpty) {
      await AuthService.instance.saveMpin(mpin);
    }
    await AuthService.instance.setBioEnabled(_bioEnabled);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Responsive.formMaxWidth),
            child: ListView(
              padding: Responsive.pagePadding(context),
              children: [
                const SizedBox(height: 24),
                const _SetupHeader(),
                const SizedBox(height: 32),
                // MPIN Section
                const _SectionLabel(
                  icon: Icons.pin_outlined,
                  title: 'Set MPIN (Optional)',
                  subtitle: 'Quick 6-digit unlock pin',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mpinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  obscureText: true,
                  obscuringCharacter: '●',
                  decoration: const InputDecoration(
                    labelText: 'MPIN',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() => _mpinError = null),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _mpinConfirmCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  obscureText: true,
                  obscuringCharacter: '●',
                  decoration: const InputDecoration(
                    labelText: 'Confirm MPIN',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                    counterText: '',
                  ),
                ),
                if (_mpinError != null) ...[
                  const SizedBox(height: 6),
                  Text(_mpinError!,
                      style:
                          const TextStyle(color: AppTheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 24),
                // Biometric Section
                if (_bioAvailable) ...[
                  const _SectionLabel(
                    icon: Icons.fingerprint_rounded,
                    title: 'Enable Biometrics',
                    subtitle: 'Use fingerprint or Face ID to unlock',
                  ),
                  const SizedBox(height: 8),
                  _BioToggle(
                    value: _bioEnabled,
                    onChanged: (v) => setState(() => _bioEnabled = v),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton(
                  onPressed: _saving ? null : _finish,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Get Started'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          _mpinCtrl.clear();
                          _mpinConfirmCtrl.clear();
                          _finish();
                        },
                  child: const Text('Skip for now',
                      style: TextStyle(color: AppTheme.onSurfaceMuted)),
                ),
              ], // ListView children
            ), // ListView
          ), // ConstrainedBox
        ), // Center
      ), // SafeArea
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_open_rounded, color: AppTheme.primary, size: 48),
        const SizedBox(height: 12),
        Text(
          'Secure Your Vault',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add quick unlock options',
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
              Text(subtitle,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BioToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BioToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Biometric Unlock',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        secondary:
            const Icon(Icons.fingerprint_rounded, color: AppTheme.primary),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
      ),
    );
  }
}
