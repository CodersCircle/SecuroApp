import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/clipboard_util.dart';
import '../core/utils/responsive.dart';
import '../database/app_database.dart';
import '../services/totp_service.dart';

class TotpCard extends StatefulWidget {
  final TotpAccount account;
  final VoidCallback onDelete;

  const TotpCard({super.key, required this.account, required this.onDelete});

  @override
  State<TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends State<TotpCard> {
  late Timer _timer;
  late String _code;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _code = TotpService.instance.generateCode(
        widget.account.secretKey,
        digits: widget.account.digits,
        period: widget.account.period,
      );
      _remaining =
          TotpService.instance.secondsRemaining(period: widget.account.period);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.account.period;
    final isUrgent = _remaining <= 5;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(widget.account.iconEmoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.account.issuer,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                      Text(widget.account.accountName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  )),
                      const SizedBox(height: 8),
                      Text(
                        TotpService.instance.formatCode(_code),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? AppTheme.error : AppTheme.primary,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Icon in place of circular countdown
                IconButton(
                  onPressed: () {
                    ClipboardUtil.copyAndAutoClear(_code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('OTP copied!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.fromLTRB(
                            24, 0, 24, Responsive.isWide(context) ? 24 : 100),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_all_rounded, size: 22),
                ),
              ],
            ),
          ),
          // Horizontal progress line at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                isUrgent
                    ? AppTheme.error
                    : AppTheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
