import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seettu_app/screens/my_groups_screen.dart';
import 'package:seettu_app/screens/seettu_detail_screen.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/group_create_step1.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeettuApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/groups', builder: (_, __) => const MyGroupsScreen()),
    GoRoute(
      path: '/seettu/:id',
      builder: (context, state) =>
          SeettuDetailScreen(args: state.extra as SeettuDetailArgs),
    ),
  ],
);

class SeettuApp extends StatelessWidget {
  const SeettuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Seettu',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C3B3A)),
      ),
    );
  }
}
