import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';

import '../core/theme/app_theme.dart';
import '../services/link_service.dart';
import 'web_connect_screen.dart';

/// Web-only vault viewer — read-only display of synced data from mobile.
/// No editing, no auth, just view copied passwords + TOTP codes.
class WebVaultScreen extends StatefulWidget {
  final Map<String, dynamic> vaultData;

  const WebVaultScreen({super.key, required this.vaultData});

  @override
  State<WebVaultScreen> createState() => _WebVaultScreenState();
}

class _WebVaultScreenState extends State<WebVaultScreen> {
  int _index = 0; // 0 = passwords, 1 = TOTP
  String _search = '';
  List<Map<String, String>> get _passwords {
    final raw = widget.vaultData['passwords'] as List<dynamic>? ?? [];
    return raw.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  List<Map<String, String>> get _totp {
    final raw = widget.vaultData['totp'] as List<dynamic>? ?? [];
    return raw.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  List<Map<String, String>> get _filteredPasswords {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _passwords;
    return _passwords.where((p) {
      return p['platform']!.toLowerCase().contains(q) ||
          p['username']!.toLowerCase().contains(q) ||
          (p['group'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String? _visibleId; // Track which password is currently shown
  final Map<String, String?> _totpCache = {}; // Cache TOTP codes

  void _toggleShow(String id) {
    setState(() => _visibleId = _visibleId == id ? null : id);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getCurrentTOTP(Map<String, String> entry) {
    final secretKey = entry['secretKey'] ?? '';
    if (_totpCache.containsKey(secretKey)) {
      return _totpCache[secretKey]!;
    }
    try {
      final digits = int.tryParse(entry['digits'] ?? '6') ?? 6;
      final code = OTP.generateTOTPCodeString(
        secretKey,
        DateTime.now().millisecondsSinceEpoch,
        length: digits,
        interval: int.tryParse(entry['period'] ?? '30') ?? 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      _totpCache[secretKey] = code;
      return code;
    } catch (e) {
      return 'Error';
    }
  }

  void _refreshTOTP() {
    setState(() => _totpCache.clear());
  }

  Future<void> _reconnect() async {
    await LinkService.instance.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WebConnectScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'SecuroApp Web',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _TotpRefreshBadge(
                  onRefresh: _refreshTOTP,
                  visible: _index == 1,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_passwords.length} passwords · ${_totp.length} 2FA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reconnect',
                  onPressed: _reconnect,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Disconnect',
                  onPressed: _reconnect,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),

          // ── Tab Bar ────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'Passwords',
                    icon: Icons.shield_rounded,
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _SegmentButton(
                    label: '2FA Codes',
                    icon: Icons.qr_code_2_rounded,
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                ],
              ),
            ),
          ),

          // ── Search (passwords tab only) ────────────────
          if (_index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search passwords...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

          // ── Content ────────────────────────────────────
          Expanded(
            child: _index == 0 ? _buildPasswords() : _buildTotp(),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswords() {
    final items = _filteredPasswords;

    if (items.isEmpty) {
      return Center(
        child: Text(
          _search.isNotEmpty ? 'No matching passwords' : 'No passwords synced',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = items[i];
        final id = '${p['platform']}-${p['username']}-$i';
        final isShown = _visibleId == id;
        final emoji = p['iconEmoji'] ?? '🔑';
        final platform = p['platform'] ?? 'Unknown';
        final username = p['username'] ?? '';
        final password = p['password'] ?? '';

        return Card(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(emoji,
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center),
            ),
            title: Text(platform,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: username.isNotEmpty ? Text(username) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isShown)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => _copy(password),
                    tooltip: 'Copy password',
                  ),
                if (!isShown)
                  IconButton(
                    icon: const Icon(Icons.visibility_off_outlined),
                    onPressed: () => _toggleShow(id),
                    tooltip: 'Show password',
                  ),
                if (isShown)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _toggleShow(id),
                    tooltip: 'Hide password',
                  ),
              ],
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            isThreeLine: isShown,
          ),
        );
      },
    );
  }

  Widget _buildTotp() {
    if (_totp.isEmpty) {
      return Center(
        child: Text(
          'No 2FA codes synced',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _totp.length,
      itemBuilder: (_, i) {
        final entry = _totp[i];
        final issuer = entry['issuer'] ?? '';
        final account = entry['accountName'] ?? '';
        final emoji = entry['iconEmoji'] ?? '🔐';
        final code = _getCurrentTOTP(entry);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issuer,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                if (account.isNotEmpty)
                  Text(account,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                      overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      code,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                                color: AppTheme.primary,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () => _copy(code.replaceAll(' ', '')),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? AppTheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppTheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotpRefreshBadge extends StatefulWidget {
  final VoidCallback onRefresh;
  final bool visible;

  const _TotpRefreshBadge({
    required this.onRefresh,
    required this.visible,
  });

  @override
  State<_TotpRefreshBadge> createState() => _TotpRefreshBadgeState();
}

class _TotpRefreshBadgeState extends State<_TotpRefreshBadge> {
  int _remaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = 30 - (DateTime.now().second % 30);
        if (_remaining == 0) {
          widget.onRefresh();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return SizedBox(
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
    );
  }
}
