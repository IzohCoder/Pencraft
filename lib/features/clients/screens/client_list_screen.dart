import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../providers/client_providers.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {/* TODO: search */},
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64,
                        color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: Spacing.md),
                    Text('No clients yet', style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Spacing.sm),
                    Text('Add your first client to get started.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Spacing.xl),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/clients/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add client'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: clients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = clients[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(c.name),
                subtitle: c.phone.isNotEmpty ? Text(c.phone) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/clients/${c.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
