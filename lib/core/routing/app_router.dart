import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/auth_screen.dart';
import '../../features/authentication/barber_signup_screen.dart';
import '../../features/authentication/role_selection_screen.dart';
import '../../features/authentication/signup_screen.dart';
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
import 'transitions.dart';

/// Route table (preserved names — screens were redesigned in place):
/// /splash /onboarding /auth /role/:uid
/// /customer (shell: Home / Explore / Bookings / Profile)
/// /shop/:id /booking/:id /booking-success/:id /queue/:number?bookingId=
/// /barber (shell: Dashboard / Queue / Bookings / Profile)
/// /barber/requests/:id /barber/queue/:id /barber/shop
///
/// Drill-down routes use [DouriTransitionPage] (slide + fade); the entry
/// and shell routes (/splash, /onboarding, /auth, /customer, /barber) keep
/// the default builder (fade handled by the shell).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/signup/barber',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: const BarberSignupScreen(),
        ),
      ),
      GoRoute(
        path: '/role/:uid',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: RoleSelectionScreen(uid: state.pathParameters['uid']!),
        ),
      ),
      GoRoute(path: '/customer', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/shop/:id',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: BarberDetailsScreen(shopId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/booking/:id',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: BookingScreen(shopId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/booking-success/:id',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: BookingConfirmationScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/queue/:number',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: QueueTicketScreen(
            queueNumber: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
            bookingId: state.uri.queryParameters['bookingId'],
          ),
        ),
      ),
      GoRoute(path: '/barber', builder: (_, _) => const BarberDashboardScreen()),
      GoRoute(
        path: '/barber/requests/:id',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: BookingRequestsScreen(shopId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/barber/queue/:id',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: QueueManagementScreen(shopId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/barber/shop',
        pageBuilder: (context, state) => DouriTransitionPage<void>(
          key: state.pageKey,
          kind: DouriTransitionKind.slide,
          child: const ShopManagementScreen(),
        ),
      ),
    ],
  );
});
