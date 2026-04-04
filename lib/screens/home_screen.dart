import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../features/vault/vault_screen.dart';
import '../features/authenticator/authenticator_screen.dart';
import '../features/generator/generator_screen.dart';
import '../features/settings/settings_screen.dart';
import '../services/totp_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    VaultScreen(),
    AuthenticatorScreen(),
    GeneratorScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_rounded,
      label: 'Vault'
    ),
    (
      icon: Icons.qr_code_2_outlined,
      activeIcon: Icons.qr_code_2_rounded,
      label: 'Auth'
    ),
    (
      icon: Icons.password_outlined,
      activeIcon: Icons.password_rounded,
      label: 'Generator'
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // ── Desktop / Wide Tablet (≥900px) ─────────────────────
    if (width >= Breakpoints.mobile) {
      final isDesktop = width >= Breakpoints.desktop;
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────
            _DesktopSidebar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              expanded: isDesktop,
              navItems: _navItems,
            ),
            // ── Divider ──────────────────────────────────────
            Container(
              width: 1,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
            ),
            // ── Main Content ──────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _DesktopTopBar(
                    index: _index,
                    navItems: _navItems,
                    isAuthScreen: _index == 1,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: _screens[_index],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile (< 600px) ─────────────────────────────────────
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          _MobileTopBar(isAuthScreen: _index == 1),
          Expanded(child: _screens[_index]),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Desktop Sidebar ────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool expanded;
  final List<({IconData icon, IconData activeIcon, String label})> navItems;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.expanded,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = expanded ? 240.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Logo + Brand
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 20 : 0,
              vertical: 12,
            ),
            child: expanded
                ? Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SecuroApp',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Your secure vault',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 8),
            child: Divider(
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          // Nav items
          ...List.generate(navItems.length, (i) {
            final item = navItems[i];
            final isSelected = selectedIndex == i;
            return _SidebarNavItem(
              icon: item.icon,
              activeIcon: item.activeIcon,
              label: item.label,
              isSelected: isSelected,
              expanded: expanded,
              onTap: () => onDestinationSelected(i),
            );
          }),
          const Spacer(),
          // Footer version badge
          if (expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AES-256 Encrypted',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold)),
                        Text('v1.0.0',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Icon(Icons.verified_user_rounded,
                    color: AppTheme.primary.withValues(alpha: 0.5), size: 20),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 8, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 14 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: expanded
                ? Row(
                    children: [
                      Icon(isSelected ? activeIcon : icon,
                          color: color, size: 22),
                      const SizedBox(width: 14),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ]
                    ],
                  )
                : Center(
                    child: Icon(isSelected ? activeIcon : icon,
                        color: color, size: 22),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop Top Bar ────────────────────────────────────────────────────────

class _DesktopTopBar extends StatefulWidget {
  final int index;
  final List<({IconData icon, IconData activeIcon, String label})> navItems;
  final bool isAuthScreen;

  const _DesktopTopBar({
    required this.index,
    required this.navItems,
    required this.isAuthScreen,
  });

  @override
  State<_DesktopTopBar> createState() => _DesktopTopBarState();
}

class _DesktopTopBarState extends State<_DesktopTopBar> {
  Timer? _timer;
  int _remaining = 30;

  @override
  void initState() {
    super.initState();
    if (widget.isAuthScreen) _startTimer();
  }

  @override
  void didUpdateWidget(_DesktopTopBar old) {
    super.didUpdateWidget(old);
    if (widget.isAuthScreen && !old.isAuthScreen) {
      _startTimer();
    } else if (!widget.isAuthScreen && old.isAuthScreen) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _stopTimer() => _timer?.cancel();

  void _updateTimer() {
    if (!mounted) return;
    setState(() => _remaining = TotpService.instance.secondsRemaining());
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.navItems[widget.index].label;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Page title
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
          ),
          const Spacer(),
          // TOTP countdown for auth screen
          if (widget.isAuthScreen) ...[
            Text(
              'Refreshing in $_remaining s',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _remaining / 30,
                strokeWidth: 2.5,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Notification bell
          _NotifButton(),
        ],
      ),
    );
  }
}

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHistory(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5)),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _NotificationHistorySheet(),
    );
  }
}

// ── Mobile Top Bar ─────────────────────────────────────────────────────────

class _MobileTopBar extends StatefulWidget {
  final bool isAuthScreen;
  const _MobileTopBar({required this.isAuthScreen});

  @override
  State<_MobileTopBar> createState() => _MobileTopBarState();
}

class _MobileTopBarState extends State<_MobileTopBar> {
  Timer? _timer;
  int _remaining = 30;

  @override
  void initState() {
    super.initState();
    if (widget.isAuthScreen) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_MobileTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAuthScreen && !oldWidget.isAuthScreen) {
      _startTimer();
    } else if (!widget.isAuthScreen && oldWidget.isAuthScreen) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _updateTimer() {
    if (!mounted) return;
    setState(() {
      _remaining = TotpService.instance.secondsRemaining();
    });
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
        child: Row(
          children: [
            Text(
              'SecuroApp',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const Spacer(),
            if (widget.isAuthScreen) ...[
              Text(
                'Refreshing in $_remaining s',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: _remaining / 30,
                  strokeWidth: 2,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => _showHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _NotificationHistorySheet(),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded, color: AppTheme.primary),
              label: 'Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_2_outlined),
              selectedIcon:
                  Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
              label: 'Auth',
            ),
            NavigationDestination(
              icon: Icon(Icons.password_outlined),
              selectedIcon:
                  Icon(Icons.password_rounded, color: AppTheme.primary),
              label: 'Generator',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon:
                  Icon(Icons.settings_rounded, color: AppTheme.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationHistorySheet extends StatelessWidget {
  const _NotificationHistorySheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Icon(Icons.notifications_rounded,
                  color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text('Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(height: 1),
        const _NotifTile(
          icon: Icons.shield_rounded,
          title: 'Vault secured',
          subtitle: 'AES-256 encryption active',
          time: 'Now',
        ),
        const _NotifTile(
          icon: Icons.lock_rounded,
          title: 'Auto-lock enabled',
          subtitle: 'Vault locks after 5 minutes of inactivity',
          time: 'Session',
        ),
        const _NotifTile(
          icon: Icons.copy_rounded,
          title: 'Clipboard guard active',
          subtitle: 'Copied passwords auto-clear after 30s',
          time: 'Always on',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 24),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(time, style: Theme.of(context).textTheme.labelSmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
