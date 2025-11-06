class Kegiatan {
  final int? id;
  final String judul;
  final String lokasi;
  final String tanggal;
  final String waktu;
  final String? catatan;
  final String status;

  Kegiatan({
    this.id,
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.waktu,
    this.catatan,
    this.status = "Belum Selesai",
  });

  Kegiatan copyWith({
    int? id,
    String? judul,
    String? lokasi,
    String? tanggal,
    String? waktu,
    String? catatan,
    String? status,
  }) {
    return Kegiatan(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      lokasi: lokasi ?? this.lokasi,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
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
    };
  }

  factory Kegiatan.fromMap(Map<String, dynamic> map) {
    return Kegiatan(
      id: map['id'],
      judul: map['judul'] ?? '',
      lokasi: map['lokasi'] ?? '',
      tanggal: map['tanggal'] ?? '',
      waktu: map['waktu'] ?? '',
      catatan: map['catatan'],
      status: map['status'] ?? "Belum Selesai",
    );
  }
}
