import 'package:go_router/go_router.dart';

import '../../screens/app_shell.dart';
import '../../screens/dashboard/dashboard_page.dart';
import '../../screens/expenses/expenses_page.dart';
import '../../screens/fuel/fuel_page.dart';
import '../../screens/maintenance/maintenance_page.dart';
import '../../screens/vehicles/vehicle_detail_page.dart';
import '../../screens/vehicles/vehicles_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // 0 – Übersicht
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return const DashboardPage();
              },
              routes: [
                GoRoute(
                  path: 'maintenance/:vehicleId',
                  builder: (context, state) {
                    final vehicleId = state.pathParameters['vehicleId']!;

                    return MaintenancePage(vehicleId: vehicleId);
                  },
                ),
              ],
            ),
          ],
        ),

        // 1 – Tanken
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

        // 2 – Kosten
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) {
                return const ExpensesPage();
              },
            ),
          ],
        ),

        // 3 – Fahrzeuge
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (context, state) {
                return const VehiclesPage();
              },
              routes: [
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
