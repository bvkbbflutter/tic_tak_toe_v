import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/game_match.dart';
import '../data/models/user_profile.dart';

class LocalCacheService {
  static const String profileBoxName = 'user_profile_box';
  static const String matchesBoxName = 'match_history_box';
  static const String localGamesBoxName = 'local_games_box';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>(profileBoxName);
      await Hive.openBox<String>(matchesBoxName);
      await Hive.openBox<String>(localGamesBoxName);
    } catch (e) {
      debugPrint('Hive init error: $e');
    }
  }

  // Profile caching
  static Future<void> cacheProfile(UserProfile profile) async {
    try {
      final box = Hive.box<String>(profileBoxName);
      await box.put('current_user', jsonEncode(profile.toMap()));
    } catch (e) {
      debugPrint('Error caching profile: $e');
    }
  }

  static UserProfile? getCachedProfile() {
    try {
      if (!Hive.isBoxOpen(profileBoxName)) return null;
      final box = Hive.box<String>(profileBoxName);
      final jsonStr = box.get('current_user');
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserProfile.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error getting cached profile: $e');
    }
    return null;
  }

  // Matches caching for offline replay
  static Future<void> cacheMatch(GameMatch match) async {
    try {
      if (!Hive.isBoxOpen(matchesBoxName)) return;
      final box = Hive.box<String>(matchesBoxName);
      await box.put(match.matchId, jsonEncode(match.toMap()));
    } catch (e) {
      debugPrint('Error caching match: $e');
    }
  }

  static List<GameMatch> getCachedMatches() {
    try {
      if (!Hive.isBoxOpen(matchesBoxName)) return [];
      final box = Hive.box<String>(matchesBoxName);
      return box.values
          .map((jsonStr) {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            return GameMatch.fromMap(map);
          })
          .where((m) => m.playerXId != 'local_x' && m.playerOId != 'local_o')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error getting cached matches: $e');
      return [];
    }
  }

  static GameMatch? getCachedMatch(String matchId) {
    try {
      if (!Hive.isBoxOpen(matchesBoxName)) return null;
      final box = Hive.box<String>(matchesBoxName);
      final jsonStr = box.get(matchId);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return GameMatch.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error getting cached match: $e');
    }
    return null;
  }
}
