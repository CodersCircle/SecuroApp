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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet =
        width >= Responsive.mobileMax + 1 && width <= Responsive.tabletMax;
    final isDesktop = width > Responsive.tabletMax;
    final isWide = isTablet || isDesktop;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: isDesktop,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: isDesktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              minWidth: isDesktop ? 200 : 72,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedIconTheme: const IconThemeData(color: AppTheme.primary),
              selectedLabelTextStyle: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
              unselectedIconTheme: IconThemeData(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
              unselectedLabelTextStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
              leading: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.sp6,
                  horizontal: isDesktop ? Responsive.sp4 : 0,
                ),
                child: isDesktop
                    ? Row(children: [
                        const Icon(Icons.shield_rounded,
                            color: AppTheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text('SecuroApp',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )),
                      ])
                    : const Icon(Icons.shield_rounded,
                        color: AppTheme.primary, size: 28),
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield_rounded),
                    label: Text('Vault')),
                NavigationRailDestination(
                    icon: Icon(Icons.qr_code_2_outlined),
                    selectedIcon: Icon(Icons.qr_code_2_rounded),
                    label: Text('Authenticator')),
                NavigationRailDestination(
                    icon: Icon(Icons.password_outlined),
                    selectedIcon: Icon(Icons.password_rounded),
                    label: Text('Generator')),
                NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(isAuthScreen: _index == 1),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop
                              ? Responsive.contentMaxWidth
                              : Responsive.cardMaxWidth,
                        ),
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

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          _TopBar(isAuthScreen: _index == 1),
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

class _TopBar extends StatefulWidget {
  final bool isAuthScreen;
  const _TopBar({required this.isAuthScreen});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
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
  void didUpdateWidget(_TopBar oldWidget) {
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
