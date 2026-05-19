import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
  bool get isAuthenticated => _ref.read(authNotifierProvider).isAuthenticated;
  bool get isLoading => _ref.read(authNotifierProvider).isLoading;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      if (notifier.isLoading) return '/splash';
      final isAuth = notifier.isAuthenticated;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register' || loc == '/splash';
      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/search',
            builder: (_, state) => SearchScreen(
              initialDestination: state.uri.queryParameters['destination'],
            ),
          ),
          GoRoute(path: '/trips', builder: (_, __) => const TripsScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const AiChatScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/booking/:tripId',
            builder: (_, state) =>
                BookingScreen(tripId: state.pathParameters['tripId']!),
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 64, color: Color(0xFF2563EB)),
            SizedBox(height: 24),
            Text('TravelEasy',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB))),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromPath(location),
        onDestinationSelected: (i) => _navigateTo(context, i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Recherche'),
          NavigationDestination(
              icon: Icon(Icons.luggage_outlined),
              selectedIcon: Icon(Icons.luggage),
              label: 'Voyages'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'IA'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/trips') || path.startsWith('/booking')) return 2;
    if (path.startsWith('/chat')) return 3;
    return 4;
  }

  void _navigateTo(BuildContext context, int index) {
    const paths = ['/home', '/search', '/trips', '/chat', '/profile'];
    context.go(paths[index]);
  }
}
