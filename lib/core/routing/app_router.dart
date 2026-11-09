import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/auth_screen.dart';
import '../../features/authentication/role_selection_screen.dart';
import '../../features/barber/booking_requests/booking_requests_screen.dart';
import '../../features/barber/dashboard/barber_dashboard_screen.dart';
import '../../features/barber/queue_management/queue_management_screen.dart';
import '../../features/barber/shop_management/shop_management_screen.dart';
import '../../features/customer/barber_details/barber_details_screen.dart';
import '../../features/customer/booking/booking_screen.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/queue/queue_ticket_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: '/role/:uid',
        builder: (_, state) => RoleSelectionScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(path: '/customer', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/shop/:id',
        builder: (_, state) => BarberDetailsScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, state) => BookingScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/queue/:number',
        builder: (_, state) => QueueTicketScreen(queueNumber: int.parse(state.pathParameters['number']!)),
      ),
      GoRoute(path: '/barber', builder: (_, _) => const BarberDashboardScreen()),
      GoRoute(
        path: '/barber/requests/:id',
        builder: (_, state) => BookingRequestsScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/barber/queue/:id',
        builder: (_, state) => QueueManagementScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/barber/shop', builder: (_, _) => const ShopManagementScreen()),
    ],
  );
});

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.content_cut, size: 120, color: Color(0xFFC8F078)),
            const SizedBox(height: 24),
            Text('DOURI', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFFC8F078)),
          ],
        ),
      ),
    );
  }
}
