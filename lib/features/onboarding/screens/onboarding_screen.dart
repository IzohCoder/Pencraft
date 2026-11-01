import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/design/tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/database.dart';
import '../../../features/settings/providers/business_profile_providers.dart';
import '../../../services/settings_service.dart';
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Step 1
  final _bizName = TextEditingController();
  final _ownerName = TextEditingController();

  // Step 2
  final _address = TextEditingController();
  final _taxId = TextEditingController();

  // Step 3
  final _mpesa = TextEditingController();
  final _bank = TextEditingController();
  final _paypal = TextEditingController();

  // Step 4
  String _currency = 'KES';
  int _vatBps = 1600;

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [_bizName, _ownerName, _address, _taxId, _mpesa, _bank, _paypal]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageController.nextPage(
          duration: Motion.medium, curve: Motion.decelerate);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    // Save all collected business profile data via the existing repository
    await ref.read(businessProfileRepositoryProvider).upsertProfile(
      BusinessProfilesCompanion(
        name: Value(_bizName.text.trim().isEmpty ? 'My Business' : _bizName.text.trim()),
        ownerName: Value(_ownerName.text.trim()),
        address: Value(_address.text.trim()),
        taxId: Value(_taxId.text.trim()),
        paymentInstructions: Value([
          if (_mpesa.text.trim().isNotEmpty) 'M-Pesa: ${_mpesa.text.trim()}',
          if (_bank.text.trim().isNotEmpty) _bank.text.trim(),
          if (_paypal.text.trim().isNotEmpty) 'PayPal: ${_paypal.text.trim()}',
        ].join('\n')),
        currencyCode: Value(_currency),
        defaultTaxRateBps: Value(_vatBps),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ),
    );
    await ref.read(settingsProvider.notifier).setOnboardingComplete(true);
    if (mounted) context.go('/documents');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header bar with skip
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md, vertical: Spacing.sm),
              child: Row(
                children: [
                  Text('Pencraft',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'DMSerifDisplay')),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: const Text('Skip')),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: LinearProgressIndicator(
                value: (_page + 1) / 4,
                backgroundColor: theme.colorScheme.outlineVariant,
                color: theme.colorScheme.primary,
                borderRadius: Radii.chipAll,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${_page + 1} of 4',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(bizName: _bizName, ownerName: _ownerName),
                  _Step2(address: _address, taxId: _taxId),
                  _Step3(mpesa: _mpesa, bank: _bank, paypal: _paypal),
                  _Step4(
                    currency: _currency,
                    vatBps: _vatBps,
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onVatChanged: (v) => setState(() => _vatBps = v),
                  ),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_page == 3 ? 'Get started' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({required this.bizName, required this.ownerName});
  final TextEditingController bizName;
  final TextEditingController ownerName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Text('Your business', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: Spacing.sm),
          Text('This appears at the top of every invoice you send.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: Spacing.xl),
          AppTextField(
            controller: bizName,
            label: 'Business name',
            hint: 'e.g. Kariuki Designs',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: ownerName,
            label: 'Your name',
            hint: 'e.g. James Kariuki',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({required this.address, required this.taxId});
  final TextEditingController address;
  final TextEditingController taxId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Text('Address & tax', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: Spacing.sm),
          Text('Shown on invoices and may be required for tax compliance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: Spacing.xl),
          AppTextField(
            controller: address,
            label: 'Business address',
            hint: 'Nairobi, Kenya',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: taxId,
            label: 'KRA PIN / Tax ID (optional)',
            hint: 'A123456789B',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({required this.mpesa, required this.bank, required this.paypal});
  final TextEditingController mpesa;
  final TextEditingController bank;
  final TextEditingController paypal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Text('How you get paid', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: Spacing.sm),
          Text('These appear as payment instructions on every invoice. You can always update them later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: Spacing.xl),
          AppTextField(
            controller: mpesa,
            label: 'M-Pesa Paybill / Till number',
            hint: 'e.g. 247247 or Till 123456',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: bank,
            label: 'Bank account details (optional)',
            hint: 'Bank name, account no., branch',
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          AppTextField(
            controller: paypal,
            label: 'PayPal email (optional)',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _Step4 extends StatelessWidget {
  const _Step4({
    required this.currency,
    required this.vatBps,
    required this.onCurrencyChanged,
    required this.onVatChanged,
  });
  final String currency;
  final int vatBps;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<int> onVatChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Text('Currency & tax', style: theme.textTheme.displayMedium),
          const SizedBox(height: Spacing.sm),
          Text('Set your defaults. You can change these per-invoice anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Spacing.xl),
          Text('Default currency', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          DropdownButtonFormField<String>(
            value: currency,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'KES', child: Text('KES — Kenyan Shilling')),
              DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR — Euro')),
              DropdownMenuItem(value: 'GBP', child: Text('GBP — British Pound')),
              DropdownMenuItem(value: 'UGX', child: Text('UGX — Ugandan Shilling')),
              DropdownMenuItem(value: 'TZS', child: Text('TZS — Tanzanian Shilling')),
            ],
            onChanged: (v) { if (v != null) onCurrencyChanged(v); },
          ),
          const SizedBox(height: Spacing.lg),
          Text('Default VAT / tax rate', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          DropdownButtonFormField<int>(
            value: vatBps,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 0, child: Text('0% — No tax')),
              DropdownMenuItem(value: 500, child: Text('5%')),
              DropdownMenuItem(value: 800, child: Text('8%')),
              DropdownMenuItem(value: 1600, child: Text('16% — Kenya VAT')),
              DropdownMenuItem(value: 1800, child: Text('18%')),
              DropdownMenuItem(value: 2000, child: Text('20%')),
            ],
            onChanged: (v) { if (v != null) onVatChanged(v); },
          ),
        ],
      ),
    );
  }
}
