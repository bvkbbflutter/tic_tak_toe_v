import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream in-game messages & reactions for an active match
  Stream<List<ChatMessage>> streamMatchChat(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  // Send an in-game reaction or message
  Future<void> sendMatchMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required String text,
    bool isReaction = false,
    String emoji = '',
  }) async {
    try {
      final docRef = _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        id: docRef.id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        isReaction: isReaction,
        emoji: emoji,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await docRef.set(message.toMap());
    } catch (e) {
      debugPrint('Error sending match message: $e');
    }
  }

  // Generate deterministic conversation ID for 2 users
  String getConversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  // Stream 1-on-1 private conversation
  Stream<List<ChatMessage>> streamConversation(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  // Send 1-on-1 private message
  Future<void> sendDirectMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      final docRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        id: docRef.id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await docRef.set(message.toMap());
      await _firestore.collection('conversations').doc(conversationId).set({
        'lastMessage': text,
        'lastSenderId': senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending direct message: $e');
    }
  }
}
