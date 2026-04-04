import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/app_database.dart';
import '../../main.dart';
import '../../services/encryption_service.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/password_strength_indicator.dart';

class AddPasswordScreen extends StatefulWidget {
  final PasswordItem? editItem;
  const AddPasswordScreen({super.key, this.editItem});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _platformCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedGroup = 'Personal';
  String _selectedIcon = '🔑';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _platformCtrl.text = item.platformName;
      _usernameCtrl.text = item.username;
      _passwordCtrl.text =
          EncryptionService.instance.decrypt(item.encryptedPassword);
      _urlCtrl.text = item.websiteUrl;
      _notesCtrl.text = item.notes;
      _selectedGroup = item.groupName;
      _selectedIcon = item.iconEmoji;
    }
  }

  @override
  void dispose() {
    _platformCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _updateIcon(String platformName) {
    final logo = AppConstants.getLogoForPlatform(platformName);
    if (logo.isNotEmpty) {
      setState(() => _selectedIcon = logo);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final isEdit = widget.editItem != null;
    final platformName = _platformCtrl.text.trim();

    final encrypted = EncryptionService.instance.encrypt(_passwordCtrl.text);
    final now = Value(DateTime.now());

    final companion = PasswordItemsCompanion(
      platformName: Value(platformName),
      username: Value(_usernameCtrl.text.trim()),
      encryptedPassword: Value(encrypted),
      notes: Value(_notesCtrl.text),
      groupName: Value(_selectedGroup),
      iconEmoji: Value(_selectedIcon),
      websiteUrl: Value(_urlCtrl.text.trim()),
      updatedAt: now,
    );

    if (isEdit) {
      await appDatabase
          .updatePassword(companion.copyWith(id: Value(widget.editItem!.id)));
    } else {
      await appDatabase.insertPassword(companion);
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editItem != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(isEdit ? 'Edit Vault Entry' : 'New Vault Entry'),
          centerTitle: true),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Responsive.formMaxWidth),
            child: ListView(
              padding: Responsive.pagePadding(context),
              children: [
                const _SectionTitle(title: 'Categorization'),
                const SizedBox(height: 12),
                _GroupChipSelector(
                    selected: _selectedGroup,
                    onChanged: (g) => setState(() => _selectedGroup = g)),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Choose Icon'),
                const SizedBox(height: 12),
                _IconPicker(
                    selected: _selectedIcon,
                    onSelect: (e) => setState(() => _selectedIcon = e)),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'Platform Info'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Platform Name',
                  controller: _platformCtrl,
                  onChanged: _updateIcon,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Username / Email',
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'Security'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: true,
                  showToggle: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordCtrl,
                  builder: (_, val, __) =>
                      PasswordStrengthIndicator(password: val.text),
                ),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'Additional Details'),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Website URL',
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final uri = Uri.tryParse(v);
                    if (uri == null || !uri.hasAbsolutePath)
                      return 'Enter a valid URL';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Notes',
                  controller: _notesCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Update Entry' : 'Add to Vault',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ], // ListView children
            ), // ListView
          ), // ConstrainedBox
        ), // Center
      ), // Form
    ); // Scaffold
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _IconPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.platformIcons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final e = AppConstants.platformIcons[i];
          final isSelected = e == selected;
          return GestureDetector(
            onTap: () => onSelect(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 2),
              ),
              child:
                  Center(child: Text(e, style: const TextStyle(fontSize: 20))),
            ),
          );
        },
      ),
    );
  }
}

class _GroupChipSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _GroupChipSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppConstants.defaultGroups.map((g) {
          final isSelected = selected == g;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: (v) {
                if (v) onChanged(g);
              },
              showCheckmark: false,
              side: BorderSide.none,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
