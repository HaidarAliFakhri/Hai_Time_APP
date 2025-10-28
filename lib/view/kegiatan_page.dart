import 'package:flutter/material.dart';

import '../db/db_kegiatan.dart';
import '../model/kegiatan.dart';
import 'tambah_kegiatan.dart';

class KegiatanPage extends StatefulWidget {
  final Kegiatan kegiatan;

  const KegiatanPage({super.key, required this.kegiatan});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Kegiatan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Judul: ${kegiatan.judul}",
              style: const TextStyle(fontSize: 18),
            ),
            Text("Lokasi: ${kegiatan.lokasi}"),
            Text("Tanggal: ${kegiatan.tanggal}"),
            Text("Waktu: ${kegiatan.waktu}"),
            const SizedBox(height: 16),
            if (kegiatan.catatan != null && kegiatan.catatan!.isNotEmpty)
              Text("Catatan: ${kegiatan.catatan}"),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahKegiatanPage(kegiatan: kegiatan),
                      ),
                    );
                    if (result == true) Navigator.pop(context, true);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Hapus"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await DBKegiatan().deleteKegiatan(kegiatan.id!);
                    if (context.mounted) Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
