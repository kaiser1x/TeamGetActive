import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';

/// Centralized route definitions. Add new routes here as features are built.
class AppRouter {
  // Route name constants
  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String habits = '/habits';
  static const String progress = '/progress';
  static const String insights = '/insights';
  static const String rewards = '/rewards';
  static const String settings = '/settings';

  /// Generates a route based on [RouteSettings.name].
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // Placeholder routes — screens added in future phases
      case dashboard:
      case habits:
      case progress:
      case insights:
      case rewards:
      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? '')),
            body: Center(
              child: Text(
                '${settings.name} — coming soon',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
