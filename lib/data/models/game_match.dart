import 'move_model.dart';

class GameMatch {
  final String matchId;
  final String playerXId;
  final String playerOId;
  final String playerXName;
  final String playerOName;
  final String playerXAvatar;
  final String playerOAvatar;
  final String currentTurn; // 'X' or 'O'
  final List<String> board; // 9 elements
  final String status; // 'waiting', 'in_progress', 'finished', 'abandoned'
  final String? winner; // 'X', 'O', 'draw', or null
  final List<int>? winningLine; // indices, e.g. [0, 1, 2]
  final List<MoveModel> moves;
  final bool isPrivate;
  final String? roomCode;
  final String? drawOfferBy; // uid of player who offered draw
  final int turnDeadline; // timestamp
  final String? rematchRequestedBy; // uid of player asking for rematch
  final String? rematchStatus; // 'pending', 'accepted', 'declined'
  final int rematchExpiresAt; // epoch timestamp
  final DateTime createdAt;
  final DateTime updatedAt;

  const GameMatch({
    required this.matchId,
    required this.playerXId,
    this.playerOId = '',
    required this.playerXName,
    this.playerOName = 'Waiting for opponent...',
    this.playerXAvatar = '',
    this.playerOAvatar = '',
    this.currentTurn = 'X',
    required this.board,
    this.status = 'waiting',
    this.winner,
    this.winningLine,
    this.moves = const [],
    this.isPrivate = false,
    this.roomCode,
    this.drawOfferBy,
    this.turnDeadline = 0,
    this.rematchRequestedBy,
    this.rematchStatus,
    this.rematchExpiresAt = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'playerXId': playerXId,
      'playerOId': playerOId,
      'playerXName': playerXName,
      'playerOName': playerOName,
      'playerXAvatar': playerXAvatar,
      'playerOAvatar': playerOAvatar,
      'currentTurn': currentTurn,
      'board': board,
      'status': status,
      'winner': winner,
      'winningLine': winningLine,
      'moves': moves.map((m) => m.toMap()).toList(),
      'isPrivate': isPrivate,
      'roomCode': roomCode,
      'drawOfferBy': drawOfferBy,
      'turnDeadline': turnDeadline,
      'rematchRequestedBy': rematchRequestedBy,
      'rematchStatus': rematchStatus,
      'rematchExpiresAt': rematchExpiresAt,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory GameMatch.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawBoard = map['board'] as List<dynamic>?;
    final boardList = rawBoard != null
        ? rawBoard.map((e) => e.toString()).toList()
        : List.filled(9, '');

    final rawMoves = map['moves'] as List<dynamic>?;
    final movesList = rawMoves != null
        ? rawMoves
            .map((m) => MoveModel.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList()
        : <MoveModel>[];

    final rawWinningLine = map['winningLine'] as List<dynamic>?;
    final winningLineList = rawWinningLine?.map((e) => (e as num).toInt()).toList();

    return GameMatch(
      matchId: map['matchId'] as String? ?? docId ?? '',
      playerXId: map['playerXId'] as String? ?? '',
      playerOId: map['playerOId'] as String? ?? '',
      playerXName: map['playerXName'] as String? ?? 'Player X',
      playerOName: map['playerOName'] as String? ?? 'Player O',
      playerXAvatar: map['playerXAvatar'] as String? ?? '',
      playerOAvatar: map['playerOAvatar'] as String? ?? '',
      currentTurn: map['currentTurn'] as String? ?? 'X',
      board: boardList.length == 9 ? boardList : List.filled(9, ''),
      status: map['status'] as String? ?? 'waiting',
      winner: map['winner'] as String?,
      winningLine: winningLineList,
      moves: movesList,
      isPrivate: map['isPrivate'] as bool? ?? false,
      roomCode: map['roomCode'] as String?,
      drawOfferBy: map['drawOfferBy'] as String?,
      turnDeadline: (map['turnDeadline'] as num?)?.toInt() ?? 0,
      rematchRequestedBy: map['rematchRequestedBy'] as String?,
      rematchStatus: map['rematchStatus'] as String?,
      rematchExpiresAt: (map['rematchExpiresAt'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  GameMatch copyWith({
    String? matchId,
    String? playerXId,
    String? playerOId,
    String? playerXName,
    String? playerOName,
    String? playerXAvatar,
    String? playerOAvatar,
    String? currentTurn,
    List<String>? board,
    String? status,
    String? winner,
    List<int>? winningLine,
    List<MoveModel>? moves,
    bool? isPrivate,
    String? roomCode,
    String? drawOfferBy,
    int? turnDeadline,
    String? rematchRequestedBy,
    String? rematchStatus,
    int? rematchExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameMatch(
      matchId: matchId ?? this.matchId,
      playerXId: playerXId ?? this.playerXId,
      playerOId: playerOId ?? this.playerOId,
      playerXName: playerXName ?? this.playerXName,
      playerOName: playerOName ?? this.playerOName,
      playerXAvatar: playerXAvatar ?? this.playerXAvatar,
      playerOAvatar: playerOAvatar ?? this.playerOAvatar,
      currentTurn: currentTurn ?? this.currentTurn,
      board: board ?? this.board,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      winningLine: winningLine ?? this.winningLine,
      moves: moves ?? this.moves,
      isPrivate: isPrivate ?? this.isPrivate,
      roomCode: roomCode ?? this.roomCode,
      drawOfferBy: drawOfferBy ?? this.drawOfferBy,
      turnDeadline: turnDeadline ?? this.turnDeadline,
      rematchRequestedBy: rematchRequestedBy ?? this.rematchRequestedBy,
      rematchStatus: rematchStatus ?? this.rematchStatus,
      rematchExpiresAt: rematchExpiresAt ?? this.rematchExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
