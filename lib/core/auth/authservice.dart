import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // sign user in
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // create a new user
  Future<UserCredential> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      String collegeName,
      String studentId) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // save user data to Realtime Database at users/{uid}
      await _database.ref('users/${userCredential.user!.uid}').set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'collegeName': collegeName,
        'studentId': studentId,
        'createdAt': ServerValue.timestamp,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign user out
  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  // get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // get user data from Realtime Database
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await _database.ref('users/$uid').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }
}
