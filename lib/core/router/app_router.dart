import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/huarique_detail_screen.dart';
import '../../features/home/map_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/preferences/preferences_screen.dart';
import '../../features/subscription/subscription_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) => GoRouter(
        initialLocation: '/login',
        refreshListenable: auth,
        // Controls navigation based on the current authentication state.
        redirect: (context, state) {
          final loggedIn = auth.isLoggedIn;
          final loc = state.matchedLocation;
          final onAuth = loc == '/login' ||
              loc == '/register' ||
              loc == '/forgot-password';
          if (!loggedIn && !onAuth) return '/login';
          // No redirigir desde recuperar contraseña aunque haya sesión nula.
          // App exploradora: cualquier sesión válida va al descubrimiento.
          if (loggedIn && (loc == '/login' || loc == '/register')) {
            return '/home';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (_, _) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (_, _) => const MapScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/preferences',
            builder: (_, _) => const PreferencesScreen(),
          ),
          GoRoute(
            path: '/huarique/:id',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id']!);
              return HuariqueDetailScreen(huariqueId: id);
            },
          ),
          GoRoute(
            path: '/subscription',
            builder: (_, _) => const SubscriptionScreen(),
          ),
        ],
      );
}
