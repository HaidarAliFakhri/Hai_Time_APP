// lib/services/kegiatan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/activitymodel.dart';

/// Service untuk operasi CRUD pada koleksi `users/{uid}/kegiatan`.
class KegiatanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  KegiatanService();

  /// 1) Tambah kegiatan.
  /// Mengembalikan docId string yang dibuat Firestore.
  Future<String> addKegiatan(String uid, KegiatanFirebase kegiatan) async {
    final ref = _db.collection("users").doc(uid).collection("kegiatan").doc();

    final now = DateTime.now().toIso8601String();

    final data = kegiatan.copyWith(
      docId: ref.id,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(data.toMap());
    return ref.id;
  }

  /// 2) Ambil stream semua kegiatan user (urut terbaru dulu berdasarkan createdAt).
  Stream<List<KegiatanFirebase>> getKegiatanUser(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // doc.data() berisi Map<String,dynamic>
            return KegiatanFirebase.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// 3) Ambil satu kegiatan berdasarkan docId. Kembalikan null jika tidak ada.
  Future<KegiatanFirebase?> getKegiatanById(String uid, String docId) async {
    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .doc(docId)
        .get();

    if (!doc.exists) return null;
    return KegiatanFirebase.fromMap(doc.data()!, doc.id);
  }

  /// 4) Update seluruh object kegiatan (pastikan kegiatan.docId tidak null).
  Future<void> updateKegiatan(String uid, KegiatanFirebase kegiatan) async {
    if (kegiatan.docId == null) {
      throw ArgumentError('kegiatan.docId cannot be null for update');
    }

    final updated = kegiatan.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .doc(kegiatan.docId)
        .update(updated.toMap());
  }

  /// 5) Update hanya field notifId (lebih efisien & aman).
  Future<void> updateKegiatanNotifId(
    String uid,
    String docId,
    int? notifId,
  ) async {
    final patch = <String, dynamic>{
      'notifId': notifId,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .doc(docId)
        .update(patch);
  }

  /// 6) Hapus kegiatan.
  Future<void> deleteKegiatan(String uid, String docId) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .doc(docId)
        .delete();
  }

  /// 7) Ambil histori (status == 'Selesai')
  Stream<List<KegiatanFirebase>> getHistoriKegiatan(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .where('status', isEqualTo: 'Selesai')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return KegiatanFirebase.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
