import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../../../core/currency_formatter.dart';
import '../../../data/database.dart';
import '../../../data/models/document_model.dart';
import '../providers/document_providers.dart';

/// Bottom sheet for recording a full or partial payment.
class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({super.key, required this.doc});
  final DocumentModel doc;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String _method = 'M-Pesa';
  bool _saving = false;
  DateTime _date = DateTime.now();

  static const _methods = ['M-Pesa', 'Cash', 'Bank Transfer', 'PayPal', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill with full balance
    _amountCtrl.text = CurrencyFormatter.formatMinorToDisplay(
        widget.doc.balanceDue, widget.doc.currencyCode);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = widget.doc.currencyCode;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text('Record Payment', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Text(
            'Balance due: ${CurrencyFormatter.format(widget.doc.balanceDue, currency)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.md),

          // Amount field
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '$currency ',
            ),
            autofocus: true,
          ),
          const SizedBox(height: Spacing.sm),

          // Method dropdown
          DropdownButtonFormField<String>(
            value: _method,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: Spacing.sm),

          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Payment date',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text('${_date.day}/${_date.month}/${_date.year}'),
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Reference
          TextFormField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(
              labelText: 'Reference (optional)',
              hintText: 'Transaction ID, cheque number, etc.',
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Record Payment'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amountMinor = CurrencyFormatter.parseToMinor(
        _amountCtrl.text, widget.doc.currencyCode);
    if (amountMinor <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await ref.read(documentRepositoryProvider).addPayment(
            PaymentsCompanion(
              documentId: Value(widget.doc.id),
              amountMinor: Value(amountMinor),
              paymentDate: Value(_date.millisecondsSinceEpoch ~/ 1000),
              method: Value(_method),
              reference: Value(_referenceCtrl.text.trim()),
              notes: const Value(''),
              createdAt: Value(now),
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
