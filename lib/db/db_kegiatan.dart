import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/kegiatan.dart';

class DBKegiatan {
  static final DBKegiatan _instance = DBKegiatan._internal();
  factory DBKegiatan() => _instance;
  DBKegiatan._internal();

  static Database? _db;

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
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE kegiatan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          judul TEXT,
          lokasi TEXT,
          tanggal TEXT,
          waktu TEXT,
          catatan TEXT
        )
        ''');
      },
      version: 1,
    );
  }

  Future<int> insertKegiatan(Kegiatan kegiatan) async {
    final db = await database;
    return await db.insert('kegiatan', kegiatan.toMap());
  }

  Future<List<Kegiatan>> getKegiatanList() async {
    final db = await database;
    final result = await db.query('kegiatan');
    return result.map((e) => Kegiatan.fromMap(e)).toList();
  }

  Future<int> updateKegiatan(Kegiatan kegiatan) async {
    final db = await database;
    return await db.update(
      'kegiatan',
      kegiatan.toMap(),
      where: 'id = ?',
      whereArgs: [kegiatan.id],
    );
  }

  Future<int> deleteKegiatan(int id) async {
    final db = await database;
    return await db.delete('kegiatan', where: 'id = ?', whereArgs: [id]);
  }
}
