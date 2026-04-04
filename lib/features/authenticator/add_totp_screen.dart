import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../database/app_database.dart';
import '../../main.dart';
import '../../services/totp_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_text_field.dart';

class AddTotpScreen extends StatefulWidget {
  const AddTotpScreen({super.key});

  @override
  State<AddTotpScreen> createState() => _AddTotpScreenState();
}

class _AddTotpScreenState extends State<AddTotpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _issuerCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _issuerCtrl.dispose();
    _accountCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final code = TotpService.instance.generateCode(_secretCtrl.text);
    if (code == '------') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid secret key'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final issuer = _issuerCtrl.text.trim();
    await appDatabase.insertTotp(
      TotpAccountsCompanion(
        issuer: Value(issuer),
        accountName: Value(_accountCtrl.text.trim()),
        secretKey: Value(_secretCtrl.text.trim()),
      ),
    );

    await NotificationService.instance.notifyTotpAdded(issuer);

    if (mounted) Navigator.pop(context);
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;
    _scanned = true;

    final parsed = TotpService.instance.parseOtpAuthUri(rawValue);
    if (parsed != null) {
      setState(() {
        _issuerCtrl.text = parsed['issuer'] ?? '';
        _accountCtrl.text = parsed['account'] ?? '';
        _secretCtrl.text = parsed['secret'] ?? '';
      });
      _tabCtrl.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add 2FA Account'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Scan QR Code'),
            Tab(text: 'Manual Entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          Stack(
            children: [
              MobileScanner(onDetect: _onQRDetected),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          // Manual entry tab
          Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Responsive.formMaxWidth),
                child: ListView(
                  padding: Responsive.pagePadding(context),
                  children: [
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Issuer (e.g. Google)',
                      controller: _issuerCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Account Name / Email',
                      controller: _accountCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Secret Key',
                      controller: _secretCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Add Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
