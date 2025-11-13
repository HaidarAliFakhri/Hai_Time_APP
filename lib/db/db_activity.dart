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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kegiatan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT,
            lokasi TEXT,
            tanggal TEXT,
            waktu TEXT,
            catatan TEXT,
            status TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE kegiatan ADD COLUMN status TEXT");
        }
      },
    );
  }

  // Statistik kegiatan
  Future<Map<String, int>> getStatistik() async {
    final db = await database;
    final now = DateTime.now();

    final result = await db.query('kegiatan');
    int total = result.length;
    int selesai = 0;
    int mingguIni = 0;

    for (var map in result) {
      final k = Kegiatan.fromMap(map);
      if (k.status == 'Selesai') selesai++;

      try {
        final partsTanggal = k.tanggal.split('/');
        if (partsTanggal.length == 3) {
          final kegiatanDate = DateTime(
            int.parse(partsTanggal[2]),
            int.parse(partsTanggal[1]),
            int.parse(partsTanggal[0]),
          );
          final diff = now.difference(kegiatanDate).inDays;
          if (diff >= 0 && diff <= 7) mingguIni++;
        }
      } catch (_) {}
    }

    return {'total': total, 'selesai': selesai, 'mingguIni': mingguIni};
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
    final count = await db.delete('kegiatan', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
    return count;
  }

  // Periksa otomatis kegiatan yang sudah lewat
  Future<void> periksaKegiatanOtomatis() async {
    final db = await database;
    final result = await db.query('kegiatan');
    final now = DateTime.now();

    for (var map in result) {
      final k = Kegiatan.fromMap(map);

      try {
        final isFormatDenganGarisMiring = k.tanggal.contains("/");
        final tanggalParts = isFormatDenganGarisMiring
            ? k.tanggal.split("/")
            : k.tanggal.split(" ");
        final waktuParts = k.waktu.split(":");

        int tahun, bulan, hari;
        if (isFormatDenganGarisMiring) {
          hari = int.parse(tanggalParts[0]);
          bulan = int.parse(tanggalParts[1]);
          tahun = int.parse(tanggalParts[2]);
        } else {
          hari = int.parse(tanggalParts[0]);
          bulan = _bulanKeAngka(tanggalParts[1]);
          tahun = int.parse(tanggalParts[2]);
        }

        final kegiatanDate = DateTime(
          tahun,
          bulan,
          hari,
          int.parse(waktuParts[0]),
          int.parse(waktuParts[1]),
        );

        if (kegiatanDate.isBefore(now) && k.status != 'Selesai') {
          await db.update(
            'kegiatan',
            {'status': 'Selesai'},
            where: 'id = ?',
            whereArgs: [k.id],
          );
        }
      } catch (e) {
        print("⚠️ Gagal parsing tanggal: ${k.tanggal}, error: $e");
      }
    }

    notifyListeners();
  }

  // Ambil kegiatan selesai
  Future<List<Kegiatan>> getKegiatanSelesai() async {
    final db = await database;
    final now = DateTime.now();

    final result = await db.query(
      'kegiatan',
      where: 'status != ?',
      whereArgs: ['Selesai'],
    );

    for (var map in result) {
      final k = Kegiatan.fromMap(map);
      try {
        final tanggalParts = k.tanggal.split(" ");
        final waktuParts = k.waktu.split(":");
        final bulan = _bulanKeAngka(tanggalParts[1]);
        final kegiatanDate = DateTime(
          int.parse(tanggalParts[2]),
          bulan,
          int.parse(tanggalParts[0]),
          int.parse(waktuParts[0]),
          int.parse(waktuParts[1]),
        );
        if (kegiatanDate.isBefore(now)) {
          await db.update(
            'kegiatan',
            {'status': 'Selesai'},
            where: 'id = ?',
            whereArgs: [k.id],
          );
        }
      } catch (e) {
        print("⚠️ Error parsing tanggal: ${k.tanggal}, $e");
      }
    }

    final updated = await db.query(
      'kegiatan',
      where: 'status = ?',
      whereArgs: ['Selesai'],
      orderBy: 'tanggal DESC',
    );

    return updated.map((e) => Kegiatan.fromMap(e)).toList();
  }

  // Helper
  int _bulanKeAngka(String bulan) {
    switch (bulan.toLowerCase()) {
      case "jan":
      case "januari":
        return 1;
      case "feb":
      case "februari":
        return 2;
      case "mar":
      case "maret":
        return 3;
      case "apr":
      case "april":
        return 4;
      case "mei":
        return 5;
      case "jun":
      case "juni":
        return 6;
      case "jul":
      case "juli":
        return 7;
      case "agu":
      case "agustus":
        return 8;
      case "sep":
      case "september":
        return 9;
      case "okt":
      case "oktober":
        return 10;
      case "nov":
      case "november":
        return 11;
      case "des":
      case "desember":
        return 12;
      default:
        return 1;
    }
  }
}
