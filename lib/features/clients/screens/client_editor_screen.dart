import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/client_providers.dart';
import '../../../data/models/client_model.dart';

class ClientEditorScreen extends ConsumerStatefulWidget {
  const ClientEditorScreen({super.key, this.clientId});

  final int? clientId;

  @override
  ConsumerState<ClientEditorScreen> createState() => _ClientEditorScreenState();
}

class _ClientEditorScreenState extends ConsumerState<ClientEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _email, _address, _taxId, _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _address = TextEditingController();
    _taxId = TextEditingController();
    _notes = TextEditingController();

    if (widget.clientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadClient());
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _taxId, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    final repo = ref.read(clientRepositoryProvider);
    final client = await repo.getClient(widget.clientId!);
    if (client != null && mounted) {
      _name.text = client.name;
      _phone.text = client.phone;
      _email.text = client.email;
      _address.text = client.address;
      _taxId.text = client.taxId;
      _notes.text = client.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.clientId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit client' : 'New client'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            AppTextField(
              controller: _name,
              label: 'Name *',
              hint: 'Company or person name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              hint: '+254 700 000 000',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _address,
              label: 'Address',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _taxId,
              label: 'Tax ID / KRA PIN',
              hint: 'A123456789B',
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _notes,
              label: 'Notes',
              hint: 'Internal notes (not shown on invoices)',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(clientRepositoryProvider);
    if (widget.clientId == null) {
      await repo.createClient(ClientModel(
        id: 0,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        taxId: _taxId.text.trim(),
        notes: _notes.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ));
    } else {
      await repo.updateClient(ClientModel(
        id: widget.clientId!,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        taxId: _taxId.text.trim(),
        notes: _notes.text.trim(),
        createdAt: 0,
      ));
    }
    if (mounted) context.pop();
  }
}
