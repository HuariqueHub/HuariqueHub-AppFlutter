import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/huarique_detail_screen.dart';
import '../../features/owner/owner_dashboard_screen.dart';
import '../../features/owner/create_edit_huarique_screen.dart';
import '../../features/owner/owner_promos_screen.dart';
import '../../features/owner/create_edit_promo_screen.dart';
import '../../features/subscription/subscription_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) => GoRouter(
        initialLocation: '/login',
        refreshListenable: auth,
        redirect: (context, state) {
          final loggedIn = auth.isLoggedIn;
          final onAuth = state.matchedLocation == '/login' ||
              state.matchedLocation == '/register';
          if (!loggedIn && !onAuth) return '/login';
          if (loggedIn && onAuth) {
            return auth.isOwner ? '/owner-dashboard' : '/home';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (_, __) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/huarique/:id',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id']!);
              return HuariqueDetailScreen(huariqueId: id);
            },
          ),
          GoRoute(
            path: '/owner-dashboard',
            builder: (_, __) => const OwnerDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/huarique/new',
            builder: (_, __) => const CreateEditHuariqueScreen(),
          ),
          GoRoute(
            path: '/owner/huarique/:id/edit',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CreateEditHuariqueScreen(huariqueId: id);
            },
          ),
          GoRoute(
            path: '/owner/promos',
            builder: (_, __) => const OwnerPromosScreen(),
          ),
          GoRoute(
            path: '/owner/promos/new',
            builder: (_, __) => const CreateEditPromoScreen(),
          ),
          GoRoute(
            path: '/owner/promos/:id/edit',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CreateEditPromoScreen(promoId: id);
            },
          ),
          GoRoute(
            path: '/subscription',
            builder: (_, __) => const SubscriptionScreen(),
          ),
        ],
      );
}
