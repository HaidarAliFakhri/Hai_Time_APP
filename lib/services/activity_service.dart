import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/activitymodel.dart';

class KegiatanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1️⃣ Tambah kegiatan
  Future<void> addKegiatan(String uid, KegiatanFirebase kegiatan) async {
    final ref = _db.collection("users").doc(uid).collection("kegiatan").doc();

    final now = DateTime.now().toIso8601String();

    // Ensure notifId handled by caller normally, but if not present, we'll keep null here.
    // Prefer caller (UI) to create notifId via NotifikasiService.generateSafeNotifId()
    final data = kegiatan.copyWith(
      docId: ref.id,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(data.toMap());
  }

  // 2️⃣ Ambil stream kegiatan user
  Stream<List<KegiatanFirebase>> getKegiatanUser(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        // orderBy createdAt descending gives newest first and avoids composite index issues
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return KegiatanFirebase.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // 3️⃣ Update kegiatan
  Future<void> updateKegiatan(String uid, KegiatanFirebase kegiatan) async {
    // ensure updatedAt set
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

  // 4️⃣ Hapus kegiatan
  Future<void> deleteKegiatan(String uid, String docId) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("kegiatan")
        .doc(docId)
        .delete();
  }

  // 5️⃣ Histori kegiatan
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
