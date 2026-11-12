import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/chat/direct_chat_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/history/match_history_screen.dart';
import '../../features/history/replay_screen.dart';
import '../../features/local_game/local_game_screen.dart';
import '../../features/matchmaking/matchmaking_screen.dart';
import '../../features/matchmaking/qr_scanner_screen.dart';
import '../../features/online_game/online_game_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../services/local_cache_service.dart';
import '../../services/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') return null;

      final isLoggedIn = authState.hasValue && authState.value != null;
      final hasCachedProfile = LocalCacheService.getCachedProfile() != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      // If user is not authenticated and has no cached profile, redirect to /auth
      if (!isLoggedIn && !hasCachedProfile) {
        return isAuthRoute ? null : '/auth';
      }

      // If logged in and on /auth, redirect to home
      if ((isLoggedIn || hasCachedProfile) && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/game/local',
        builder: (context, state) => const LocalGameScreen(),
      ),
      GoRoute(
        path: '/matchmaking',
        builder: (context, state) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/game/online/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId'] ?? '';
          return OnlineGameScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/game/replay/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId'] ?? '';
          return ReplayScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MatchHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/chat/:convId',
        builder: (context, state) {
          final convId = state.pathParameters['convId'] ?? '';
          final peerName = state.uri.queryParameters['name'] ?? 'Chat';
          return DirectChatScreen(
            conversationId: convId,
            peerName: peerName,
          );
        },
      ),
    ],
  );
});
