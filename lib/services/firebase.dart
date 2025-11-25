import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hai_time_app/model/user_firebase_model.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // =====================================================
  // REGISTER BIASA (DITAMBAHKAN PARAM username)
  // =====================================================
  static Future<UserFirebaseModel?> registerUser({
    required String email,
    required String password,
    required String username, // 🔥 ditambahkan
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    // 🔥 Simpan ke Firestore seperti registerUserFirebase
    final model = UserFirebaseModel(
      uid: user.uid,
      username: username,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await firestore.collection('users').doc(user.uid).set(model.toMap());

    return model;
  }

  // =====================================================
  // LOGIN USER
  // =====================================================
  static Future<UserFirebaseModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;

      final snap = await firestore.collection('users').doc(user.uid).get();

      if (!snap.exists) return null;

      return UserFirebaseModel.fromMap({'uid': user.uid, ...snap.data()!});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        return null;
      }

      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // =====================================================
  // REGISTER DENGAN USERNAME (SUDAH BENAR)
  // =====================================================
  static Future<UserFirebaseModel?> registerUserFirebase({
    required String email,
    required String username,
    required String password,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return null;

    final model = UserFirebaseModel(
      uid: user.uid,
      username: username,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await firestore.collection('users').doc(user.uid).set(model.toMap());

    return model;
  }
}
