import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hai_time_app/model/user_firebase_model.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<UserFirebaseModel?> registerUser({
    required String email,
    required String password,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) return null;
    final snap = await firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;
    return UserFirebaseModel.fromMap({'uid': user.uid, ...snap.data()!});
  }

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
      // handle credential error → return null, biar UI bisa "Email/password salah"
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        return null;
      }

      // kalau error lain (network, too-many-requests, dll) boleh kamu log
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow; // biar ketauan saat debug
    }
  }
}
