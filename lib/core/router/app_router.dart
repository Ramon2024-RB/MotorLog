import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/app_shell.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/auth/register_page.dart';
import '../../screens/dashboard/dashboard_page.dart';
import '../../screens/documents/document_detail_page.dart';
import '../../screens/documents/documents_page.dart';
import '../../screens/expenses/expenses_page.dart';
import '../../screens/fuel/fuel_page.dart';
import '../../screens/maintenance/maintenance_page.dart';
import '../../screens/premium/premium_page.dart';
import '../../screens/settings/cloud_sync_page.dart';
import '../../screens/settings/settings_page.dart';
import '../../screens/statistics/vehicle_statistics_page.dart';
import '../../screens/tires/tires_page.dart';
import '../../screens/vehicles/vehicle_detail_page.dart';
import '../../screens/vehicles/vehicles_page.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final AuthStateNotifier authStateNotifier = AuthStateNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authStateNotifier,

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;

    final isLoggedIn = session != null;

    final isLoginPage = state.matchedLocation == '/login';
    final isRegisterPage = state.matchedLocation == '/register';

    final isAuthPage = isLoginPage || isRegisterPage;

    if (!isLoggedIn && !isAuthPage) {
      return '/login';
    }

    if (isLoggedIn && isAuthPage) {
      return '/';
    }

    return null;
  },

  routes: [
    // -------------------------------------------------------------------------
    // LOGIN
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    // -------------------------------------------------------------------------
    // REGISTRIERUNG
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterPage();
      },
    ),

    // -------------------------------------------------------------------------
    // EINSTELLUNGEN
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        return const SettingsPage();
      },
      routes: [
        // ---------------------------------------------------------------------
        // CLOUD & SYNCHRONISIERUNG
        // /settings/cloud
        // ---------------------------------------------------------------------

        GoRoute(
          path: 'cloud',
          builder: (context, state) {
            return const CloudSyncPage();
          },
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    // PREMIUM
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/premium',
      builder: (context, state) {
        return const PremiumPage();
      },
    ),

    // -------------------------------------------------------------------------
    // HAUPTNAVIGATION
    // -------------------------------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // ---------------------------------------------------------------------
        // 0 – ÜBERSICHT
        // ---------------------------------------------------------------------

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return const DashboardPage();
              },
              routes: [
                // -----------------------------------------------------------------
                // WARTUNGEN
                // -----------------------------------------------------------------

                GoRoute(
                  path: 'maintenance/:vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return MaintenancePage(vehicleId: vehicleId);
                  },
                ),

                // -----------------------------------------------------------------
                // REIFEN
                // -----------------------------------------------------------------
                GoRoute(
                  path: 'tires/:vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return TiresPage(vehicleId: vehicleId);
                  },
                ),

                // -----------------------------------------------------------------
                // DOKUMENTE
                // -----------------------------------------------------------------
                GoRoute(
                  path: 'documents/:vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return DocumentsPage(vehicleId: vehicleId);
                  },
                  routes: [
                    GoRoute(
                      path: ':documentId',
                      builder: (context, state) {
                        final documentId = state.pathParameters['documentId']!;

                        return DocumentDetailPage(documentId: documentId);
                      },
                    ),
                  ],
                ),

                // -----------------------------------------------------------------
                // STATISTIKEN
                // -----------------------------------------------------------------
                GoRoute(
                  path: 'statistics/:vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return VehicleStatisticsPage(vehicleId: vehicleId);
                  },
                ),
              ],
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // 1 – TANKEN
        // ---------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fuel',
              builder: (context, state) {
                final vehicleId = state.uri.queryParameters['vehicleId'];

                return FuelPage(vehicleId: vehicleId);
              },
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // 2 – KOSTEN
        // ---------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) {
                final vehicleId = state.uri.queryParameters['vehicleId'];

                return ExpensesPage(vehicleId: vehicleId);
              },
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // 3 – FAHRZEUGE
        // ---------------------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) {
                return const VehiclesPage();
              },
              routes: [
                // -------------------------------------------------------------
                // FAHRZEUGDETAILS
                // -------------------------------------------------------------

                GoRoute(
                  path: ':vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return VehicleDetailPage(vehicleId: vehicleId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
