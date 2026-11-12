class UserProfile {
  final String uid;
  final String playerId;
  final String username;
  final String displayName;
  final String photoUrl;
  final String gender;
  final String bio;
  final String country;
  final int level;
  final int xp;
  final int totalMatches;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;
  final bool isOnline;
  final bool isInGame;
  final DateTime lastSeen;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.playerId,
    required this.username,
    required this.displayName,
    this.photoUrl = '',
    this.gender = 'Prefer not to say',
    this.bio = '',
    this.country = '',
    this.level = 1,
    this.xp = 0,
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isOnline = true,
    this.isInGame = false,
    required this.lastSeen,
    required this.createdAt,
  });

  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;

  bool get computedIsOnline =>
      isOnline && DateTime.now().difference(lastSeen).inMinutes < 5;

  bool get computedIsInGame => computedIsOnline && isInGame;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'playerId': playerId,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'gender': gender,
      'bio': bio,
      'country': country,
      'level': level,
      'xp': xp,
      'totalMatches': totalMatches,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isOnline': isOnline,
      'isInGame': isInGame,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserProfile(
      uid: map['uid'] as String? ?? docId ?? '',
      playerId: map['playerId'] as String? ?? 'TTT-00000',
      username: map['username'] as String? ?? 'Player',
      displayName: map['displayName'] as String? ?? 'Player',
      photoUrl: map['photoUrl'] as String? ?? '',
      gender: map['gender'] as String? ?? 'Prefer not to say',
      bio: map['bio'] as String? ?? '',
      country: map['country'] as String? ?? '',
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      totalMatches: (map['totalMatches'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      isOnline: map['isOnline'] as bool? ?? false,
      isInGame: map['isInGame'] as bool? ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['lastSeen'] as num).toInt())
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? playerId,
    String? username,
    String? displayName,
    String? photoUrl,
    String? gender,
    String? bio,
    String? country,
    int? level,
    int? xp,
    int? totalMatches,
    int? wins,
    int? losses,
    int? draws,
    int? currentStreak,
    int? bestStreak,
    bool? isOnline,
    bool? isInGame,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      playerId: playerId ?? this.playerId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      totalMatches: totalMatches ?? this.totalMatches,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isOnline: isOnline ?? this.isOnline,
      isInGame: isInGame ?? this.isInGame,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
