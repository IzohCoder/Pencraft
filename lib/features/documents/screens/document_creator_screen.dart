import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/design/tokens.dart';
import '../../../core/invoice_math.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/document_numbering.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/database.dart';
import '../../../data/providers/database_provider.dart';
import '../../../data/models/document_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/item_model.dart';
import '../providers/document_providers.dart';
import '../../../features/clients/providers/client_providers.dart';
import '../../../features/items/providers/item_providers.dart';
import '../../../services/settings_service.dart';
import '../widgets/invoice_preview_card.dart';

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class DocumentCreatorScreen extends ConsumerStatefulWidget {
  const DocumentCreatorScreen({
    super.key,
    this.documentId,
    required this.documentType,
  });

  final int? documentId;
  final String documentType;

  @override
  ConsumerState<DocumentCreatorScreen> createState() =>
      _DocumentCreatorScreenState();
}

class _DocumentCreatorScreenState
    extends ConsumerState<DocumentCreatorScreen> {
  // Form state
  ClientModel? _selectedClient;
  String _currencyCode = 'KES';
  int _taxMode = 0; // 0=exclusive 1=inclusive
  int _discountMode = 0; // 0=percent 1=flat
  int _discountValue = 0; // bps or minor units
  int _globalTaxRateBps = 1600; // 16%
  final List<_LineItemDraft> _lineItems = [];
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _termsCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  int? _dueDate; // epoch seconds
  bool _saving = false;

  // Computed totals (updated on every change)
  int get _subtotal => InvoiceMath.subtotal(
      _lineItems.map((li) => InvoiceMath.lineSubtotal(
            quantityX100: li.quantityX100,
            unitPriceMinor: li.unitPriceMinor,
          )).toList());

  int get _taxAmount => _taxMode == 1
      ? InvoiceMath.taxInclusive(
          priceIncludingTaxMinor: _subtotal,
          taxRateBps: _globalTaxRateBps)
      : InvoiceMath.taxExclusive(
          subtotalMinor: _subtotal, taxRateBps: _globalTaxRateBps);

  int get _discountAmount => InvoiceMath.discountAmount(
        subtotalMinor: _subtotal,
        discountMode: _discountMode,
        discountValue: _discountValue,
      );

  int get _total => InvoiceMath.total(
        subtotalMinor: _subtotal,
        taxMinor: _taxAmount,
        discountMinor: _discountAmount,
      );

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocument());
    } else {
      // Start with one empty line item
      _lineItems.add(_LineItemDraft());
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    _discountCtrl.dispose();
    for (final li in _lineItems) {
      li.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = await repo.getDocument(widget.documentId!);
    if (doc == null || !mounted) return;

    setState(() {
      _currencyCode = doc.currencyCode;
      _taxMode = doc.taxMode;
      _discountMode = doc.discountMode;
      _discountValue = doc.discountValue;
      _globalTaxRateBps = doc.globalTaxRateBps;
      _dueDate = doc.dueDate;
      _notesCtrl.text = doc.notes;
      _termsCtrl.text = doc.terms;

      // Load line items
      _lineItems.clear();
      for (final li in doc.lineItems) {
        _lineItems.add(_LineItemDraft.fromModel(li));
      }
      if (_lineItems.isEmpty) _lineItems.add(_LineItemDraft());

      // Discount display
      if (_discountValue > 0) {
        _discountCtrl.text = _discountMode == 0
            ? (_discountValue / 100).toStringAsFixed(0) // bps → percent
            : CurrencyFormatter.formatMinorToDisplay(_discountValue, _currencyCode);
      }
    });

    // Load client
    if (doc.clientId != null) {
      final client = await ref.read(clientRepositoryProvider).getClient(doc.clientId!);
      if (mounted) setState(() => _selectedClient = client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.documentId != null;
    final isEstimate = widget.documentType == 'estimate';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? 'Edit ${isEstimate ? 'estimate' : 'invoice'}'
            : 'New ${isEstimate ? 'estimate' : 'invoice'}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Client selector
          SliverToBoxAdapter(child: _ClientSection(
            selected: _selectedClient,
            onSelect: (c) => setState(() => _selectedClient = c),
          )),

          // Line items header
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'ITEMS'),
          ),

          // Line item list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _LineItemCard(
                key: ValueKey(_lineItems[i].id),
                draft: _lineItems[i],
                currencyCode: _currencyCode,
                onChanged: () => setState(() {}),
                onDelete: _lineItems.length > 1
                    ? () => setState(() => _lineItems.removeAt(i))
                    : null,
                onPickItem: () => _pickItem(i),
              ),
              childCount: _lineItems.length,
            ),
          ),

          // Add item button
          SliverToBoxAdapter(
            child: TextButton.icon(
              onPressed: () => setState(() => _lineItems.add(_LineItemDraft())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add line item'),
            ),
          ),

          // Live paper preview (totals)
          SliverToBoxAdapter(
            child: _TotalsPreview(
              subtotal: _subtotal,
              taxAmount: _taxAmount,
              discountAmount: _discountAmount,
              total: _total,
              currencyCode: _currencyCode,
              taxRateBps: _globalTaxRateBps,
              taxMode: _taxMode,
              discountMode: _discountMode,
              discountCtrl: _discountCtrl,
              onTaxModeChanged: (v) => setState(() => _taxMode = v ? 1 : 0),
              onDiscountChanged: _onDiscountChanged,
            ),
          ),

          // Paper invoice preview card — updates live, tap to open full preview
          SliverToBoxAdapter(
            child: InvoicePreviewCard(
              doc: _buildPreviewDoc(),
              businessName: 'My Business', // TODO(m3): load from profile
              onTap: () {
                // If document is saved, open PDF preview; otherwise show totals preview
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save the document first to view full PDF preview')),
                );
              },
            ),
          ),

          // Notes & terms
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.md),
              child: Column(
                children: [
                  AppTextField(
                    controller: _notesCtrl,
                    label: 'Notes',
                    hint: 'Thank you for your business!',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppTextField(
                    controller: _termsCtrl,
                    label: 'Terms',
                    hint: 'Payment due within 30 days',
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),

          // Due date
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_dueDate != null
                  ? 'Due: ${DocumentNumbering.dueDateLabel(_dueDate)}'
                  : 'Set due date'),
              onTap: _pickDueDate,
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _onDiscountChanged(String val) {
    setState(() {
      final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0;
      if (_discountMode == 0) {
        // percent → bps
        _discountValue = (parsed * 100).round();
      } else {
        // flat amount in display units → minor
        _discountValue = (parsed * CurrencyFormatter.minorPerUnit(_currencyCode)).round();
      }
    });
  }

  DocumentModel _buildPreviewDoc() {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return DocumentModel(
      id: 0,
      type: widget.documentType,
      number: 'PREVIEW',
      clientId: _selectedClient?.id,
      clientName: _selectedClient?.name,
      currencyCode: _currencyCode,
      taxMode: _taxMode,
      discountMode: _discountMode,
      discountValue: _discountValue,
      globalTaxRateBps: _globalTaxRateBps,
      depositMinor: 0,
      statusOverride: 'draft',
      issueDate: nowEpoch,
      dueDate: _dueDate,
      notes: _notesCtrl.text,
      terms: _termsCtrl.text,
      templateId: 1,
      accentColour: null,
      createdAt: nowEpoch,
      updatedAt: nowEpoch,
      lineItems: _lineItems.map((li) => LineItemModel(
        id: 0,
        documentId: 0,
        description: li.descriptionCtrl.text,
        unit: li.unitCtrl.text,
        quantityX100: li.quantityX100,
        unitPriceMinor: li.unitPriceMinor,
        sortOrder: 0,
      )).toList(),
      payments: const [],
    );
  }

  Future<void> _pickItem(int index) async {
    final items = await ref.read(itemListProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<ItemModel>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      builder: (_) => _ItemPickerSheet(items: items),
    );
    if (picked != null && mounted) {
      setState(() {
        _lineItems[index].descriptionCtrl.text = picked.name;
        _lineItems[index].unitCtrl.text = picked.unit;
        _lineItems[index].priceCtrl.text =
            CurrencyFormatter.formatMinorToDisplay(picked.unitPriceMinor, _currencyCode);
        _lineItems[index].unitPriceMinor = picked.unitPriceMinor;
        _lineItems[index].itemId = picked.id;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate != null
          ? DateTime.fromMillisecondsSinceEpoch(_dueDate! * 1000)
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked.millisecondsSinceEpoch ~/ 1000);
    }
  }

  Future<void> _save() async {
    if (_lineItems.isEmpty || _lineItems.every((li) => li.descriptionCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(documentRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final lineCompanions = _lineItems
          .where((li) => li.descriptionCtrl.text.trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((e) => LineItemsCompanion.insert(
                documentId: 0, // will be set below
                description: Value(e.value.descriptionCtrl.text.trim()),
                unit: Value(e.value.unitCtrl.text.trim().isEmpty ? 'item' : e.value.unitCtrl.text.trim()),
                quantityX100: Value(e.value.quantityX100),
                unitPriceMinor: Value(e.value.unitPriceMinor),
                taxRateBps: Value(e.value.taxRateBps),
                sortOrder: Value(e.key),
                createdAt: now,
              ))
          .toList();

      if (widget.documentId == null) {
        // Create new
        final sequence = await repo.nextSequence(widget.documentType);
        final number = DocumentNumbering.generate(
          prefix: widget.documentType == 'estimate' ? 'EST' : 'INV',
          year: DateTime.now().year,
          sequence: sequence,
        );

        final docId = await repo.createDocument(DocumentsCompanion.insert(
          type: widget.documentType,
          number: number,
          clientId: Value(_selectedClient?.id),
          currencyCode: Value(_currencyCode),
          taxMode: Value(_taxMode),
          discountMode: Value(_discountMode),
          discountValue: Value(_discountValue),
          globalTaxRateBps: Value(_globalTaxRateBps),
          statusOverride: const Value('draft'),
          issueDate: now,
          dueDate: Value(_dueDate),
          notes: Value(_notesCtrl.text.trim()),
          terms: Value(_termsCtrl.text.trim()),
          createdAt: now,
          updatedAt: now,
        ));

        // Insert line items with real docId
        for (final li in lineCompanions) {
          await ref.read(databaseProvider).into(
              ref.read(databaseProvider).lineItems).insert(
                li.copyWith(documentId: Value(docId)));
        }

        // Increment free tier counter
        await ref.read(settingsProvider.notifier).incrementDocsThisMonth();

        if (mounted) {
          context.pop();
          context.push('/documents/$docId');
        }
      } else {
        // Update existing
        await repo.updateDocument(DocumentsCompanion(
          id: Value(widget.documentId!),
          clientId: Value(_selectedClient?.id),
          currencyCode: Value(_currencyCode),
          taxMode: Value(_taxMode),
          discountMode: Value(_discountMode),
          discountValue: Value(_discountValue),
          globalTaxRateBps: Value(_globalTaxRateBps),
          dueDate: Value(_dueDate),
          notes: Value(_notesCtrl.text.trim()),
          terms: Value(_termsCtrl.text.trim()),
          updatedAt: Value(now),
        ));

        await repo.upsertLineItems(
          widget.documentId!,
          lineCompanions
              .map((li) => li.copyWith(documentId: Value(widget.documentId!)))
              .toList(),
        );

        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Client selection section
// ---------------------------------------------------------------------------

class _ClientSection extends ConsumerWidget {
  const _ClientSection({required this.selected, required this.onSelect});

  final ClientModel? selected;
  final ValueChanged<ClientModel?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(clientListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
      child: InkWell(
        onTap: () async {
          final clients = clientsAsync.valueOrNull ?? [];
          final picked = await showModalBottomSheet<ClientModel>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
            builder: (_) => _ClientPickerSheet(clients: clients),
          );
          if (picked != null) onSelect(picked);
        },
        borderRadius: Radii.cardAll,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            borderRadius: Radii.cardAll,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            color: theme.cardColor,
          ),
          child: Row(
            children: [
              Icon(
                selected != null ? Icons.person : Icons.person_add_outlined,
                color: selected != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  selected?.name ?? 'Select client',
                  style: selected != null
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line item draft (mutable)
// ---------------------------------------------------------------------------

class _LineItemDraft {
  _LineItemDraft()
      : id = DateTime.now().microsecondsSinceEpoch,
        descriptionCtrl = TextEditingController(),
        qtyCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(),
        unitCtrl = TextEditingController(text: 'item');

  _LineItemDraft.fromModel(LineItemModel m)
      : id = m.id,
        itemId = m.itemId,
        descriptionCtrl = TextEditingController(text: m.description),
        qtyCtrl = TextEditingController(
            text: (m.quantityX100 / 100).toString()),
        priceCtrl = TextEditingController(),
        unitCtrl = TextEditingController(text: m.unit),
        quantityX100 = m.quantityX100,
        unitPriceMinor = m.unitPriceMinor,
        taxRateBps = m.taxRateBps;

  final int id;
  int? itemId;
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController unitCtrl;
  int quantityX100 = 100; // 1.00
  int unitPriceMinor = 0;
  int? taxRateBps;

  void dispose() {
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    unitCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// Line item card
// ---------------------------------------------------------------------------

class _LineItemCard extends StatefulWidget {
  const _LineItemCard({
    super.key,
    required this.draft,
    required this.currencyCode,
    required this.onChanged,
    this.onDelete,
    required this.onPickItem,
  });

  final _LineItemDraft draft;
  final String currencyCode;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;
  final VoidCallback onPickItem;

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  @override
  void initState() {
    super.initState();
    // Populate price field if price is known
    if (widget.draft.unitPriceMinor > 0) {
      widget.draft.priceCtrl.text = CurrencyFormatter.formatMinorToDisplay(
          widget.draft.unitPriceMinor, widget.currencyCode);
    }
  }

  void _onPriceChanged(String val) {
    widget.draft.unitPriceMinor =
        CurrencyFormatter.parseToMinor(val, widget.currencyCode);
    widget.onChanged();
  }

  void _onQtyChanged(String val) {
    final qty = double.tryParse(val) ?? 1.0;
    widget.draft.quantityX100 = (qty * 100).round();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineTotal = InvoiceMath.lineSubtotal(
      quantityX100: widget.draft.quantityX100,
      unitPriceMinor: widget.draft.unitPriceMinor,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        borderRadius: Radii.cardAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.draft.descriptionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  style: theme.textTheme.bodyMedium,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.close, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              // Qty
              SizedBox(
                width: 56,
                child: TextField(
                  controller: widget.draft.qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                  style: theme.textTheme.bodySmall,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: _onQtyChanged,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Unit
              SizedBox(
                width: 60,
                child: TextField(
                  controller: widget.draft.unitCtrl,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                  style: theme.textTheme.bodySmall,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Rate
              Expanded(
                child: TextField(
                  controller: widget.draft.priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rate',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                  style: theme.textTheme.bodySmall,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  onChanged: _onPriceChanged,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Line total
              Text(
                CurrencyFormatter.format(lineTotal, widget.currencyCode),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals preview (live paper preview)
// ---------------------------------------------------------------------------

class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.currencyCode,
    required this.taxRateBps,
    required this.taxMode,
    required this.discountMode,
    required this.discountCtrl,
    required this.onTaxModeChanged,
    required this.onDiscountChanged,
  });

  final int subtotal;
  final int taxAmount;
  final int discountAmount;
  final int total;
  final String currencyCode;
  final int taxRateBps;
  final int taxMode;
  final int discountMode;
  final TextEditingController discountCtrl;
  final ValueChanged<bool> onTaxModeChanged;
  final ValueChanged<String> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxLabel =
        'VAT ${(taxRateBps / 100).toStringAsFixed(0)}% (${taxMode == 1 ? "incl." : "excl."})';

    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: Radii.documentAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _PreviewRow('Subtotal',
              CurrencyFormatter.format(subtotal, currencyCode), theme),
          _PreviewRow(taxLabel,
              CurrencyFormatter.format(taxAmount, currencyCode), theme),
          if (discountAmount > 0)
            _PreviewRow('Discount',
                '−${CurrencyFormatter.format(discountAmount, currencyCode)}',
                theme,
                valueColor: const Color(0xFF1E7D45)),
          const Divider(),
          _PreviewRow(
            'Total',
            CurrencyFormatter.format(total, currencyCode),
            theme,
            bold: true,
          ),
          const SizedBox(height: Spacing.md),
          // Tax inclusive toggle
          Row(
            children: [
              Expanded(
                child: Text('Tax inclusive',
                    style: theme.textTheme.bodySmall),
              ),
              Switch(
                value: taxMode == 1,
                onChanged: onTaxModeChanged,
              ),
            ],
          ),
          // Discount field
          AppTextField(
            controller: discountCtrl,
            label: 'Discount (${discountMode == 0 ? '%' : currencyCode})',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: onDiscountChanged,
          ),
        ],
      ),
    );
  }
}

Widget _PreviewRow(String label, String value, ThemeData theme,
    {bool bold = false, Color? valueColor}) {
  final style = bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style?.copyWith(
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Section label helper
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client picker bottom sheet
// ---------------------------------------------------------------------------

class _ClientPickerSheet extends StatelessWidget {
  const _ClientPickerSheet({required this.clients});

  final List<ClientModel> clients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: Spacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: Radii.chipAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text('Select client', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: clients.isEmpty
                ? Center(
                    child: Text('No clients yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(clients[i].initials,
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                      title: Text(clients[i].name),
                      subtitle: clients[i].phone.isNotEmpty
                          ? Text(clients[i].phone)
                          : null,
                      onTap: () => Navigator.pop(context, clients[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item picker bottom sheet
// ---------------------------------------------------------------------------

class _ItemPickerSheet extends StatelessWidget {
  const _ItemPickerSheet({required this.items});

  final List<ItemModel> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: Spacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: Radii.chipAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text('Pick an item', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No saved items',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i].name),
                      subtitle: Text(items[i].unit),
                      trailing: Text(
                        CurrencyFormatter.format(
                            items[i].unitPriceMinor, items[i].currencyCode),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      onTap: () => Navigator.pop(context, items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
