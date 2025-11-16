import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/activity.dart';

class DBKegiatan {
  static final DBKegiatan _instance = DBKegiatan._internal();
  factory DBKegiatan() => _instance;
  DBKegiatan._internal();

  static Database? _db;
  final _controller = StreamController<void>.broadcast();

  // STREAM NOTIFIER
  void notifyListeners() => _controller.add(null);
  Stream<void> get onChange => _controller.stream;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kegiatan.db');

   return openDatabase(
  path,
  version: 3, // naikkan versi jika perlu
  onCreate: (db, version) async {
    await db.execute('''
      CREATE TABLE kegiatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT,
        lokasi TEXT,
        tanggal TEXT,
        waktu TEXT,
        catatan TEXT,
        status TEXT,
        pengingat INTEGER DEFAULT 0
      )
    ''');
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE kegiatan ADD COLUMN status TEXT");
    }
    // jika belum ada pengingat -> tambahkan
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE kegiatan ADD COLUMN pengingat INTEGER DEFAULT 0");
      } catch (e) {
        // ignore jika sudah ada
      }
    }
  },
);

  }

  // Statistik kegiatan
  Future<Map<String, int>> getStatistik() async {
    final db = await database;
    final result = await db.query('kegiatan');

    int total = result.length;
    int selesai = 0;
    int mingguIni = 0;

    final now = DateTime.now();

    for (var map in result) {
      final k = Kegiatan.fromMap(map);
      if (k.status == 'Selesai') selesai++;

      final date = _parseTanggalDanWaktu(k.tanggal, k.waktu);
      if (date == null) continue;

      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff <= 7) mingguIni++;
    }

    return {
      'total': total,
      'selesai': selesai,
      'mingguIni': mingguIni,
    };
  }

  // Tambah kegiatan baru
  Future<int> insertKegiatan(Kegiatan kegiatan) async {
    final db = await database;
    final data = kegiatan.toMap();

    data['status'] ??= 'Belum Selesai';

    final id = await db.insert('kegiatan', data);
    notifyListeners();
    return id;
  }

  // Ambil semua kegiatan
  Future<List<Kegiatan>> getKegiatanList() async {
    final db = await database;
    final result = await db.query('kegiatan', orderBy: 'id DESC');
    return result.map((e) => Kegiatan.fromMap(e)).toList();
  }

  // Update kegiatan
  Future<int> updateKegiatan(Kegiatan kegiatan) async {
    final db = await database;

    final count = await db.update(
      'kegiatan',
      kegiatan.toMap(),
      where: 'id = ?',
      whereArgs: [kegiatan.id],
    );

    notifyListeners();
    return count;
  }

  // Hapus kegiatan
  Future<int> deleteKegiatan(int id) async {
    final db = await database;

    final count = await db.delete(
      'kegiatan',
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
    return count;
  }

  // =============================
  //  AUTO UPDATE STATUS
  // =============================
  Future<void> periksaKegiatanOtomatis() async {
    final db = await database;
    final result = await db.query('kegiatan');
    final now = DateTime.now();

    for (var map in result) {
      final k = Kegiatan.fromMap(map);

      final date = _parseTanggalDanWaktu(k.tanggal, k.waktu);

      if (date == null) {
        print("⚠️ Format tanggal tidak dikenali: ${k.tanggal}");
        continue;
      }

      if (date.isBefore(now) && k.status != 'Selesai') {
        await db.update(
          'kegiatan',
          {'status': 'Selesai'},
          where: 'id = ?',
          whereArgs: [k.id],
        );

        print("✅ Kegiatan otomatis selesai: ${k.judul}");
      }
    }

    notifyListeners();
  }

  // =============================
  // PARSING TANGGAL AMAN
  // =============================
  DateTime? _parseTanggalDanWaktu(String tanggal, String waktu) {
  try {
    tanggal = tanggal.trim();
    waktu = waktu.trim().replaceAll(".", ":");

    // =========================
    //  PARSING WAKTU
    // =========================
    int jam, menit;
    final wp = waktu.split(":");

    if (wp.length < 2) return null;

    jam = int.parse(wp[0]);
    menit = int.parse(wp[1].replaceAll(RegExp(r'[^0-9]'), ''));

    // Format AM/PM
    final lower = waktu.toLowerCase();
    if (lower.contains("pm") && jam < 12) jam += 12;
    if (lower.contains("am") && jam == 12) jam = 0;

    // =========================
    //  PARSING TANGGAL FORMAT 1
    // =========================
    if (tanggal.contains("/")) {
      final p = tanggal.split("/");

      if (p.length != 3) return null;

      return DateTime(
        int.parse(p[2]),
        int.parse(p[1]),
        int.parse(p[0]),
        jam,
        menit,
      );
    }

    // =========================
    //  PARSING TANGGAL FORMAT 2
    // =========================
    if (tanggal.contains(" ")) {
      final p = tanggal.split(" ");

      if (p.length != 3) return null;

      final bulanFix = p[1].trim();

      return DateTime(
        int.parse(p[2]),
        _bulanKeAngka(bulanFix),
        int.parse(p[0]),
        jam,
        menit,
      );
    }

    return null;
  } catch (e) {
    print("⚠️ Gagal parsing: $tanggal $waktu | $e");
    return null;
  }
}



  // Konversi nama bulan
  int _bulanKeAngka(String bulan) {
    const map = {
      "Januari": 1,
      "Februari": 2,
      "Maret": 3,
      "April": 4,
      "Mei": 5,
      "Juni": 6,
      "Juli": 7,
      "Agustus": 8,
      "September": 9,
      "Oktober": 10,
      "November": 11,
      "Desember": 12,
    };
    return map[bulan] ?? 1;
  }

  // =============================
  // DATA KEGIATAN SELESAI
  // =============================
  Future<List<Kegiatan>> getKegiatanSelesai() async {
    final db = await database;

    final result = await db.query(
      'kegiatan',
      where: 'status = ?',
      whereArgs: ['Selesai'],
      orderBy: 'id DESC',
    );

    return result.map((e) => Kegiatan.fromMap(e)).toList();
  }
}
