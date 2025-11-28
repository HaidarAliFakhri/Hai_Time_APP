class KegiatanFirebase {
  String? docId; // ID dokumen Firebase
  String judul;
  String lokasi;
  String tanggal;
  String waktu;
  String? catatan;
  String status;
  int pengingat;

  String? createdAt;
  String? updatedAt;
  int? notifId;
  final double? latitude;
  final double? longitude;

  KegiatanFirebase({
    this.docId,
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.waktu,
    this.catatan,
    this.status = "Belum Selesai",
    this.pengingat = 0,
    this.createdAt,
    this.updatedAt,
    this.notifId,
    this.latitude,
    this.longitude,
  });

  // FROM FIREBASE
  factory KegiatanFirebase.fromMap(Map<String, dynamic> map, String docId) {
    return KegiatanFirebase(
      docId: docId,
      judul: map['judul'] ?? '',
      lokasi: map['lokasi'] ?? '',
      tanggal: map['tanggal'] ?? '',
      waktu: map['waktu'] ?? '',
      catatan: map['catatan'],
      status: map['status'] ?? 'Belum Selesai',
      pengingat: map['pengingat'] ?? 0,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      notifId: map['notifId'] is int
          ? map['notifId'] as int
          : (map['notifId'] != null
                ? int.tryParse(map['notifId'].toString())
                : null),
      //  Ambil koordinat dari Firestore
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }

  // TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'lokasi': lokasi,
      'tanggal': tanggal,
      'waktu': waktu,
      'catatan': catatan,
      'status': status,
      'pengingat': pengingat,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
      'notifId': notifId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  KegiatanFirebase copyWith({
    String? docId,
    String? judul,
    String? lokasi,
    String? tanggal,
    String? waktu,
    String? catatan,
    String? status,
    int? pengingat,
    String? createdAt,
    String? updatedAt,
    int? notifId,
    double? latitude,
    double? longitude,
  }) {
    return KegiatanFirebase(
      docId: docId ?? this.docId,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      pengingat: pengingat ?? this.pengingat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notifId: notifId ?? this.notifId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
