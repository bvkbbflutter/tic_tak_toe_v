import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/game_match.dart';
import '../data/models/user_profile.dart';

abstract class IMatchmakingService {
  Future<int> getRegisteredOtherPlayersCount(String currentUid);
  Future<String?> findQuickMatch(UserProfile currentUser);
  Future<void> cancelMatchmaking(String matchId);
  Future<GameMatch> createPrivateRoom(UserProfile currentUser);
  Future<GameMatch?> joinPrivateRoom(String roomCode, UserProfile joiner);
}

class FirestoreMatchmakingService implements IMatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matchesCol =>
      _firestore.collection('matches');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  String _generateRoomCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  @override
  Future<int> getRegisteredOtherPlayersCount(String currentUid) async {
    try {
      final snap = await _usersCol.limit(20).get();
      return snap.docs.where((d) => d.id != currentUid).length;
    } catch (e) {
      debugPrint('Error checking registered players: $e');
      return 0;
    }
  }

  @override
  Future<String?> findQuickMatch(UserProfile currentUser) async {
    try {
      // 1. Look for existing open match waiting for playerO
      final waitingMatches = await _matchesCol
          .where('status', isEqualTo: 'waiting')
          .where('isPrivate', isEqualTo: false)
          .limit(10)
          .get();

      for (var doc in waitingMatches.docs) {
        final data = doc.data();
        final xId = data['playerXId'] as String? ?? '';
        if (xId.isNotEmpty && xId != currentUser.uid) {
          // Join this match as player O
          await _matchesCol.doc(doc.id).update({
            'playerOId': currentUser.uid,
            'playerOName': currentUser.displayName,
            'playerOAvatar': currentUser.photoUrl,
            'status': 'in_progress',
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
          return doc.id;
        }
      }

      // 2. Check if other registered players exist in the app
      final otherPlayersCount = await getRegisteredOtherPlayersCount(currentUser.uid);
      if (otherPlayersCount == 0) {
        // No other registered players in the game yet
        return null;
      }

      // 3. Other players exist -> Create new waiting match
      final matchDoc = _matchesCol.doc();
      final newMatch = GameMatch(
        matchId: matchDoc.id,
        playerXId: currentUser.uid,
        playerXName: currentUser.displayName,
        playerXAvatar: currentUser.photoUrl,
        board: List.filled(9, ''),
        status: 'waiting',
        currentTurn: 'X',
        isPrivate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await matchDoc.set(newMatch.toMap());
      return matchDoc.id;
    } catch (e) {
      debugPrint('Error finding quick match: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelMatchmaking(String matchId) async {
    try {
      final doc = await _matchesCol.doc(matchId).get();
      if (doc.exists && doc.data()?['status'] == 'waiting') {
        await _matchesCol.doc(matchId).delete();
      }
    } catch (e) {
      debugPrint('Error cancelling matchmaking: $e');
    }
  }

  @override
  Future<GameMatch> createPrivateRoom(UserProfile currentUser) async {
    final matchDoc = _matchesCol.doc();
    final code = _generateRoomCode();
    final match = GameMatch(
      matchId: matchDoc.id,
      playerXId: currentUser.uid,
      playerXName: currentUser.displayName,
      playerXAvatar: currentUser.photoUrl,
      board: List.filled(9, ''),
      status: 'waiting',
      currentTurn: 'X',
      isPrivate: true,
      roomCode: code,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await matchDoc.set(match.toMap());
    return match;
  }

  @override
  Future<GameMatch?> joinPrivateRoom(String roomCode, UserProfile joiner) async {
    try {
      final snap = await _matchesCol
          .where('roomCode', isEqualTo: roomCode.trim())
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = doc.data();
      if (data['playerXId'] == joiner.uid) {
        // Can't join own room as opponent
        return GameMatch.fromMap(data, docId: doc.id);
      }

      await _matchesCol.doc(doc.id).update({
        'playerOId': joiner.uid,
        'playerOName': joiner.displayName,
        'playerOAvatar': joiner.photoUrl,
        'status': 'in_progress',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      final updatedDoc = await _matchesCol.doc(doc.id).get();
      return GameMatch.fromMap(updatedDoc.data()!, docId: updatedDoc.id);
    } catch (e) {
      debugPrint('Error joining room: $e');
      return null;
    }
  }
}
