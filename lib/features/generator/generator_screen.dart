import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/clipboard_util.dart';
import '../../core/utils/responsive.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Strong password options
  int _length = 16;
  bool _useSymbols = true;
  bool _useNumbers = true;
  bool _useUpper = true;
  bool _useLower = true;
  String _generated = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _generateStrong();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Easy-to-type generator ─────────────────────────────────
  static const _words = [
    'Tiger',
    'Moon',
    'River',
    'Stone',
    'Cloud',
    'Flame',
    'Ocean',
    'Storm',
    'Eagle',
    'Blade',
    'Frost',
    'Solar',
    'Comet',
    'Delta',
    'Pixel',
    'Amber',
    'Swift',
    'Nexus',
  ];
  static const _symbols = ['@', '#', '!', '\$', '%', '&', '*'];

  String _generateEasy() {
    final rng = Random.secure();
    final w1 = _words[rng.nextInt(_words.length)];
    final w2 = _words[rng.nextInt(_words.length)];
    final sym = _symbols[rng.nextInt(_symbols.length)];
    final num = 10 + rng.nextInt(90);
    return '$w1$sym$w2$num';
  }

  // ── Strong password generator ──────────────────────────────
  void _generateStrong() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    var chars = '';
    if (_useUpper) chars += upper;
    if (_useLower) chars += lower;
    if (_useNumbers) chars += numbers;
    if (_useSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() => _generated = 'Select at least one option');
      return;
    }

    final rng = Random.secure();
    setState(() {
      _generated = List.generate(
        _length,
        (_) => chars[rng.nextInt(chars.length)],
      ).join();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // const SizedBox(height: 12),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primary,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Easy to Type'),
              Tab(text: 'Strong'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _EasyTab(onGenerate: _generateEasy),
              _StrongTab(
                generated: _generated,
                length: _length,
                useSymbols: _useSymbols,
                useNumbers: _useNumbers,
                useUpper: _useUpper,
                useLower: _useLower,
                onLengthChanged: (v) => setState(() => _length = v.toInt()),
                onSymbolsChanged: (v) {
                  setState(() => _useSymbols = v);
                  _generateStrong();
                },
                onNumbersChanged: (v) {
                  setState(() => _useNumbers = v);
                  _generateStrong();
                },
                onUpperChanged: (v) {
                  setState(() => _useUpper = v);
                  _generateStrong();
                },
                onLowerChanged: (v) {
                  setState(() => _useLower = v);
                  _generateStrong();
                },
                onGenerate: _generateStrong,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Easy Tab ──────────────────────────────────────────────────

class _EasyTab extends StatefulWidget {
  final String Function() onGenerate;
  const _EasyTab({required this.onGenerate});

  @override
  State<_EasyTab> createState() => _EasyTabState();
}

class _EasyTabState extends State<_EasyTab> {
  String _password = '';

  @override
  void initState() {
    super.initState();
    _password = widget.onGenerate();
  }

  @override
  Widget build(BuildContext context) {
    final hp = Responsive.horizontalPadding(context);
    final bottomPad = Responsive.isWide(context) ? Responsive.sp6 : 120.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hp, Responsive.sp5, hp, bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.cardMaxWidth),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'Memorable Passwords',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Easy to remember, hard to guess',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 32),
              _PasswordDisplay(password: _password),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          setState(() => _password = widget.onGenerate()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Generate'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ClipboardUtil.copyAndAutoClear(_password);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('How it works',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We combine two random words with a special symbol and a number to create a password that is easy for humans to type but difficult for computers to crack.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ], // Column children
          ), // Column
        ), // ConstrainedBox
      ), // Center
    );
  }
}

// ── Strong Tab ────────────────────────────────────────────────

class _StrongTab extends StatelessWidget {
  final String generated;
  final int length;
  final bool useSymbols, useNumbers, useUpper, useLower;
  final ValueChanged<double> onLengthChanged;
  final ValueChanged<bool> onSymbolsChanged;
  final ValueChanged<bool> onNumbersChanged;
  final ValueChanged<bool> onUpperChanged;
  final ValueChanged<bool> onLowerChanged;
  final VoidCallback onGenerate;

  const _StrongTab({
    required this.generated,
    required this.length,
    required this.useSymbols,
    required this.useNumbers,
    required this.useUpper,
    required this.useLower,
    required this.onLengthChanged,
    required this.onSymbolsChanged,
    required this.onNumbersChanged,
    required this.onUpperChanged,
    required this.onLowerChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final hp = Responsive.horizontalPadding(context);
    final bottomPad = Responsive.isWide(context) ? Responsive.sp6 : 120.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.cardMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(hp, Responsive.sp5, hp, bottomPad),
          children: [
            _PasswordDisplay(password: generated),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Length',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$length',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                value: length.toDouble(),
                min: 8,
                max: 32,
                divisions: 24,
                onChanged: onLengthChanged,
                onChangeEnd: (_) => onGenerate(),
              ),
            ),
            const SizedBox(height: 12),
            _ToggleTile(
                label: 'Uppercase',
                subtitle: 'ABC...',
                value: useUpper,
                onChanged: onUpperChanged),
            _ToggleTile(
                label: 'Lowercase',
                subtitle: 'abc...',
                value: useLower,
                onChanged: onLowerChanged),
            _ToggleTile(
                label: 'Numbers',
                subtitle: '123...',
                value: useNumbers,
                onChanged: onNumbersChanged),
            _ToggleTile(
                label: 'Symbols',
                subtitle: '!@#...',
                value: useSymbols,
                onChanged: onSymbolsChanged),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Generate'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ClipboardUtil.copyAndAutoClear(generated);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ], // Row children
            ), // Row
          ], // ListView children
        ), // ListView
      ), // ConstrainedBox
    ); // Center
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _PasswordDisplay extends StatelessWidget {
  final String password;
  const _PasswordDisplay({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: SelectableText(
          password,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
