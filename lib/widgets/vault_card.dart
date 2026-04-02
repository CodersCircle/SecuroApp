import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/clipboard_util.dart';
import '../database/app_database.dart';
import '../services/encryption_service.dart';

class VaultCard extends StatelessWidget {
  final PasswordItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const VaultCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _IconBadge(emoji: item.iconEmoji),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.platformName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.username,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _GroupChip(group: item.groupName),
                  ],
                ),
              ),
              _CopyButton(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final String emoji;
  const _IconBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String group;
  const _GroupChip({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        group,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final PasswordItem item;
  const _CopyButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final decrypted = EncryptionService.instance.decrypt(item.encryptedPassword);
          ClipboardUtil.copyAndAutoClear(decrypted);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password copied!', style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 100), // Above floating bar
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.copy_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
