class FriendModel {
  final String uid;
  final String playerId;
  final String displayName;
  final String photoUrl;
  final String status; // 'pending', 'accepted', 'blocked'
  final bool isOnline;
  final bool isInGame;
  final int updatedAt;

  const FriendModel({
    required this.uid,
    required this.playerId,
    required this.displayName,
    this.photoUrl = '',
    this.status = 'accepted',
    this.isOnline = false,
    this.isInGame = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'playerId': playerId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status,
      'isOnline': isOnline,
      'isInGame': isInGame,
      'updatedAt': updatedAt,
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return FriendModel(
      uid: map['uid'] as String? ?? docId ?? '',
      playerId: map['playerId'] as String? ?? 'TTT-00000',
      displayName: map['displayName'] as String? ?? 'Player',
      photoUrl: map['photoUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'accepted',
      isOnline: map['isOnline'] as bool? ?? false,
      isInGame: map['isInGame'] as bool? ?? false,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}
