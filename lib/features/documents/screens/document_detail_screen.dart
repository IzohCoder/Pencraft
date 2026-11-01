import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/design/tokens.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/document_numbering.dart';
import '../../../data/database.dart';
import '../../../data/models/document_model.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../providers/document_providers.dart';
import '../widgets/paid_stamp_overlay.dart';
import '../widgets/record_payment_sheet.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _showStamp = false;

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(documentDetailProvider(widget.id));

    return docAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (doc) {
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Invoice not found')),
          );
        }
        final status = doc.derivedStatus;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(doc.number),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => context.push('/documents/${doc.id}/edit'),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _handleAction(context, v, doc),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuItem(value: 'share_pdf', child: Text('Share PDF')),
                  const PopupMenuItem(value: 'whatsapp', child: Text('Send via WhatsApp')),
                  if (doc.type == 'estimate')
                    const PopupMenuItem(value: 'convert', child: Text('Convert to Invoice')),
                  const PopupMenuItem(value: 'void', child: Text('Void')),
                  const PopupMenuItem(value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Status + totals summary card
                  SliverToBoxAdapter(
                    child: _SummaryCard(doc: doc, onRecordPayment: () => _recordPayment(context, doc)),
                  ),

                  // Line items
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.sm),
                      child: Text('Line items',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _LineItemRow(li: doc.lineItems[i], currency: doc.currencyCode),
                      childCount: doc.lineItems.length,
                    ),
                  ),

                  // Totals breakdown
                  SliverToBoxAdapter(child: _TotalsBreakdown(doc: doc)),

                  // Payment history
                  if (doc.payments.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.sm),
                        child: Text('Payment history',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PaymentRow(payment: doc.payments[i], currency: doc.currencyCode),
                        childCount: doc.payments.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // Paid stamp overlay
              if (_showStamp) const PaidStampOverlay(),
            ],
          ),

          // Record payment FAB (only if not paid/void)
          floatingActionButton: (status != 'paid' && status != 'void')
              ? FloatingActionButton.extended(
                  onPressed: () => _recordPayment(context, doc),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record payment'),
                )
              : null,
        );
      },
    );
  }

  void _handleAction(BuildContext context, String action, dynamic doc) {
    switch (action) {
      case 'delete':
        _confirmDelete(context, doc);
        break;
      case 'whatsapp':
        _shareWhatsApp(doc as DocumentModel);
        break;
      case 'share_pdf':
        context.push('/documents/${doc.id}/pdf');
        break;
      case 'duplicate':
        _duplicateDocument(context, doc as DocumentModel);
        break;
      case 'convert':
        _convertToInvoice(context, doc as DocumentModel);
        break;
      case 'void':
        _voidDocument(context, doc as DocumentModel);
        break;
    }
  }

  Future<void> _recordPayment(BuildContext context, dynamic doc) async {
    final dm = doc as DocumentModel;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentSheet(doc: dm),
    );
    if (result == true && mounted) {
      // Refresh document
      ref.invalidate(documentDetailProvider(widget.id));
      // If now fully paid, trigger stamp
      final updated = await ref.read(documentRepositoryProvider).getDocument(widget.id);
      if (updated != null && updated.derivedStatus == 'paid') {
        await _triggerPaidStamp();
      }
    }
  }

  Future<void> _triggerPaidStamp() async {
    HapticFeedback.heavyImpact();
    setState(() => _showStamp = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showStamp = false);
  }

  void _shareWhatsApp(DocumentModel doc) {
    WhatsAppService.instance.shareDocument(
      doc: doc,
      business: const BusinessProfileData(name: 'My Business'),
      templateId: doc.templateId,
      showFooter: false,
    );
  }

  Future<void> _duplicateDocument(BuildContext context, DocumentModel doc) async {
    final repo = ref.read(documentRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final seq = await repo.nextSequence(doc.type);
    final prefix = doc.type == 'estimate' ? 'EST' : 'INV';
    final year = DateTime.now().year;
    final newNumber = '$prefix-$year-${seq.toString().padLeft(3, '0')}';

    final newId = await repo.createDocument(DocumentsCompanion.insert(
      type: doc.type,
      number: newNumber,
      clientId: Value(doc.clientId),
      currencyCode: Value(doc.currencyCode),
      taxMode: Value(doc.taxMode),
      discountMode: Value(doc.discountMode),
      discountValue: Value(doc.discountValue),
      globalTaxRateBps: Value(doc.globalTaxRateBps),
      depositMinor: Value(doc.depositMinor),
      statusOverride: const Value('draft'),
      issueDate: now,
      dueDate: Value(doc.dueDate),
      notes: Value(doc.notes),
      terms: Value(doc.terms),
      templateId: Value(doc.templateId),
      accentColour: Value(doc.accentColour),
      createdAt: now,
      updatedAt: now,
    ));
    await repo.upsertLineItems(newId, doc.lineItems.map((li) => LineItemsCompanion.insert(
      documentId: newId,
      description: Value(li.description),
      unit: Value(li.unit),
      quantityX100: Value(li.quantityX100),
      unitPriceMinor: Value(li.unitPriceMinor),
      sortOrder: Value(li.sortOrder),
      createdAt: now,
    )).toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicated as $newNumber')),
      );
      context.push('/documents/$newId');
    }
  }

  Future<void> _convertToInvoice(BuildContext context, DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convert to Invoice?'),
        content: Text('${doc.number} will become an invoice. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Convert')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final repo = ref.read(documentRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final seq = await repo.nextSequence('invoice');
    final year = DateTime.now().year;
    final newNumber = 'INV-$year-${seq.toString().padLeft(3, '0')}';
    await repo.updateDocument(DocumentsCompanion(
      id: Value(doc.id),
      type: const Value('invoice'),
      number: Value(newNumber),
      updatedAt: Value(now),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Converted to invoice $newNumber')),
      );
    }
  }

  Future<void> _voidDocument(BuildContext context, DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Void document?'),
        content: const Text('This marks the document as void. No further payments can be recorded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Void', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await ref.read(documentRepositoryProvider).updateDocument(DocumentsCompanion(
      id: Value(doc.id),
      statusOverride: const Value('void'),
      updatedAt: Value(now),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document voided')),
      );
    }
  }

  void _confirmDelete(BuildContext context, dynamic doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('${doc.number} will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(documentRepositoryProvider).deleteDocument(doc.id);
              if (mounted) context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.doc, required this.onRecordPayment});

  final dynamic doc;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = doc.balanceDue as int;
    final total = doc.totalMinor as int;
    final status = doc.derivedStatus as String;

    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: Radii.cardAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      CurrencyFormatter.format(total, doc.currencyCode as String),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (status == 'paid')
                const Icon(Icons.check_circle, color: Color(0xFF1E7D45), size: 32),
            ],
          ),
          if (balance > 0 && balance < total) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Balance due: ${CurrencyFormatter.format(balance, doc.currencyCode as String)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (doc.clientName != null) ...[
            const SizedBox(height: Spacing.md),
            Text(doc.clientName as String, style: theme.textTheme.titleSmall),
          ],
          const SizedBox(height: Spacing.sm),
          Text(
            DocumentNumbering.dueDateLabel(doc.dueDate as int?),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.li, required this.currency});

  final dynamic li;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = (li.quantityX100 as int) / 100;
    final qtyStr = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(li.description as String, style: theme.textTheme.bodyMedium),
                Text('$qtyStr × ${CurrencyFormatter.format(li.unitPriceMinor as int, currency)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(li.subtotalMinor as int, currency),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsBreakdown extends StatelessWidget {
  const _TotalsBreakdown({required this.doc});

  final dynamic doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = doc.currencyCode as String;

    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          const Divider(),
          _TotalsRow('Subtotal', doc.subtotalMinor as int, currency, theme),
          _TotalsRow('Tax (${(doc.globalTaxRateBps as int) / 100}%)',
              doc.taxMinor as int, currency, theme),
          if ((doc.discountMinor as int) > 0)
            _TotalsRow('Discount', -(doc.discountMinor as int), currency, theme,
                color: const Color(0xFF1E7D45)),
          const Divider(),
          _TotalsRow('Total', doc.totalMinor as int, currency, theme,
              bold: true),
          if ((doc.totalPaidMinor as int) > 0)
            _TotalsRow('Paid', -(doc.totalPaidMinor as int), currency, theme,
                color: const Color(0xFF1E7D45)),
          if ((doc.balanceDue as int) > 0)
            _TotalsRow('Balance due', doc.balanceDue as int, currency, theme,
                bold: true, color: theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _TotalsRow(String label, int amount, String currency, ThemeData theme,
      {bool bold = false, Color? color}) {
    final style = (bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
        ?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)),
          Text(
            amount < 0
                ? '−${CurrencyFormatter.format(-amount, currency)}'
                : CurrencyFormatter.format(amount, currency),
            style: style,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.currency});

  final dynamic payment;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(
        (payment.paymentDate as int) * 1000);
    return ListTile(
      leading: const Icon(Icons.check_circle_outline, color: Color(0xFF1E7D45)),
      title: Text(CurrencyFormatter.format(payment.amountMinor as int, currency),
          style: theme.textTheme.bodyMedium),
      subtitle: Text(
          '${payment.method} · ${date.day}/${date.month}/${date.year}',
          style: theme.textTheme.bodySmall),
      dense: true,
    );
  }
}
