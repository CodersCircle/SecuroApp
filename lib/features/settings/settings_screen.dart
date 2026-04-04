import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:securo_app/screens/login_screen.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/drive_backup_service.dart';
import '../../services/import_export_service.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/encryption_service.dart';
import '../../database/app_database.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.adaptive(
            context,
            mobile: double.infinity,
            tablet: 700,
            desktop: Responsive.contentMaxWidth,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            Responsive.sp4,
            Responsive.horizontalPadding(context),
            Responsive.isWide(context) ? Responsive.sp6 : 120,
          ),
          children: [
            const _ProfileCard(),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'General'),
            const _SectionCard(
              children: [
                _ThemeTile(),
                _NotificationTile(),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Vault Management'),
            const _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Import Vault',
                  subtitle: 'CSV or JSON format',
                  isImport: true,
                ),
                _SettingsTile(
                  icon: Icons.download_rounded,
                  title: 'Export as CSV',
                  exportFormat: 'csv',
                ),
                _SettingsTile(
                  icon: Icons.cloud_done_outlined,
                  title: 'Google Drive Backup',
                  subtitle: 'Secure encrypted cloud backup',
                  isDriveBackup: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Security'),
            _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Unlock',
                  subtitle: 'Fingerprint or Face ID',
                  trailing: Switch.adaptive(value: true, onChanged: (v) {}),
                ),
                _SettingsTile(
                  icon: Icons.phonelink_lock_rounded,
                  title: 'Auto-lock timeout',
                  subtitle: '5 minutes',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Account'),
            const _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  isLogout: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 32, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text('SecuroApp v1.0.0',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text('AES-256 Military Grade Encryption',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────

class _ProfileCard extends StatefulWidget {
  const _ProfileCard();

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.instance.getProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _AvatarWidget(
              avatarPath: profile?.avatarPath,
              username: profile?.username ?? '',
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.username ?? 'Securo User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile?.email ?? 'Protecting your data',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Widget ─────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarPath;
  final String username;
  final double size;

  const _AvatarWidget({
    required this.avatarPath,
    required this.username,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath != null && File(avatarPath!).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        image: hasAvatar
            ? DecorationImage(
                image: FileImage(File(avatarPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasAvatar
          ? null
          : Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

// ── Profile Edit Screen ───────────────────────────────────────────────────

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.instance.getProfile();
    if (mounted && p != null) {
      setState(() {
        _usernameCtrl.text = p.username;
        _emailCtrl.text = p.email;
        _avatarPath = p.avatarPath;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      try {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: AppTheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          setState(() => _avatarPath = croppedFile.path);
        }
      } catch (e) {
        debugPrint('Image Cropper Error: $e');
        // Fallback to uncropped image if cropper fails
        setState(() => _avatarPath = picked.path);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    // Update basic profile
    await AuthService.instance.updateProfile(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      avatarPath: _avatarPath,
    );

    if (_passwordCtrl.text.isNotEmpty || _pinCtrl.text.isNotEmpty) {
      if (_passwordCtrl.text.isNotEmpty) {
        await AuthService.instance.updateMasterPassword(_passwordCtrl.text);
      }
      if (_pinCtrl.text.isNotEmpty) {
        await AuthService.instance.saveMpin(_pinCtrl.text);
      }
      scaffold.showSnackBar(
          const SnackBar(content: Text('Security settings updated.')));
    }

    navigator.pop();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  _AvatarWidget(
                    avatarPath: _avatarPath,
                    username: _usernameCtrl.text,
                    size: 100,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const _SectionHeader(title: 'Personal Info'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Username',
              controller: _usernameCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            const _SectionHeader(title: 'Security Updates (Optional)'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'New Master Password',
              controller: _passwordCtrl,
              obscureText: true,
              showToggle: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'New MPIN (6 Digits)',
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length != 6) {
                  return 'MPIN must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications Toggle ──────────────────────────────────────────────────

class _NotificationTile extends StatefulWidget {
  const _NotificationTile();

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _isEnabled = NotificationService.instance.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.notifications_none_rounded,
            color: AppTheme.primary, size: 22),
      ),
      title: const Text('Notifications',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Manage vault alerts',
          style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch.adaptive(
        value: _isEnabled,
        activeTrackColor: AppTheme.primary,
        onChanged: (val) async {
          setState(() => _isEnabled = val);
          await NotificationService.instance.setEnabled(val);
        },
      ),
    );
  }
}

// ── Settings Tile ────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? exportFormat;
  final bool isImport;
  final bool isDriveBackup;
  final bool isLogout;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.exportFormat,
    this.isImport = false,
    this.isDriveBackup = false,
    this.isLogout = false,
    this.trailing,
    this.onTap,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (isLogout) {
      final navigator = Navigator.of(context);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    final scaffold = ScaffoldMessenger.of(context);

    // ✅ Initialize EncryptionService before export
    if (!EncryptionService.instance.isInitialized) {
      scaffold.showSnackBar(const SnackBar(
          content:
              Text('Error: Encryption engine not ready. Please restart app.'),
          backgroundColor: AppTheme.error));
      return;
    }

    try {
      if (exportFormat != null) {
        // Let user choose what to export
        final exportChoice = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text('Export Data'),
                    content: const Text('What would you like to export?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, 'vault'),
                          child: const Text('Vault Passwords')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, 'auth'),
                          child: const Text('Authenticator Keys')),
                    ]));

        if (exportChoice == null) return; // User canceled

        final svc = ImportExportService.instance;

        if (exportChoice == 'vault') {
          final items = await appDatabase.getAllPasswords();
          if (items.isEmpty) {
            scaffold.showSnackBar(const SnackBar(
                content: Text('No passwords to export.'),
                behavior: SnackBarBehavior.floating));
            return;
          }
          switch (exportFormat) {
            case 'csv':
              await svc.exportAsCSV(items);
            case 'json':
              await svc.exportAsJSON(items);
            case 'txt':
              await svc.exportAsTXT(items);
          }
        } else if (exportChoice == 'auth') {
          scaffold.showSnackBar(const SnackBar(
              content: Text('Authenticator export coming soon.'),
              behavior: SnackBarBehavior.floating));
        }
      } else if (isImport) {
        final rows = await ImportExportService.instance.importFromFile();
        if (rows != null && rows.isNotEmpty) {
          // ACTUALLY IMPORT THE PASSWORDS INTO THE DATABASE
          int successCount = 0;
          for (final row in rows) {
            final platform =
                row['platform'] ?? row['Platform Name'] ?? 'Imported';
            final username = row['username'] ?? row['Username'] ?? '';
            final passwordRaw = row['password'] ?? row['Password'] ?? '';
            final group = row['group'] ?? row['Group'] ?? 'Personal';
            final notes = row['notes'] ?? row['Notes'] ?? '';

            if (passwordRaw.isNotEmpty) {
              final encrypted = EncryptionService.instance.encrypt(passwordRaw);
              await appDatabase.insertPassword(PasswordItemsCompanion.insert(
                platformName: platform,
                username: username,
                encryptedPassword: encrypted,
                notes: Value(notes),
                groupName: Value(group),
                iconEmoji: const Value('🔑'),
                websiteUrl: const Value(''),
              ));
              successCount++;
            }
          }
          await NotificationService.instance.notifyImportComplete(successCount);
          scaffold.showSnackBar(SnackBar(
              content: Text('$successCount entries imported successfully.'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating));
        } else if (rows != null && rows.isEmpty) {
          scaffold.showSnackBar(const SnackBar(
              content: Text('No valid entries found to import.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating));
        }
      } else if (isDriveBackup) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('Starting Google Drive backup...'),
            behavior: SnackBarBehavior.floating));
        final ok = await DriveBackupService.instance.backupToDrive();
        if (ok) {
          await NotificationService.instance.notifyBackupComplete();
          scaffold.showSnackBar(const SnackBar(
              content: Text('Backup successful!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating));
        } else {
          scaffold.showSnackBar(const SnackBar(
              content:
                  Text('Backup failed. Please check Google Sign-In setup.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating));
        }
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? AppTheme.error : AppTheme.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isLogout ? AppTheme.error : null)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: trailing ??
          (onTap != null ||
                  exportFormat != null ||
                  isImport ||
                  isDriveBackup ||
                  isLogout
              ? const Icon(Icons.chevron_right_rounded, size: 20)
              : null),
      onTap: onTap ??
          ((exportFormat != null || isImport || isDriveBackup || isLogout)
              ? () => _handleTap(context)
              : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final mode = ThemeService.instance.themeMode;
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.palette_outlined,
                color: AppTheme.primary, size: 22),
          ),
          title: const Text('Theme Mode',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(mode.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 16)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 16)),
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_outlined, size: 16)),
            ],
            selected: {mode},
            onSelectionChanged: (set) =>
                ThemeService.instance.setThemeMode(set.first),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        );
      },
    );
  }
}
