import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_theme.dart';
import 'data/providers/database_provider.dart';
import 'services/admob_service.dart';
import 'services/revenue_cat_service.dart';
import 'data/seed_data.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RevenueCatService.configure();
  await AdMobService.initialize();
  runApp(const ProviderScope(child: PencraftApp()));
}

class PencraftApp extends ConsumerStatefulWidget {
  const PencraftApp({super.key});

  @override
  ConsumerState<PencraftApp> createState() => _PencraftAppState();
}

class _PencraftAppState extends ConsumerState<PencraftApp> {
  @override
  void initState() {
    super.initState();
    // Seed demo data on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(databaseProvider);
      await SeedData.seedIfEmpty(db);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pencraft',
      routerConfig: router,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
    );
  }
}
