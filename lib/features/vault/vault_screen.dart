import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../database/app_database.dart';
import '../../main.dart';
import '../../services/notification_service.dart';
import '../../widgets/vault_card.dart';
import 'add_password_screen.dart';
import 'password_detail_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedGroup = 'Social Media';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _deleteItem(PasswordItem item) async {
    await appDatabase.deletePassword(item.id);
    await NotificationService.instance.notifyPasswordDeleted(item.platformName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(
            controller: _searchCtrl,
            onSearch: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: 12),
          _GroupFilterRow(
            selected: _selectedGroup,
            onSelect: (g) => setState(() => _selectedGroup = g),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<PasswordItem>>(
              stream: appDatabase.watchAllPasswords(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var items = snapshot.data!;

                if (_selectedGroup != 'All') {
                  items = items
                      .where((i) => i.groupName == _selectedGroup)
                      .toList();
                }

                if (_query.isNotEmpty) {
                  final q = _query.toLowerCase();
                  items = items
                      .where((i) =>
                          i.platformName.toLowerCase().contains(q) ||
                          i.username.toLowerCase().contains(q))
                      .toList();
                }

                if (items.isEmpty) {
                  return const _EmptyState();
                }

                final isWide =
                    MediaQuery.sizeOf(context).width > Responsive.mobileMax;
                final isDesktop =
                    MediaQuery.sizeOf(context).width > Responsive.tabletMax;
                final crossCount = isDesktop
                    ? 3
                    : isWide
                        ? 2
                        : 1;

                return isWide
                    ? GridView.builder(
                        padding: Responsive.listPadding(context),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          mainAxisExtent: 110,
                          crossAxisSpacing: Responsive.sp3,
                          mainAxisSpacing: Responsive.sp3,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 32),
                            ),
                            onDismissed: (_) => _deleteItem(item),
                            child: VaultCard(
                              item: item,
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PasswordDetailScreen(item: item),
                                ),
                              ),
                              onDelete: () => _deleteItem(item),
                            ),
                          );
                        })
                    : ListView.builder(
                        padding: Responsive.listPadding(context),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 32),
                            ),
                            onDismissed: (_) => _deleteItem(item),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: VaultCard(
                                item: item,
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PasswordDetailScreen(item: item),
                                  ),
                                ),
                                onDelete: () => _deleteItem(item),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: Responsive.fabPadding(context),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
          ),
          elevation: 4,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  const _Header({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 4,
          Responsive.horizontalPadding(context), Responsive.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SearchBar(
            controller: controller,
            hintText: 'Search passwords...',
            onChanged: onSearch,
            leading:
                const Icon(Icons.search_rounded, size: 22, color: Colors.grey),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5)),
              ),
            ),
            padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16)),
          ),
        ],
      ),
    );
  }
}

class _GroupFilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _GroupFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context)),
        itemCount: AppConstants.defaultGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final group = AppConstants.defaultGroups[i];
          final isSelected = selected == group;
          return FilterChip(
            label: Text(group),
            selected: isSelected,
            onSelected: (_) => onSelect(group),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: AppTheme.primary,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_reset_rounded,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text('No items found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Try a different search or add a new password',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  )),
        ],
      ),
    );
  }
}
