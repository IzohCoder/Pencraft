import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/app_colors.dart';

/// Payment instructions editor screen.
/// Manages the M-Pesa Paybill/Till, bank account and other payment details
/// that appear beautifully on every invoice.
class PaymentInstructionsScreen extends ConsumerStatefulWidget {
  const PaymentInstructionsScreen({super.key, this.initialValue = ''});

  final String initialValue;

  @override
  ConsumerState<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentInstructionsScreenState
    extends ConsumerState<PaymentInstructionsScreen> {
  final _formKey = GlobalKey<FormState>();

  // M-Pesa fields
  final _mpesaTypeCtrl = TextEditingController();
  final _mpesaNumberCtrl = TextEditingController();
  final _mpesaNameCtrl = TextEditingController();

  // Bank fields
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _bankBranchCtrl = TextEditingController();

  // Other
  final _paypalCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  bool _mpesaEnabled = false;
  bool _bankEnabled = false;
  bool _paypalEnabled = false;
  bool _otherEnabled = false;
  String _mpesaType = 'Paybill'; // 'Paybill' | 'Till'

  @override
  void initState() {
    super.initState();
    // Parse initialValue (newline-separated plain text) if present
    // For MVP, we pre-populate from any existing instructions string
    if (widget.initialValue.isNotEmpty) {
      // Simple detection: if "Paybill" or "Till" in string, enable M-Pesa
      final lines = widget.initialValue.split('\n');
      for (final line in lines) {
        if (line.contains('Paybill')) {
          _mpesaEnabled = true;
          _mpesaType = 'Paybill';
        } else if (line.contains('Till')) {
          _mpesaEnabled = true;
          _mpesaType = 'Till';
        } else if (line.contains('Bank:') || line.contains('Account:')) {
          _bankEnabled = true;
        } else if (line.contains('PayPal')) {
          _paypalEnabled = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _mpesaTypeCtrl.dispose();
    _mpesaNumberCtrl.dispose();
    _mpesaNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankBranchCtrl.dispose();
    _paypalCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  String _buildInstructions() {
    final buf = StringBuffer();

    if (_mpesaEnabled && _mpesaNumberCtrl.text.isNotEmpty) {
      buf.writeln('M-Pesa $_mpesaType: ${_mpesaNumberCtrl.text}');
      if (_mpesaNameCtrl.text.isNotEmpty) {
        buf.writeln('Account name: ${_mpesaNameCtrl.text}');
      }
    }

    if (_bankEnabled && _bankAccountCtrl.text.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln();
      if (_bankNameCtrl.text.isNotEmpty) buf.writeln('Bank: ${_bankNameCtrl.text}');
      buf.writeln('Account: ${_bankAccountCtrl.text}');
      if (_bankBranchCtrl.text.isNotEmpty) buf.writeln('Branch: ${_bankBranchCtrl.text}');
    }

    if (_paypalEnabled && _paypalCtrl.text.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln();
      buf.writeln('PayPal: ${_paypalCtrl.text}');
    }

    if (_otherEnabled && _otherCtrl.text.isNotEmpty) {
      if (buf.isNotEmpty) buf.writeln();
      buf.write(_otherCtrl.text);
    }

    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Instructions'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Text(
              'These details appear on every invoice, making it easy for clients to pay you.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.lg),

            // ── M-Pesa Section ──────────────────────────────────────
            _SectionToggle(
              icon: Icons.phone_android_outlined,
              title: 'M-Pesa',
              subtitle: 'Paybill or Till number',
              accentColor: const Color(0xFF4CAF50), // M-Pesa green
              enabled: _mpesaEnabled,
              onToggle: (v) => setState(() => _mpesaEnabled = v),
            ),
            if (_mpesaEnabled) ...[
              const SizedBox(height: Spacing.sm),
              // Paybill / Till toggle
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Paybill', label: Text('Paybill')),
                  ButtonSegment(value: 'Till', label: Text('Till Number')),
                ],
                selected: {_mpesaType},
                onSelectionChanged: (s) =>
                    setState(() => _mpesaType = s.first),
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _mpesaNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _mpesaType == 'Paybill'
                      ? 'Paybill Number'
                      : 'Till Number',
                  hintText: _mpesaType == 'Paybill' ? '123456' : '987654',
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _mpesaNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Name (optional)',
                  hintText: 'Business name shown on M-Pesa',
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],

            // ── Bank Section ─────────────────────────────────────────
            _SectionToggle(
              icon: Icons.account_balance_outlined,
              title: 'Bank Account',
              subtitle: 'Local bank transfer details',
              accentColor: AppColorsLight.accent,
              enabled: _bankEnabled,
              onToggle: (v) => setState(() => _bankEnabled = v),
            ),
            if (_bankEnabled) ...[
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _bankNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g. Equity Bank',
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _bankAccountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _bankBranchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Branch (optional)',
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],

            // ── PayPal Section ───────────────────────────────────────
            _SectionToggle(
              icon: Icons.language_outlined,
              title: 'PayPal / Online Link',
              subtitle: 'PayPal email or payment link',
              accentColor: const Color(0xFF003087),
              enabled: _paypalEnabled,
              onToggle: (v) => setState(() => _paypalEnabled = v),
            ),
            if (_paypalEnabled) ...[
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _paypalCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'PayPal email or link',
                  hintText: 'payments@example.com',
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],

            // ── Other Section ────────────────────────────────────────
            _SectionToggle(
              icon: Icons.notes_outlined,
              title: 'Other Instructions',
              subtitle: 'Cash, cheque, or custom text',
              accentColor: theme.colorScheme.secondary,
              enabled: _otherEnabled,
              onToggle: (v) => setState(() => _otherEnabled = v),
            ),
            if (_otherEnabled) ...[
              const SizedBox(height: Spacing.sm),
              TextFormField(
                controller: _otherCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Custom payment instructions',
                  hintText: 'e.g. Cash payment accepted on delivery',
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }

  void _save() {
    final result = _buildInstructions();
    Navigator.of(context).pop(result);
  }
}

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.enabled,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
        borderRadius: Radii.cardBR,
        border: Border.all(
          color: enabled ? accentColor.withValues(alpha: 0.4) : theme.colorScheme.outlineVariant,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: enabled ? accentColor : theme.colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        value: enabled,
        onChanged: onToggle,
        activeThumbColor: accentColor,
      ),
    );
  }
}
