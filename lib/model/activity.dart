class Kegiatan {
  int? id;
  String judul;
  String lokasi;
  String tanggal;   // dd/MM/yyyy
  String waktu;     // HH:mm
  String? catatan;
  String status;    // "Belum Selesai" / "Selesai"
  int pengingat;    // menit sebelum kegiatan

  Kegiatan({
    this.id,
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.waktu,
    this.catatan,
    this.status = "Belum Selesai",
    this.pengingat = 0,
  });

  factory Kegiatan.fromMap(Map<String, dynamic> map) {
    return Kegiatan(
      id: map['id'] as int?,
      judul: map['judul'] as String? ?? '',
      lokasi: map['lokasi'] as String? ?? '',
      tanggal: map['tanggal'] as String? ?? '',
      waktu: map['waktu'] as String? ?? '',
      catatan: map['catatan'] as String?,
      status: map['status'] as String? ?? 'Belum Selesai',
      pengingat: (map['pengingat'] is int)
          ? map['pengingat'] as int
          : int.tryParse('${map['pengingat'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'lokasi': lokasi,
      'tanggal': tanggal,
      'waktu': waktu,
      'catatan': catatan,
      'status': status,
      'pengingat': pengingat,
    };
  }

  // ================================
  //     ⬇⬇⬇ FIX copyWith ⬇⬇⬇
  // ================================
  Kegiatan copyWith({
    int? id,
    String? judul,
    String? lokasi,
    String? tanggal,
    String? waktu,
    String? catatan,
    String? status,
    int? pengingat,
  }) {
    return Kegiatan(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      pengingat: pengingat ?? this.pengingat,
    );
  }
}
