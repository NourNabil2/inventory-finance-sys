import 'package:bungee_manage_sys/core/routes/routes.dart';
import 'package:bungee_manage_sys/features/auth/presentation/cubit/login_cubit.dart';
import 'package:bungee_manage_sys/features/auth/presentation/pages/login_page.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/injection_container.dart' as di;

/// App router for navigation
///
/// Uses DashboardShell for all dashboard routes to maintain
/// persistent sidebar and smooth content switching
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    // ── Auth ──────────────────────────────────────────────
      case Routes.auth:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<LoginCubit>(
            create: (_) => di.sl<LoginCubit>(),
            child: const LoginPage(),
          ),
        );

    // ── Dashboard (Shell Route) ─────────────────────────
    // All dashboard routes use the same DashboardShell
    // The shell handles content switching internally
      case Routes.dashBoard:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.inventory:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.customers:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.invoices:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.finance:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.checks:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      case Routes.suppliers:
        return MaterialPageRoute(
          builder: (_) => const DashboardShell(),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Route not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}