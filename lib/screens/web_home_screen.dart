import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../database/app_database.dart';
import '../features/authenticator/authenticator_screen.dart';
import '../features/generator/generator_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/vault/vault_screen.dart';
import '../main.dart' show appDatabase;
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
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
  bool _importing = false;
  String? _importError;

  static const _screens = [
    VaultScreen(),
    AuthenticatorScreen(),
    GeneratorScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialVaultData != null) {
      _importVaultData(widget.initialVaultData!);
    }
  }

  /// Writes the synced vault payload into the local database.
  /// Passwords arrive as plain-text (decrypted by link_service before delivery)
  /// and we re-encrypt them with the local EncryptionService key.
  Future<void> _importVaultData(Map<String, dynamic> data) async {
    if (!mounted) return;
    setState(() => _importing = true);

    try {
      // ── Clear existing data first (prevent duplicates on re-scan) ──
      await appDatabase.deleteAllPasswords();
      await appDatabase.deleteAllTotp();

      // ── Passwords ───────────────────────────────────────
      final passwords = data['passwords'];
      if (passwords is List) {
        for (final entry in passwords) {
          final plain = entry['password'] as String? ?? '';
          final enc = EncryptionService.instance.encrypt(plain);
          await appDatabase.insertPassword(PasswordItemsCompanion.insert(
            platformName: entry['platform'] as String? ?? 'Imported',
            username: entry['username'] as String? ?? '',
            encryptedPassword: enc,
            notes: Value(entry['notes'] as String? ?? ''),
            groupName: Value(entry['group'] as String? ?? 'Personal'),
            iconEmoji: Value(entry['iconEmoji'] as String? ?? '🔑'),
            websiteUrl: Value(entry['websiteUrl'] as String? ?? ''),
          ));
        }
      }

      // ── TOTP accounts ────────────────────────────────────
      final totp = data['totp'];
      if (totp is List) {
        for (final entry in totp) {
          await appDatabase.insertTotp(TotpAccountsCompanion.insert(
            issuer: entry['issuer'] as String? ?? '',
            accountName: entry['accountName'] as String? ?? '',
            secretKey: entry['secretKey'] as String? ?? '',
            iconEmoji: Value(entry['iconEmoji'] as String? ?? '🔐'),
            digits:
                Value(int.tryParse(entry['digits']?.toString() ?? '6') ?? 6),
            period:
                Value(int.tryParse(entry['period']?.toString() ?? '30') ?? 30),
          ));
        }
      }

      // ── User profile ─────────────────────────────────────
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        final username = profile['username'] as String? ?? '';
        final email = profile['email'] as String? ?? '';
        if (username.isNotEmpty) {
          await AuthService.instance.updateProfile(
            username: username,
            email: email,
          );
        }
      }

      if (mounted) setState(() => _importing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _importError = e.toString();
        });
      }
    }
  }

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > Responsive.tabletMax;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Import progress banner ─────────────────────
          if (_importing)
            Material(
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Importing vault from mobile…',
                      style: tt.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          if (_importError != null)
            Material(
              color: AppTheme.error.withValues(alpha: 0.1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Import error: $_importError',
                        style: tt.labelSmall?.copyWith(color: AppTheme.error)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: AppTheme.error),
                    onPressed: () => setState(() => _importError = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ),
            ),

          // ── Main shell ────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Navigation Rail
                NavigationRail(
                  extended: isDesktop,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: isDesktop
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  minWidth: isDesktop ? 220 : 72,
                  minExtendedWidth: 220,
                  groupAlignment: -1.0,
                  backgroundColor: cs.surface,
                  indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
                  selectedIconTheme:
                      const IconThemeData(color: AppTheme.primary),
                  selectedLabelTextStyle: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: tt.labelMedium?.fontSize),
                  unselectedIconTheme: IconThemeData(
                      color: cs.onSurface.withValues(alpha: 0.45)),
                  unselectedLabelTextStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: tt.labelMedium?.fontSize),
                  leading: SizedBox(
                    width: isDesktop ? 220 : 72,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 20,
                        bottom: 8,
                        left: isDesktop ? 16 : 0,
                        right: isDesktop ? 16 : 0,
                      ),
                      child: isDesktop
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shield_rounded,
                                      color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'SecuroApp',
                                  style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface),
                                ),
                              ],
                            )
                          : Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shield_rounded,
                                    color: AppTheme.primary, size: 20),
                              ),
                            ),
                    ),
                  ),
                  trailing: SizedBox(
                    width: isDesktop ? 220 : 72,
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: 20,
                          left: isDesktop ? 16 : 4,
                          right: isDesktop ? 16 : 4),
                      child: _DisconnectButton(
                          onTap: _goToQr, extended: isDesktop),
                    ),
                  ),
                  destinations: _destinations,
                ),

                VerticalDivider(
                    width: 1, thickness: 1, color: cs.outlineVariant),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WhsTopBar(
                          isAuthScreen: _index == 1,
                          currentIndex: _index,
                          onDisconnect: _goToQr),
                      Expanded(child: _screens[_index]),
                    ],
                  ),
                ),
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
  final int currentIndex;
  final VoidCallback onDisconnect;

  const _WhsTopBar({
    required this.isAuthScreen,
    required this.currentIndex,
    required this.onDisconnect,
  });

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenTitles = ['Vault', 'Authenticator', 'Generator', 'Settings'];

    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Screen title — left aligned
                Text(
                  screenTitles[widget.currentIndex],
                  style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const Spacer(),
                // TOTP countdown (only on Authenticator tab)
                if (widget.isAuthScreen) ...[
                  Text(
                    'Refreshing in $_remaining s',
                    style: tt.labelSmall?.copyWith(
                        color:
                            _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      value: _remaining / 30,
                      strokeWidth: 2.5,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                        _remaining <= 5 ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Link device icon button
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Link new device',
                  color: cs.onSurface.withValues(alpha: 0.7),
                  onPressed: widget.onDisconnect,
                ),
              ],
            ),
          ),
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
      return FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(160, 44),
          maximumSize: const Size(200, 44),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 18),
            SizedBox(width: 8),
            Text('Link Device'),
          ],
        ),
      );
    }
    return IconButton.filled(
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
      tooltip: 'Link Device',
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
        foregroundColor: AppTheme.primary,
      ),
      onPressed: onTap,
    );
  }
}
