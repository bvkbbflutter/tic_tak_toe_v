class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isReaction;
  final String emoji;
  final int timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isReaction = false,
    this.emoji = '',
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'isReaction': isReaction,
      'emoji': emoji,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ChatMessage(
      id: map['id'] as String? ?? docId ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Player',
      text: map['text'] as String? ?? '',
      isReaction: map['isReaction'] as bool? ?? false,
      emoji: map['emoji'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
