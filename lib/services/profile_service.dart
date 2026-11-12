import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/user_profile.dart';
import 'local_cache_service.dart';

abstract class IProfileService {
  Future<UserProfile?> getProfile(String uid);
  Stream<UserProfile?> streamProfile(String uid);
  Future<UserProfile> initProfileForUser(User user);
  Future<void> updateProfile(UserProfile profile);
  Future<void> recordGameResult(String uid, {required bool isWin, required bool isDraw});
  Future<List<UserProfile>> searchPlayers(String query);
  Stream<List<UserProfile>> getLeaderboard();
}

class FirestoreProfileService implements IProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  String _generatePlayerId() {
    final random = Random();
    final number = 10000 + random.nextInt(90000);
    return 'TTT-$number';
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!, docId: doc.id);
        await LocalCacheService.cacheProfile(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('Error getting profile: $e');
    }
    return LocalCacheService.getCachedProfile();
  }

  @override
  Stream<UserProfile?> streamProfile(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!, docId: doc.id);
        LocalCacheService.cacheProfile(profile);
        return profile;
      }
      return LocalCacheService.getCachedProfile();
    });
  }

  @override
  Future<UserProfile> initProfileForUser(User user) async {
    try {
      final doc = await _usersCol.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final existing = UserProfile.fromMap(doc.data()!, docId: doc.id);
        final updated = existing.copyWith(
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        await _usersCol.doc(user.uid).update({
          'isOnline': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
        await LocalCacheService.cacheProfile(updated);
        return updated;
      }

      // New profile creation
      final isAnonymous = user.isAnonymous;
      final defaultName = isAnonymous
          ? 'Guest_${user.uid.substring(0, 4)}'
          : (user.displayName ?? 'Player');
      final defaultPhoto = user.photoURL ?? '';

      final newProfile = UserProfile(
        uid: user.uid,
        playerId: _generatePlayerId(),
        username: defaultName.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        displayName: defaultName,
        photoUrl: defaultPhoto,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _usersCol.doc(user.uid).set(newProfile.toMap());
      await LocalCacheService.cacheProfile(newProfile);
      return newProfile;
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      final fallback = UserProfile(
        uid: user.uid,
        playerId: _generatePlayerId(),
        username: 'guest',
        displayName: 'Guest Player',
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await LocalCacheService.cacheProfile(fallback);
      return fallback;
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _usersCol.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      await LocalCacheService.cacheProfile(profile);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordGameResult(
    String uid, {
    required bool isWin,
    required bool isDraw,
  }) async {
    try {
      final docRef = _usersCol.doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) return;

        final current = UserProfile.fromMap(snapshot.data()!, docId: snapshot.id);
        final newTotal = current.totalMatches + 1;
        final newWins = isWin ? current.wins + 1 : current.wins;
        final newLosses = (!isWin && !isDraw) ? current.losses + 1 : current.losses;
        final newDraws = isDraw ? current.draws + 1 : current.draws;
        final newStreak = isWin ? current.currentStreak + 1 : 0;
        final newBestStreak = max(newStreak, current.bestStreak);
        final xpGain = isWin ? 50 : (isDraw ? 20 : 10);
        final newXp = current.xp + xpGain;
        final newLevel = (newXp ~/ 150) + 1;

        transaction.update(docRef, {
          'totalMatches': newTotal,
          'wins': newWins,
          'losses': newLosses,
          'draws': newDraws,
          'currentStreak': newStreak,
          'bestStreak': newBestStreak,
          'xp': newXp,
          'level': newLevel,
        });
      });
    } catch (e) {
      debugPrint('Error recording game result: $e');
    }
  }

  @override
  Future<List<UserProfile>> searchPlayers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final clean = query.trim();
      final snapshot = await _usersCol
          .where('playerId', isGreaterThanOrEqualTo: clean.toUpperCase())
          .where('playerId', isLessThanOrEqualTo: '${clean.toUpperCase()}\uf8ff')
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => UserProfile.fromMap(d.data(), docId: d.id)).toList();
      }

      // Try username query
      final userSnap = await _usersCol
          .where('username', isGreaterThanOrEqualTo: clean.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${clean.toLowerCase()}\uf8ff')
          .limit(10)
          .get();

      return userSnap.docs.map((d) => UserProfile.fromMap(d.data(), docId: d.id)).toList();
    } catch (e) {
      debugPrint('Error searching players: $e');
      return [];
    }
  }

  @override
  Stream<List<UserProfile>> getLeaderboard() {
    return _usersCol
        .orderBy('wins', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserProfile.fromMap(d.data(), docId: d.id)).toList());
  }
}
