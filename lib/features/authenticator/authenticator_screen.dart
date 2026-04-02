import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../database/app_database.dart';
import '../../main.dart';
import '../../services/notification_service.dart';
import '../../widgets/totp_card.dart';
import 'add_totp_screen.dart';

class AuthenticatorScreen extends StatelessWidget {
  const AuthenticatorScreen({super.key});

  void _deleteTotp(TotpAccount account) async {
    await appDatabase.deleteTotp(account.id);
    await NotificationService.instance.notifyTotpDeleted(account.issuer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<TotpAccount>>(
              stream: appDatabase.watchAllTotp(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final accounts = snapshot.data!;
                if (accounts.isEmpty) {
                  return const _EmptyAuthState();
                }
                final isWide = MediaQuery.sizeOf(context).width >= 600;

                return isWide
                    ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, i) {
                    final account = accounts[i];
                    return Dismissible(
                      key: ValueKey(account.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
                      ),
                      onDismissed: (_) => _deleteTotp(account),
                      child: TotpCard(
                        account: account,
                        onDelete: () => _deleteTotp(account),
                      ),
                    );
                  },
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, i) {
                    final account = accounts[i];
                    return Dismissible(
                      key: ValueKey(account.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
                      ),
                      onDismissed: (_) => _deleteTotp(account),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TotpCard(
                          account: account,
                          onDelete: () => _deleteTotp(account),
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
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTotpScreen()),
          ),
          elevation: 4,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
}

class _EmptyAuthState extends StatelessWidget {
  const _EmptyAuthState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded,
              size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text('No 2FA accounts',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Tap + to scan a QR code or enter a key',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )),
        ],
      ),
    );
  }
}
