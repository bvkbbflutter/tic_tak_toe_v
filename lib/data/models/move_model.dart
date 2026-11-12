class MoveModel {
  final int moveNumber;
  final String playerId;
  final String symbol; // 'X' or 'O'
  final int index; // 0 to 8
  final int timestamp;

  const MoveModel({
    required this.moveNumber,
    required this.playerId,
    required this.symbol,
    required this.index,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'moveNumber': moveNumber,
      'playerId': playerId,
      'symbol': symbol,
      'index': index,
      'timestamp': timestamp,
    };
  }

  factory MoveModel.fromMap(Map<String, dynamic> map) {
    return MoveModel(
      moveNumber: (map['moveNumber'] as num?)?.toInt() ?? 0,
      playerId: map['playerId'] as String? ?? '',
      symbol: map['symbol'] as String? ?? '',
      index: (map['index'] as num?)?.toInt() ?? 0,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
