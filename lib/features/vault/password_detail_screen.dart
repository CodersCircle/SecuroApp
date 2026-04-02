import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/clipboard_util.dart';
import '../../database/app_database.dart';
import '../../main.dart';
import '../../services/encryption_service.dart';
import 'add_password_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  final PasswordItem item;
  const PasswordDetailScreen({super.key, required this.item});

  @override
  State<PasswordDetailScreen> createState() =>
      _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _showPassword = false;

  String get _decrypted =>
      EncryptionService.instance.decrypt(widget.item.encryptedPassword);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.platformName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddPasswordScreen(editItem: widget.item),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Icon and platform header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(widget.item.iconEmoji,
                        style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.item.platformName,
                    style:
                    Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(widget.item.groupName,
                    style: const TextStyle(
                        color: AppTheme.secondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _DetailTile(
            label: 'Username / Email',
            value: widget.item.username,
            icon: Icons.person_outline_rounded,
            onCopy: () => ClipboardUtil.copyAndAutoClear(
                widget.item.username),
          ),
          const SizedBox(height: 8),
          _PasswordTile(
            value: _decrypted,
            show: _showPassword,
            onToggle: () =>
                setState(() => _showPassword = !_showPassword),
            onCopy: () => ClipboardUtil.copyAndAutoClear(_decrypted),
          ),
          if (widget.item.websiteUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailTile(
              label: 'Website',
              value: widget.item.websiteUrl,
              icon: Icons.link_rounded,
              onCopy: () => ClipboardUtil.copyAndAutoClear(
                  widget.item.websiteUrl),
            ),
          ],
          if (widget.item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailTile(
              label: 'Notes',
              value: widget.item.notes,
              icon: Icons.notes_rounded,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Created: ${_fmtDate(widget.item.createdAt)}\nUpdated: ${_fmtDate(widget.item.updatedAt)}',
            style: const TextStyle(
                color: AppTheme.onSurfaceMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text(
            'Delete ${widget.item.platformName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await appDatabase.deletePassword(widget.item.id);
    navigator.pop();
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onCopy;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontSize: 15)),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppTheme.onSurfaceMuted,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _PasswordTile extends StatelessWidget {
  final String value;
  final bool show;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  const _PasswordTile({
    required this.value,
    required this.show,
    required this.onToggle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Password',
                    style: TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  show ? value : '••••••••••••',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: show ? 15 : 22,
                    letterSpacing: show ? 0 : 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              show
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
            ),
            color: AppTheme.onSurfaceMuted,
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppTheme.onSurfaceMuted,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
