import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<Map<String, dynamic>?> loadUserData(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> createUserProfile(
    String uid, {
    required String name,
    required String email,
    required String userType,
    required String createdAt,
  }) async {
    try {
      await _userDoc(uid).set({
        'name': name,
        'email': email,
        'userType': userType,
        'createdAt': createdAt,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> saveStats(String uid, Map<String, dynamic> data) async {
    try {
      await _userDoc(uid).set({'stats': data}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> saveRewards(String uid, Map<String, dynamic> data) async {
    try {
      await _userDoc(uid).set({'rewards': data}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> saveLives(String uid, int lives) async {
    try {
      await _userDoc(uid).set({'lives': lives}, SetOptions(merge: true));
    } catch (_) {}
  }
}