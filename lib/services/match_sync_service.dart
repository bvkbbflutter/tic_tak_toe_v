import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/game_match.dart';
import '../data/models/move_model.dart';
import 'local_cache_service.dart';

abstract class IMatchSyncService {
  Stream<GameMatch?> streamMatch(String matchId);
  Future<bool> makeMove(GameMatch currentMatch, String playerId, int cellIndex);
  Future<void> surrender(GameMatch currentMatch, String playerId);
  Future<void> offerDraw(String matchId, String playerId);
  Future<void> respondDraw(GameMatch currentMatch, bool accept);
  Future<void> requestRematch(GameMatch currentMatch, String playerId);
  Future<void> respondRematch(GameMatch currentMatch, bool accept);
  Future<void> cancelRematch(String matchId);
}

class FirestoreMatchSyncService implements IMatchSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matchesCol =>
      _firestore.collection('matches');

  static const List<List<int>> winningCombos = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  @override
  Stream<GameMatch?> streamMatch(String matchId) {
    return _matchesCol.doc(matchId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final match = GameMatch.fromMap(doc.data()!, docId: doc.id);
      if (match.status == 'finished') {
        LocalCacheService.cacheMatch(match);
      }
      return match;
    }).handleError((error) {
      debugPrint('Stream match handled safely: $error');
      return null;
    });
  }

  @override
  Future<bool> makeMove(GameMatch currentMatch, String playerId, int cellIndex) async {
    if (cellIndex < 0 || cellIndex > 8) return false;
    if (currentMatch.status != 'in_progress') return false;
    if (currentMatch.board[cellIndex].isNotEmpty) return false;

    // Check player identity and turn
    final isPlayerX = currentMatch.playerXId == playerId;
    final isPlayerO = currentMatch.playerOId == playerId;
    if (!isPlayerX && !isPlayerO) return false;

    final mySymbol = isPlayerX ? 'X' : 'O';
    if (currentMatch.currentTurn != mySymbol) return false;

    final newBoard = List<String>.from(currentMatch.board);
    newBoard[cellIndex] = mySymbol;

    // Check winner
    String? winner;
    List<int>? winningLine;

    for (final combo in winningCombos) {
      final a = newBoard[combo[0]];
      final b = newBoard[combo[1]];
      final c = newBoard[combo[2]];
      if (a.isNotEmpty && a == b && b == c) {
        winner = a;
        winningLine = combo;
        break;
      }
    }

    final isDraw = (winner == null && newBoard.every((cell) => cell.isNotEmpty));
    if (isDraw) {
      winner = 'draw';
    }

    final newStatus = (winner != null) ? 'finished' : 'in_progress';
    final nextTurn = (mySymbol == 'X') ? 'O' : 'X';

    final newMove = MoveModel(
      moveNumber: currentMatch.moves.length + 1,
      playerId: playerId,
      symbol: mySymbol,
      index: cellIndex,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedMoves = [...currentMatch.moves, newMove];

    try {
      await _matchesCol.doc(currentMatch.matchId).update({
        'board': newBoard,
        'currentTurn': nextTurn,
        'status': newStatus,
        'winner': winner,
        'winningLine': winningLine,
        'moves': updatedMoves.map((m) => m.toMap()).toList(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (newStatus == 'finished') {
        final finishedMatch = currentMatch.copyWith(
          board: newBoard,
          status: newStatus,
          winner: winner,
          winningLine: winningLine,
          moves: updatedMoves,
        );
        await LocalCacheService.cacheMatch(finishedMatch);
      }
      return true;
    } catch (e) {
      debugPrint('Error making move: $e');
      return false;
    }
  }

  @override
  Future<void> surrender(GameMatch currentMatch, String playerId) async {
    final winner = (currentMatch.playerXId == playerId) ? 'O' : 'X';
    try {
      await _matchesCol.doc(currentMatch.matchId).update({
        'status': 'finished',
        'winner': winner,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      final finishedMatch = currentMatch.copyWith(
        status: 'finished',
        winner: winner,
      );
      await LocalCacheService.cacheMatch(finishedMatch);
    } catch (e) {
      debugPrint('Error surrendering: $e');
    }
  }

  @override
  Future<void> offerDraw(String matchId, String playerId) async {
    try {
      await _matchesCol.doc(matchId).update({
        'drawOfferBy': playerId,
      });
    } catch (e) {
      debugPrint('Error offering draw: $e');
    }
  }

  @override
  Future<void> respondDraw(GameMatch currentMatch, bool accept) async {
    try {
      if (accept) {
        await _matchesCol.doc(currentMatch.matchId).update({
          'status': 'finished',
          'winner': 'draw',
          'drawOfferBy': null,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        await LocalCacheService.cacheMatch(currentMatch.copyWith(
          status: 'finished',
          winner: 'draw',
        ));
      } else {
        await _matchesCol.doc(currentMatch.matchId).update({
          'drawOfferBy': null,
        });
      }
    } catch (e) {
      debugPrint('Error responding to draw: $e');
    }
  }

  @override
  Future<void> requestRematch(GameMatch currentMatch, String playerId) async {
    try {
      final expiresAt = DateTime.now().millisecondsSinceEpoch + 60000; // 60 seconds
      await _matchesCol.doc(currentMatch.matchId).update({
        'rematchRequestedBy': playerId,
        'rematchStatus': 'pending',
        'rematchExpiresAt': expiresAt,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error requesting rematch: $e');
    }
  }

  @override
  Future<void> respondRematch(GameMatch currentMatch, bool accept) async {
    try {
      if (accept) {
        final nextTurn = currentMatch.winner == 'X' ? 'O' : 'X';
        await _matchesCol.doc(currentMatch.matchId).update({
          'board': List.filled(9, ''),
          'moves': [],
          'status': 'in_progress',
          'winner': null,
          'winningLine': null,
          'currentTurn': nextTurn,
          'drawOfferBy': null,
          'rematchRequestedBy': null,
          'rematchStatus': null,
          'rematchExpiresAt': 0,
          'turnDeadline': 0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await _matchesCol.doc(currentMatch.matchId).update({
          'rematchStatus': 'declined',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('Error responding to rematch: $e');
    }
  }

  @override
  Future<void> cancelRematch(String matchId) async {
    try {
      await _matchesCol.doc(matchId).update({
        'rematchRequestedBy': null,
        'rematchStatus': null,
        'rematchExpiresAt': 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error cancelling rematch: $e');
    }
  }
}
