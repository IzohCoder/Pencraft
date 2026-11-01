import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../../../services/backup_service.dart';

/// Backup & Restore screen — Pro feature.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: Radii.cardBR,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Your data stays on your device',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Backups are saved as a local JSON file. '
                  'You can copy it to Google Drive, WhatsApp, or any storage app for safekeeping.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Export section
          Text('Create Backup', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          Text(
            'Exports all invoices, clients, items, and settings to a file on this device.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isExporting ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_isExporting ? 'Exporting…' : 'Export Backup'),
            ),
          ),
          const SizedBox(height: Spacing.xl),

          const Divider(),
          const SizedBox(height: Spacing.lg),

          // Restore section
          Text('Restore from Backup', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: Radii.cardBR,
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restoring will replace ALL current data. This cannot be undone.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isImporting ? null : _import,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: Text(_isImporting ? 'Restoring…' : 'Restore from File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
            ),
          ),

          if (_lastMessage != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _lastMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: _lastMessage!.startsWith('✅')
                      ? const Color(0xFF1E7D45)
                      : theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() {
      _isExporting = true;
      _lastMessage = null;
    });
    try {
      final path = await ref.read(backupServiceProvider).exportBackup();
      if (path != null) {
        setState(() => _lastMessage = '✅ Backup saved to:\n$path');
      } else {
        setState(() => _lastMessage = '❌ Export failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _import() async {
    // Confirm before destructive action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
            'This will replace all your current data with the backup file you choose. '
            'This cannot be undone.\n\nAre you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isImporting = true;
      _lastMessage = null;
    });
    try {
      final success = await ref.read(backupServiceProvider).importBackup();
      setState(() {
        _lastMessage = success
            ? '✅ Data restored successfully. Restart the app to see changes.'
            : '❌ Restore failed. Make sure you selected a valid Pencraft backup file.';
      });
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
