class ChallengeModel {
  final String challengeId;
  final String fromUid;
  final String fromPlayerId;
  final String fromName;
  final String fromAvatar;
  final String toUid;
  final String toName;
  final String matchId;
  final String status; // 'pending', 'accepted', 'declined', 'cancelled', 'expired'
  final DateTime createdAt;
  final int expiresAt; // timestamp epoch in milliseconds

  const ChallengeModel({
    required this.challengeId,
    required this.fromUid,
    this.fromPlayerId = '',
    required this.fromName,
    this.fromAvatar = '',
    required this.toUid,
    this.toName = '',
    required this.matchId,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  int get secondsRemaining {
    final diff = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? (diff / 1000).ceil() : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'fromUid': fromUid,
      'fromPlayerId': fromPlayerId,
      'fromName': fromName,
      'fromAvatar': fromAvatar,
      'toUid': toUid,
      'toName': toName,
      'matchId': matchId,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt,
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ChallengeModel(
      challengeId: map['challengeId'] as String? ?? docId ?? '',
      fromUid: map['fromUid'] as String? ?? '',
      fromPlayerId: map['fromPlayerId'] as String? ?? '',
      fromName: map['fromName'] as String? ?? 'Player',
      fromAvatar: map['fromAvatar'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      toName: map['toName'] as String? ?? '',
      matchId: map['matchId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt())
          : DateTime.now(),
      expiresAt: (map['expiresAt'] as num?)?.toInt() ?? 0,
    );
  }

  ChallengeModel copyWith({
    String? challengeId,
    String? fromUid,
    String? fromPlayerId,
    String? fromName,
    String? fromAvatar,
    String? toUid,
    String? toName,
    String? matchId,
    String? status,
    DateTime? createdAt,
    int? expiresAt,
  }) {
    return ChallengeModel(
      challengeId: challengeId ?? this.challengeId,
      fromUid: fromUid ?? this.fromUid,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      fromName: fromName ?? this.fromName,
      fromAvatar: fromAvatar ?? this.fromAvatar,
      toUid: toUid ?? this.toUid,
      toName: toName ?? this.toName,
      matchId: matchId ?? this.matchId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
