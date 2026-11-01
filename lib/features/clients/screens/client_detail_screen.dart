import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../providers/client_providers.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(id));
    final theme = Theme.of(context);

    return clientAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (client) {
        if (client == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Client not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(client.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit client',
                onPressed: () => context.push('/clients/$id/edit'),
              ),
            ],
          ),
          body: ListView(
            children: [
              // Header with initials avatar
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        client.initials,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name, style: theme.textTheme.titleLarge),
                          if (client.taxId.isNotEmpty)
                            Text('KRA PIN: ${client.taxId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contact info
              if (client.phone.isNotEmpty)
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: client.phone,
                ),
              if (client.email.isNotEmpty)
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: client.email,
                ),
              if (client.address.isNotEmpty)
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: client.address,
                ),
              if (client.notes.isNotEmpty)
                _InfoTile(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: client.notes,
                ),

              const Divider(height: Spacing.lg),

              // Invoices section header
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
                child: Text(
                  'INVOICES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // TODO(m2): Show client invoice history from documentListProvider
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(
                  'Invoice history will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/documents/new?clientId=$id'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('New invoice'),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
