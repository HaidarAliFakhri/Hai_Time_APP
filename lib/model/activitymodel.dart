class KegiatanFirebase {
  String? docId;
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

  // <-- fields yang penting untuk fiturmu
  final double? jarakManualKm;      // jarak yang user isi (km)
  final String? saranBerangkat;     // teks saran yang disimpan

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
    this.jarakManualKm,
    this.saranBerangkat,
  });

  // FROM FIREBASE (Map -> Model)
  factory KegiatanFirebase.fromMap(Map<String, dynamic> map, String docId) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.'));
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

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
      notifId: parseInt(map['notifId']),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      // penting: ambil jarak manual & saran jika ada
      jarakManualKm: parseDouble(map['jarakManualKm']),
      saranBerangkat: map['saranBerangkat'] as String?,
    );
  }

  // TO FIRESTORE (Model -> Map)
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
      // simpan jarak manual & saran jika ada
      'jarakManualKm': jarakManualKm,
      'saranBerangkat': saranBerangkat,
    };
  }

  // copyWith: sertakan field baru juga
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
    double? jarakManualKm,
    String? saranBerangkat,
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
      jarakManualKm: jarakManualKm ?? this.jarakManualKm,
      saranBerangkat: saranBerangkat ?? this.saranBerangkat,
    );
  }
}
