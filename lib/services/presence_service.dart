import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseDatabase? _database;

  PresenceService() {
    try {
      final dbUrl = Firebase.app().options.databaseURL;
      if (dbUrl != null && dbUrl.isNotEmpty) {
        _database = FirebaseDatabase.instance;
      }
    } catch (e) {
      debugPrint('Realtime Database not configured: $e');
    }
  }

  Future<void> setUserOnline(String uid) async {
    if (uid.isEmpty) return;
    try {
      // 1. Update Firestore
      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'isInGame': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });

      // 2. Realtime Database onDisconnect hook (if RTDB available)
      if (_database != null) {
        final rtdbRef = _database!.ref('presence/$uid');
        await rtdbRef.set({
          'isOnline': true,
          'isInGame': false,
          'lastSeen': ServerValue.timestamp,
        });
        await rtdbRef.onDisconnect().set({
          'isOnline': false,
          'isInGame': false,
          'lastSeen': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  Future<void> setUserInGame(String uid, bool inGame) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'isInGame': inGame,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
      if (_database != null) {
        await _database!.ref('presence/$uid/isInGame').set(inGame);
      }
    } catch (e) {
      debugPrint('Error setting user in game: $e');
    }
  }

  Future<void> setUserOffline(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'isInGame': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
      if (_database != null) {
        await _database!.ref('presence/$uid').set({
          'isOnline': false,
          'isInGame': false,
          'lastSeen': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }
}
