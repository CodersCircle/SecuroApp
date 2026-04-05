import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../features/authenticator/authenticator_screen.dart';
import '../features/generator/generator_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/vault/vault_screen.dart';
import '../services/totp_service.dart';
import 'web_connect_screen.dart';

/// Full app shell for Web/Desktop — mirrors mobile HomeScreen.
/// Shown after QR scan. All screens use appDatabase (already web-capable).
class WebHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialVaultData;

  const WebHomeScreen({super.key, this.initialVaultData});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  int _index = 0;

  static const _screens = [
    VaultScreen(),
    AuthenticatorScreen(),
    GeneratorScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.shield_outlined),
      selectedIcon: Icon(Icons.shield_rounded),
      label: Text('Vault'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.qr_code_2_outlined),
      selectedIcon: Icon(Icons.qr_code_2_rounded),
      label: Text('Authenticator'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.password_outlined),
      selectedIcon: Icon(Icons.password_rounded),
      label: Text('Generator'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Settings'),
    ),
  ];

  void _goToQr() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WebConnectScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > Responsive.tabletMax;

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
                      Text(
                        'SecuroApp',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ])
                  : const Icon(Icons.shield_rounded,
                      color: AppTheme.primary, size: 28),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: Responsive.sp6),
              child: isDesktop
                  ? _DisconnectButton(onTap: _goToQr, extended: true)
                  : _DisconnectButton(onTap: _goToQr, extended: false),
            ),
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _WhsTopBar(isAuthScreen: _index == 1, onDisconnect: _goToQr),
                Expanded(child: _screens[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _WhsTopBar extends StatefulWidget {
  final bool isAuthScreen;
  final VoidCallback onDisconnect;

  const _WhsTopBar({required this.isAuthScreen, required this.onDisconnect});

  @override
  State<_WhsTopBar> createState() => _WhsTopBarState();
}

class _WhsTopBarState extends State<_WhsTopBar> {
  Timer? _timer;
  int _remaining = 30;

  @override
  void initState() {
    super.initState();
    if (widget.isAuthScreen) _startTimer();
  }

  @override
  void didUpdateWidget(_WhsTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAuthScreen && !oldWidget.isAuthScreen) {
      _startTimer();
    } else if (!widget.isAuthScreen && oldWidget.isAuthScreen) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _updateRemaining();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateRemaining() {
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
        child: Row(
          children: [
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
              const SizedBox(width: 12),
            ],
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Back to QR / Link new device',
              onPressed: widget.onDisconnect,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Disconnect Button ───────────────────────────────────────────────────────

class _DisconnectButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool extended;

  const _DisconnectButton({required this.onTap, required this.extended});

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
          label: const Text('Link Device'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary, width: 0.8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
      tooltip: 'Link Device',
      color: AppTheme.primary,
      onPressed: onTap,
    );
  }
}
