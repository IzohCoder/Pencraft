import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/documents/screens/document_list_screen.dart';
import 'features/documents/screens/document_detail_screen.dart';
import 'features/documents/screens/document_creator_screen.dart';
import 'features/documents/screens/pdf_preview_screen.dart';
import 'features/clients/screens/client_list_screen.dart';
import 'features/clients/screens/client_detail_screen.dart';
import 'features/clients/screens/client_editor_screen.dart';
import 'features/items/screens/item_list_screen.dart';
import 'features/items/screens/item_editor_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/business_profile_screen.dart';
import 'features/settings/screens/payment_instructions_screen.dart';
import 'features/settings/screens/backup_restore_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/paywall/paywall_screen.dart';

// Shared shell widget
import './core/widgets/scaffold_shell.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String documents = '/documents';
  static const String documentDetail = '/documents/:id';
  static const String documentCreate = '/documents/new';
  static const String documentPdf = '/documents/:id/pdf';
  static const String clients = '/clients';
  static const String clientDetail = '/clients/:id';
  static const String clientCreate = '/clients/new';
  static const String items = '/items';
  static const String itemCreate = '/items/new';
  static const String settings = '/settings';
  static const String businessProfile = '/settings/profile';
  static const String paymentInstructions = '/settings/payment';
  static const String backupRestore = '/settings/backup';
  static const String paywall = '/paywall';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.documents,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldShell(
          navigationShell: shell,
          tabs: const [
            ShellTab(
              label: 'Invoices',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
            ),
            ShellTab(
              label: 'Clients',
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
            ),
            ShellTab(
              label: 'Items',
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2,
            ),
            ShellTab(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
            ),
          ],
        ),
        branches: [
          // Tab 0: Documents
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.documents,
                builder: (_, __) => const DocumentListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, state) {
                      final type = state.uri.queryParameters['type'] ?? 'invoice';
                      return DocumentCreatorScreen(documentType: type);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => DocumentDetailScreen(
                      id: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'pdf',
                        builder: (_, state) => PdfPreviewScreen(
                          documentId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => DocumentCreatorScreen(
                          documentId: int.parse(state.pathParameters['id']!),
                          documentType: 'invoice',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Tab 1: Clients
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clients,
                builder: (_, __) => const ClientListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const ClientEditorScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ClientDetailScreen(
                      id: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'pdf',
                        builder: (_, state) => PdfPreviewScreen(
                          documentId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => ClientEditorScreen(
                          clientId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Items
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.items,
                builder: (_, __) => const ItemListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const ItemEditorScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (_, state) => ItemEditorScreen(
                      itemId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const BusinessProfileScreen(),
                  ),
                  GoRoute(
                    path: 'payment',
                    builder: (_, state) => PaymentInstructionsScreen(
                      initialValue: state.uri.queryParameters['current'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (_, __) => const BackupRestoreScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Modal routes (outside shell)
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, state) => PaywallScreen(
          reason: state.uri.queryParameters['reason'],
        ),
      ),
    ],
  );
});
