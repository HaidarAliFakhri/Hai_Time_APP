class Kegiatan {
  int? id;
  String judul;
  String lokasi;
  String tanggal;
  String waktu;
  String? catatan;

  Kegiatan({
    this.id,
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.waktu,
    this.catatan,
  });

  factory Kegiatan.fromMap(Map<String, dynamic> map) => Kegiatan(
    id: map['id'],
    judul: map['judul'],
    lokasi: map['lokasi'],
    tanggal: map['tanggal'],
    waktu: map['waktu'],
    catatan: map['catatan'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'judul': judul,
    'lokasi': lokasi,
    'tanggal': tanggal,
    'waktu': waktu,
    'catatan': catatan,
  };
}
