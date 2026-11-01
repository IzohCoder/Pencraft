import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../providers/document_providers.dart';
import '../widgets/document_list_item.dart';
import '../widgets/dashboard_header.dart';
import '../../../services/admob_service.dart';
import '../../../services/settings_service.dart';
import '../../../config/app_config.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all | invoice | estimate

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _filter = ['all', 'invoice', 'estimate'][_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docsAsync = ref.watch(documentListProvider(_filter));
    final settingsAsync = ref.watch(settingsProvider);
    final isPro = settingsAsync.valueOrNull?.isProMock ?? false;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text('Pencraft',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'DMSerifDisplay',
                  letterSpacing: 0,
                )),
            floating: true,
            snap: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Invoices'),
                Tab(text: 'Estimates'),
              ],
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              dividerColor: theme.colorScheme.outlineVariant,
            ),
          ),
          // Dashboard summary header
          SliverToBoxAdapter(
            child: docsAsync.when(
              data: (docs) => DashboardHeader(documents: docs),
              loading: () => const _DashboardSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // Ad banner (free tier only, not in doc flow)
          if (enableAds && !isPro)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Center(child: AppBannerAd(isPro: isPro)),
              ),
            ),
        ],
        body: docsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return _EmptyDocs(filter: _filter, onCreateTap: _onCreateTap);
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => DocumentListItem(
                document: docs[i],
                onTap: () => context.push('/documents/${docs[i].id}'),
              ),
            );
          },
          loading: () => ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const _DocSkeleton(),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: Spacing.md),
                Text('Could not load documents',
                    style: theme.textTheme.bodyMedium),
                TextButton(
                    onPressed: () => ref.refresh(documentListProvider(_filter)),
                    child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateTap,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  void _onCreateTap() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final isPro = settings?.isProMock ?? false;

    // Check free tier limit
    if (enablePaywall && !isPro) {
      final docsThisMonth = settings?.docsThisMonth ?? 0;
      if (docsThisMonth >= freeMonthlyDocumentLimit) {
        if (mounted) {
          context.push('/paywall?reason=You\'ve used your $freeMonthlyDocumentLimit free invoices this month. Upgrade to Pro for unlimited.');
        }
        return;
      }
    }

    // Show type picker
    if (!mounted) return;
    final type = await _showTypePickerSheet(context);
    if (type == null) return;
    if (mounted) context.push('/documents/new?type=$type');
  }

  Future<String?> _showTypePickerSheet(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create new',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.lg),
            _SheetOption(
              icon: Icons.receipt_long,
              label: 'Invoice',
              subtitle: 'Request payment for completed work',
              onTap: () => Navigator.of(context).pop('invoice'),
            ),
            const Divider(height: 1),
            _SheetOption(
              icon: Icons.description_outlined,
              label: 'Estimate',
              subtitle: 'Quote a price before starting work',
              onTap: () => Navigator.of(context).pop('estimate'),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(subtitle),
      onTap: onTap,
      minVerticalPadding: Spacing.sm,
    );
  }
}

class _EmptyDocs extends StatelessWidget {
  const _EmptyDocs({required this.filter, required this.onCreateTap});

  final String filter;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final label = filter == 'estimate' ? 'estimates' : 'invoices';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: Spacing.md),
            Text('No $label yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: Spacing.sm),
            Text('Create your first ${filter == 'estimate' ? 'estimate' : 'invoice'} in under a minute.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: Spacing.xl),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: Text('Create ${filter == 'estimate' ? 'estimate' : 'invoice'}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 120);
  }
}

class _DocSkeleton extends StatelessWidget {
  const _DocSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, height: 14, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12))),
              SizedBox(height: 4),
              SizedBox(width: 80, height: 12, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12))),
            ],
          ),
          Spacer(),
          SizedBox(width: 70, height: 14, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12))),
        ],
      ),
    );
  }
}
