import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/challenge_model.dart';
import '../data/models/game_match.dart';
import '../data/models/user_profile.dart';
import 'local_cache_service.dart';

class PastOpponent {
  final String uid;
  final String displayName;
  final String photoUrl;
  final int gamesPlayed;
  final int winsAgainst;
  final int lossesAgainst;
  final DateTime lastPlayed;

  const PastOpponent({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.gamesPlayed,
    required this.winsAgainst,
    required this.lossesAgainst,
    required this.lastPlayed,
  });
}

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challengesCol =>
      _firestore.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _matchesCol =>
      _firestore.collection('matches');

  /// Creates a private match and sends a 60-second challenge to the target user.
  Future<ChallengeModel?> sendChallenge({
    required UserProfile fromUser,
    required UserProfile toUser,
  }) async {
    try {
      final now = DateTime.now();
      final matchDoc = _matchesCol.doc();
      final challengeDoc = _challengesCol.doc();
      final expiresAt = now.millisecondsSinceEpoch + 60000; // 60 seconds

      final newMatch = GameMatch(
        matchId: matchDoc.id,
        playerXId: fromUser.uid,
        playerOId: toUser.uid,
        playerXName: fromUser.displayName,
        playerOName: toUser.displayName,
        playerXAvatar: fromUser.photoUrl,
        playerOAvatar: toUser.photoUrl,
        currentTurn: 'X',
        board: List.filled(9, ''),
        status: 'waiting',
        isPrivate: true,
        createdAt: now,
        updatedAt: now,
      );

      final challenge = ChallengeModel(
        challengeId: challengeDoc.id,
        fromUid: fromUser.uid,
        fromPlayerId: fromUser.playerId,
        fromName: fromUser.displayName,
        fromAvatar: fromUser.photoUrl,
        toUid: toUser.uid,
        toName: toUser.displayName,
        matchId: matchDoc.id,
        status: 'pending',
        createdAt: now,
        expiresAt: expiresAt,
      );

      final batch = _firestore.batch();
      batch.set(matchDoc, newMatch.toMap());
      batch.set(challengeDoc, challenge.toMap());
      await batch.commit();

      return challenge;
    } catch (e) {
      debugPrint("Error sending challenge: $e");
      return null;
    }
  }

  /// Listen for incoming pending challenges targeted at [uid]
  Stream<List<ChallengeModel>> streamIncomingChallenges(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _challengesCol
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = <ChallengeModel>[];
      for (final doc in snapshot.docs) {
        final c = ChallengeModel.fromMap(doc.data(), docId: doc.id);
        if (!c.isExpired) {
          list.add(c);
        }
      }
      return list;
    }).handleError((e) {
      debugPrint("Incoming challenges stream error: $e");
      return <ChallengeModel>[];
    });
  }

  /// Stream a specific challenge for real-time status updates (accepted/declined)
  Stream<ChallengeModel?> streamChallenge(String challengeId) {
    if (challengeId.isEmpty) return Stream.value(null);
    return _challengesCol.doc(challengeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ChallengeModel.fromMap(doc.data()!, docId: doc.id);
    }).handleError((e) {
      debugPrint("Stream challenge handled safely: $e");
      return null;
    });
  }

  /// Respond to an incoming challenge (Accept or Decline)
  Future<bool> respondChallenge({
    required ChallengeModel challenge,
    required UserProfile responder,
    required bool accept,
  }) async {
    try {
      if (accept) {
        final batch = _firestore.batch();
        batch.update(_challengesCol.doc(challenge.challengeId), {
          'status': 'accepted',
        });
        batch.update(_matchesCol.doc(challenge.matchId), {
          'status': 'in_progress',
          'playerOId': responder.uid,
          'playerOName': responder.displayName,
          'playerOAvatar': responder.photoUrl,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        await batch.commit();
        return true;
      } else {
        final batch = _firestore.batch();
        batch.update(_challengesCol.doc(challenge.challengeId), {
          'status': 'declined',
        });
        batch.delete(_matchesCol.doc(challenge.matchId));
        await batch.commit();
        return false;
      }
    } catch (e) {
      debugPrint("Error responding to challenge: $e");
      return false;
    }
  }

  /// Cancel an outgoing challenge
  Future<void> cancelChallenge(String challengeId, String matchId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_challengesCol.doc(challengeId), {
        'status': 'cancelled',
      });
      batch.delete(_matchesCol.doc(matchId));
      await batch.commit();
    } catch (e) {
      debugPrint("Error cancelling challenge: $e");
    }
  }

  /// Retrieve list of past opponents from locally cached match history and Firestore
  Future<List<PastOpponent>> getPastOpponents(String currentUid) async {
    final cached = LocalCacheService.getCachedMatches();
    final Map<String, List<GameMatch>> grouped = {};

    for (final match in cached) {
      String? oppUid;
      if (match.playerXId == currentUid && match.playerOId.isNotEmpty && match.playerOId != currentUid) {
        oppUid = match.playerOId;
      } else if (match.playerOId == currentUid && match.playerXId.isNotEmpty && match.playerXId != currentUid) {
        oppUid = match.playerXId;
      }
      if (oppUid != null && oppUid.isNotEmpty) {
        grouped.putIfAbsent(oppUid, () => []).add(match);
      }
    }

    final List<PastOpponent> opponents = [];
    for (final entry in grouped.entries) {
      final oppUid = entry.key;
      final matches = entry.value;
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = matches.first;

      final isOpponentX = latest.playerXId == oppUid;
      final name = isOpponentX ? latest.playerXName : latest.playerOName;
      final avatar = isOpponentX ? latest.playerXAvatar : latest.playerOAvatar;

      int wins = 0;
      int losses = 0;
      for (final m in matches) {
        if (m.winner != null && m.winner != 'draw') {
          final wonByX = m.winner == 'X';
          final currentIsX = m.playerXId == currentUid;
          if ((wonByX && currentIsX) || (!wonByX && !currentIsX)) {
            wins++;
          } else {
            losses++;
          }
        }
      }

      opponents.add(PastOpponent(
        uid: oppUid,
        displayName: name.isNotEmpty ? name : 'Past Opponent',
        photoUrl: avatar,
        gamesPlayed: matches.length,
        winsAgainst: wins,
        lossesAgainst: losses,
        lastPlayed: latest.createdAt,
      ));
    }

    opponents.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return opponents;
  }
}
