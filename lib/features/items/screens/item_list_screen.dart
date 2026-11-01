import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../providers/item_providers.dart';
import '../../../core/currency_formatter.dart';

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Items & Services')),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64,
                        color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: Spacing.md),
                    Text('No items yet', style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Spacing.sm),
                    Text('Save frequently used items and services to add them to invoices quickly.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Spacing.xl),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/items/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.description.isNotEmpty ? item.description : item.unit),
                trailing: Text(
                  CurrencyFormatter.format(item.unitPriceMinor, item.currencyCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                onTap: () => context.push('/items/${item.id}/edit'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/items/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
