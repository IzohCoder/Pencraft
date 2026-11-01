import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/item_providers.dart';
import '../../../data/models/item_model.dart';
import '../../../core/currency_formatter.dart';

class ItemEditorScreen extends ConsumerStatefulWidget {
  const ItemEditorScreen({super.key, this.itemId});

  final int? itemId;

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _unit = TextEditingController();
  final _price = TextEditingController();
  String _currency = 'KES';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unit.text = 'item';
    if (widget.itemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadItem());
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _unit, _price]) c.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    final item = await ref.read(itemRepositoryProvider).getItem(widget.itemId!);
    if (item != null && mounted) {
      _name.text = item.name;
      _description.text = item.description;
      _unit.text = item.unit;
      _price.text = CurrencyFormatter.formatAmount(item.unitPriceMinor, item.currencyCode);
      setState(() => _currency = item.currencyCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit item' : 'New item'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          AppTextField(
            controller: _name,
            label: 'Item name *',
            hint: 'e.g. Web design, Labour, Consultation',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: _description,
            label: 'Description',
            hint: 'Optional details shown on invoice',
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: _unit,
            label: 'Unit',
            hint: 'item, hour, day, kg, m²…',
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: _price,
            label: 'Default price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            prefixText: '$_currency ',
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final priceMinor = CurrencyFormatter.parseToMinor(_price.text, _currency);
    final repo = ref.read(itemRepositoryProvider);

    if (widget.itemId == null) {
      await repo.createItem(ItemModel(
        id: 0,
        name: _name.text.trim(),
        description: _description.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'item' : _unit.text.trim(),
        unitPriceMinor: priceMinor,
        currencyCode: _currency,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
    } else {
      await repo.updateItem(ItemModel(
        id: widget.itemId!,
        name: _name.text.trim(),
        description: _description.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'item' : _unit.text.trim(),
        unitPriceMinor: priceMinor,
        currencyCode: _currency,
        createdAt: 0,
      ));
    }
    if (mounted) context.pop();
  }
}
