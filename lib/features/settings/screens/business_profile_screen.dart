import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/database.dart';
import '../providers/business_profile_providers.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  String? _logoPath;
  String? _signaturePath;
  int? _existingId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxIdCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile =
        await ref.read(businessProfileRepositoryProvider).getProfile();
    if (!mounted) return;
    if (profile != null) {
      setState(() {
        _existingId = profile.id;
        _nameCtrl.text = profile.name;
        _ownerCtrl.text = profile.ownerName;
        _addressCtrl.text = profile.address;
        _phoneCtrl.text = profile.phone;
        _emailCtrl.text = profile.email;
        _taxIdCtrl.text = profile.taxId;
        _notesCtrl.text = profile.defaultNotes;
        _termsCtrl.text = profile.defaultTerms;
        _logoPath = profile.logoPath;
        _signaturePath = profile.signaturePath;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null && mounted) setState(() => _logoPath = img.path);
  }

  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null && mounted) setState(() => _signaturePath = img.path);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final companion = BusinessProfilesCompanion(
      id: _existingId != null ? Value(_existingId!) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      ownerName: Value(_ownerCtrl.text.trim()),
      address: Value(_addressCtrl.text.trim()),
      phone: Value(_phoneCtrl.text.trim()),
      email: Value(_emailCtrl.text.trim()),
      taxId: Value(_taxIdCtrl.text.trim()),
      defaultNotes: Value(_notesCtrl.text.trim()),
      defaultTerms: Value(_termsCtrl.text.trim()),
      logoPath: Value(_logoPath),
      signaturePath: Value(_signaturePath),
      createdAt: _existingId == null ? Value(now) : const Value.absent(),
    );
    await ref.read(businessProfileRepositoryProvider).upsertProfile(companion);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business profile'),
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
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
            // Logo
            _SectionLabel('Logo'),
            InkWell(
              onTap: _pickLogo,
              borderRadius: Radii.cardBR,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: Radii.cardBR,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _logoPath != null
                    ? ClipRRect(
                        borderRadius: Radii.cardBR,
                        child: Image.file(File(_logoPath!),
                            fit: BoxFit.contain))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text('Tap to add logo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Business details
            _SectionLabel('Business details'),
            AppTextField(
              controller: _nameCtrl,
              label: 'Business name',
              hint: 'Your company or trading name',
            ),
            AppTextField(
              controller: _ownerCtrl,
              label: 'Owner / your name',
              hint: 'Full name',
            ),
            AppTextField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'Street, city, postcode',
              maxLines: 3,
            ),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone',
              hint: '+254 700 000 000',
              keyboardType: TextInputType.phone,
            ),
            AppTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            AppTextField(
              controller: _taxIdCtrl,
              label: 'Tax ID / KRA PIN',
              hint: 'A123456789B',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: Spacing.lg),

            // Payment instructions shortcut
            _SectionLabel('Payment instructions'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('M-Pesa, bank, PayPal & more'),
              subtitle:
                  const Text('Set how clients pay you — shown on every invoice'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/payment'),
            ),
            const Divider(),
            const SizedBox(height: Spacing.lg),

            // Signature
            _SectionLabel('Signature'),
            InkWell(
              onTap: _pickSignature,
              borderRadius: Radii.cardBR,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: Radii.cardBR,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _signaturePath != null
                    ? ClipRRect(
                        borderRadius: Radii.cardBR,
                        child: Image.file(File(_signaturePath!),
                            fit: BoxFit.contain))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_outlined,
                              size: 28,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text('Tap to add signature image',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Defaults
            _SectionLabel('Default invoice text'),
            AppTextField(
              controller: _notesCtrl,
              label: 'Default notes',
              hint: 'e.g. Thank you for your business.',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            AppTextField(
              controller: _termsCtrl,
              label: 'Default terms',
              hint: 'e.g. Payment is due within 30 days.',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 80),
          ],
        ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
