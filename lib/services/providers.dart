import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_message.dart';
import '../data/models/game_match.dart';
import '../data/models/user_profile.dart';
import 'auth_service.dart';
import 'challenge_service.dart';
import 'chat_service.dart';
import 'local_cache_service.dart';
import 'match_sync_service.dart';
import 'matchmaking_service.dart';
import 'presence_service.dart';
import 'profile_service.dart';
import '../data/models/challenge_model.dart';

// Services
final authServiceProvider = Provider<IAuthService>((ref) {
  return FirebaseAuthService();
});

final profileServiceProvider = Provider<IProfileService>((ref) {
  return FirestoreProfileService();
});

final matchmakingServiceProvider = Provider<IMatchmakingService>((ref) {
  return FirestoreMatchmakingService();
});

final matchSyncServiceProvider = Provider<IMatchSyncService>((ref) {
  return FirestoreMatchSyncService();
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService();
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final challengeServiceProvider = Provider<ChallengeService>((ref) {
  return ChallengeService();
});

// Auth Stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Profile Stream for Current User
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    // If not logged in, try local cache
    return Stream.value(LocalCacheService.getCachedProfile());
  }
  return ref.watch(profileServiceProvider).streamProfile(authUser.uid);
});

// Leaderboard Stream
final leaderboardProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(profileServiceProvider).getLeaderboard();
});

// Active Match Stream
final activeMatchProvider = StreamProvider.family<GameMatch?, String>((ref, matchId) {
  return ref.watch(matchSyncServiceProvider).streamMatch(matchId);
});

// Active Match Chat Stream
final matchChatProvider = StreamProvider.family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(chatServiceProvider).streamMatchChat(matchId);
});

// Direct Conversation Stream
final directConversationProvider = StreamProvider.family<List<ChatMessage>, String>((ref, convId) {
  return ref.watch(chatServiceProvider).streamConversation(convId);
});

// Cached Matches for Offline Replay
final cachedMatchesProvider = Provider<List<GameMatch>>((ref) {
  return LocalCacheService.getCachedMatches();
});

// Incoming Challenges Stream
final incomingChallengesProvider = StreamProvider<List<ChallengeModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null || user.uid.isEmpty) return Stream.value([]);
  return ref.watch(challengeServiceProvider).streamIncomingChallenges(user.uid);
});
