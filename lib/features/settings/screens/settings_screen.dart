import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../services/settings_service.dart';
import '../../../config/app_config.dart';
import '../../../features/documents/providers/document_providers.dart';
import '../../../services/csv_export_service.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Business profile
          _SettingsGroup(title: 'Business', children: [
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Business profile'),
              subtitle: const Text('Name, logo, address, tax ID'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Payment instructions'),
              subtitle: const Text('M-Pesa, bank, PayPal'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/payment'),
            ),
          ]),

          // Preferences
          _SettingsGroup(title: 'Preferences', children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(settings?.themeMode == 'dark'
                  ? 'Dark'
                  : settings?.themeMode == 'light'
                      ? 'Light'
                      : 'System default'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, ref, settings?.themeMode ?? 'system'),
            ),
          ]),

          // Pro / upgrade
          if (enablePaywall)
            _SettingsGroup(title: 'Subscription', children: [
              ListTile(
                leading: Icon(Icons.workspace_premium_outlined,
                    color: theme.colorScheme.primary),
                title: Text(
                  settings?.isProMock == true ? 'Pencraft Pro — Active' : 'Upgrade to Pro',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                subtitle: settings?.isProMock == true
                    ? const Text('Unlimited invoices, all features')
                    : const Text('Unlimited invoices · All templates · No ads'),
                trailing: settings?.isProMock == true
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: settings?.isProMock == true
                    ? null
                    : () => context.push('/paywall'),
              ),
              // Dev toggle for mock Pro
              if (isDebugMode)
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report_outlined),
                  title: const Text('[Dev] Mock Pro'),
                  value: settings?.isProMock ?? false,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setProMock(v),
                ),
            ]),

          // Data
          _SettingsGroup(title: 'Data', children: [
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup & restore'),
              subtitle: const Text('Save your data to a local file'),
              trailing: Icon(Icons.lock_outline,
                  size: 16,
                  color: settings?.isProMock == true
                      ? Colors.transparent
                      : theme.colorScheme.onSurfaceVariant),
              onTap: () {
                if (enablePaywall && settings?.isProMock != true) {
                  context.push('/paywall?reason=Backup and restore is a Pro feature.');
                  return;
                }
                context.push('/settings/backup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export CSV'),
              trailing: Icon(Icons.lock_outline,
                  size: 16,
                  color: settings?.isProMock == true
                      ? Colors.transparent
                      : theme.colorScheme.onSurfaceVariant),
              onTap: () {
                if (enablePaywall && settings?.isProMock != true) {
                  context.push('/paywall?reason=CSV export is a Pro feature.');
                  return;
                }
                _exportCsv(context, ref);
              },
            ),
          ]),

          // About
          _SettingsGroup(title: 'About', children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open privacy policy */},
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Rate Pencraft'),
              onTap: () {/* TODO: open Play Store */},
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Send feedback'),
              onTap: () {/* TODO: mailto */},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              trailing: const Text('1.0.0', style: TextStyle(fontSize: 14)),
            ),
          ]),

          // Legal disclaimer
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              'Pencraft helps you create and send documents. It does not provide tax or legal advice. Consult a qualified professional for your business\'s tax and legal obligations.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final docsAsync = ref.read(documentListProvider('all'));
    final docs = docsAsync.valueOrNull ?? [];
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No documents to export.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing CSV export…')),
    );
    await CsvExportService().shareAsCsv(docs);
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spacing.sm),
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: Radii.chipAll,
          )),
          const SizedBox(height: Spacing.md),
          for (final opt in [
            ('System default', 'system'),
            ('Light', 'light'),
            ('Dark', 'dark'),
          ])
            ListTile(
              title: Text(opt.$1),
              trailing: current == opt.$2 ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode(opt.$2);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.xs),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}
