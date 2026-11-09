import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/auth_screen.dart';
import '../../features/authentication/role_selection_screen.dart';
import '../../features/barber/booking_requests/booking_requests_screen.dart';
import '../../features/barber/dashboard/barber_dashboard_screen.dart';
import '../../features/barber/queue_management/queue_management_screen.dart';
import '../../features/barber/shop_management/shop_management_screen.dart';
import '../../features/customer/barber_details/barber_details_screen.dart';
import '../../features/customer/booking/booking_confirmation_screen.dart';
import '../../features/customer/booking/booking_screen.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/queue/queue_ticket_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Route table (preserved names — screens were redesigned in place):
/// /splash /onboarding /auth /role/:uid
/// /customer (shell: Home / Explore / Bookings / Profile)
/// /shop/:id /booking/:id /booking-success/:id /queue/:number?bookingId=
/// /barber (shell: Dashboard / Queue / Bookings / Profile)
/// /barber/requests/:id /barber/queue/:id /barber/shop
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
        path: '/booking-success/:id',
        builder: (_, state) => BookingConfirmationScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/queue/:number',
        builder: (_, state) => QueueTicketScreen(
          queueNumber: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
          bookingId: state.uri.queryParameters['bookingId'],
        ),
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
