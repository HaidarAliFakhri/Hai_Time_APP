import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_time_app/model/activity.dart';
import 'package:hai_time_app/page/bottom_navigator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

import '../db/db_activity.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = "";
  String email = "";
  String username = "";
  File? _imageFile;
  String lokasi = "Mendeteksi lokasi...";
  String bergabung = "";
  final DBKegiatan db = DBKegiatan();

  @override
  void initState() {
    super.initState();
    DBKegiatan().periksaKegiatanOtomatis();
    _loadUserData();
    _getCurrentLocation();
    _loadJoinDate();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image');

    setState(() {
      nama = prefs.getString('registered_name') ?? "User";
      email = prefs.getString('registered_email') ?? "user@email.com";
      username = nama.toLowerCase().replaceAll(' ', '_');
      if (imagePath != null) _imageFile = File(imagePath);
    });
  }

  Future<void> _loadJoinDate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString('join_date');

    if (storedDate == null) {
      final now = DateTime.now();
      final formatted =
          "${now.day.toString().padLeft(2, '0')} ${_namaBulan(now.month)} ${now.year}";
      await prefs.setString('join_date', formatted);
      if (mounted) setState(() => bergabung = formatted);
    } else {
      if (mounted) setState(() => bergabung = storedDate);
    }
  }

  String _namaBulan(int bulan) {
    const bulanIndo = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return (bulan >= 1 && bulan <= 12) ? bulanIndo[bulan - 1] : "";
  }

  Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    setState(() => lokasi = "Layanan lokasi tidak aktif");
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() => lokasi = "Izin lokasi ditolak");
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    setState(() => lokasi = "Izin lokasi ditolak permanen");
    return;
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    //  Ubah koordinat jadi nama kota, kecamatan, dst.
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final namaLokasi = [
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality,
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          place.administrativeArea,
      ].join(', ');

      setState(() {
        lokasi = namaLokasi.isNotEmpty
            ? namaLokasi
            : "Lokasi terdeteksi (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})";
      });
    } else {
      setState(() {
        lokasi =
            "Tidak dapat menentukan alamat (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})";
      });
    }
  } catch (e) {
    setState(() {
      lokasi = "Gagal mendeteksi lokasi";
    });
  }
}


  void _showEditBottomSheet(BuildContext context) {
    final nameController = TextEditingController(text: nama);
    final emailController = TextEditingController(text: email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Edit Profil",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'registered_name',
                          nameController.text.trim(),
                        );
                        await prefs.setString(
                          'registered_email',
                          emailController.text.trim(),
                        );

                        if (mounted) {
                          setState(() {
                            nama = nameController.text.trim();
                            email = emailController.text.trim();
                            username = nama.toLowerCase().replaceAll(' ', '_');
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _gantiFotoProfil() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', picked.path);

      setState(() {
        _imageFile = File(picked.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diubah!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
  pinned: true,
  expandedHeight: 280,
  backgroundColor: Colors.transparent,
  centerTitle: true, // ini yang bikin teks di tengah
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigator()),
      );
    },
  ),
  title: Text(
    nama,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),

  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      final expandedHeight = 280.0;
      final minHeight = kToolbarHeight;
      final current = constraints.maxHeight.clamp(minHeight, expandedHeight);
      final t = (current - minHeight) / (expandedHeight - minHeight);
      final avatarOpacity = t.clamp(0.0, 1.0);
      final avatarFast = avatarOpacity * avatarOpacity * avatarOpacity;
      final avatarScale = 0.6 + (0.4 * avatarFast);

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAEFE), Color(0xFF007BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Avatar (menghilang cepat)
                Align(
                  alignment: const Alignment(-0.0, 0.15),
                  child: Opacity(
                    opacity: avatarFast, // sudah ada opacity
                    child: Transform.scale(
                      scale: avatarScale,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12 * avatarFast),
                                  blurRadius: 10 * avatarFast,
                                  offset: Offset(0, 4 * avatarFast),
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                    )
                                  : Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.white,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tombol edit yang ikut menghilang bersama avatar
                Align(
                  alignment: const Alignment(0.38, 0.45),
                  child: Opacity(
                    opacity: avatarFast, // sudah ada opacity
                    child: Transform.scale(
                      scale: avatarScale,
                      alignment: Alignment.center,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          onPressed: _gantiFotoProfil,
                        ),
                      ),
                    ),
                  ),
                ),

                // Nama kecil di area expanded (hanya dekorasi)
                Align(
                  alignment: const Alignment(0, 0.7),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0), // sudah ada opacity
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        email,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
),




          // Bagian isi bawah
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Info dasar
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: Colors.blue,
                            ),
                            title: const Text("Email"),
                            subtitle: Text(email),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                            ),
                            title: const Text("Lokasi"),
                            subtitle: Text(lokasi),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.blue,
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.calendar_month,
                              color: Colors.blue,
                            ),
                            title: const Text("Bergabung Sejak"),
                            subtitle: Text(bergabung),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Statistik Aktivitas
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Statistik Aktivitas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  FutureBuilder<Map<String, int>>(
                    future: db.getStatistik(),

                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data = snapshot.data!;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard(
                              "Total Kegiatan",
                              "${data['total']}",
                              Icons.event,
                            ),
                            _buildStatCard(
                              "Kegiatan Selesai",
                              "${data['selesai']}",
                              Icons.check_circle,
                            ),
                            _buildStatCard(
                              "Minggu Ini",
                              "${data['mingguIni']}",
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  //  Aktivitas Terakhir
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Aktivitas Terakhir",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<void>(
                    stream: db.onChange,
                    builder: (context, snapshot) {
                      return FutureBuilder<List<Kegiatan>>(
                        future: db.getKegiatanSelesai(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final selesai = snapshot.data!;
                          if (selesai.isEmpty) {
                            return const Text("Belum ada aktivitas selesai");
                          }
                          return Column(
                            children: selesai.map((k) {
                              return Dismissible(
                                key: Key('activity_${k.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Hapus Aktivitas"),
                                      content: Text(
                                        "Yakin ingin menghapus '${k.judul}' dari riwayat?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text(
                                            "Hapus",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) async {
                                  final deletedKegiatan = k;
                                  await db.deleteKegiatan(k.id!);
                                  db.notifyListeners();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "‘${k.judul}’ telah dihapus",
                                      ),
                                      action: SnackBarAction(
                                        label: "Urungkan",
                                        textColor: Colors.yellowAccent,
                                        onPressed: () async {
                                          await db.insertKegiatan(
                                            deletedKegiatan,
                                          );
                                          db.notifyListeners();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: _buildActivityCard(
                                  k.judul,
                                  k.tanggal,
                                  "Selesai",
                                  true,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  // Tombol Edit Profil
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _showEditBottomSheet(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3FA9F5), Color(0xFF007BFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Edit Profil",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String date,
    String status,
    bool done,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.event, color: done ? Colors.blue : Colors.orange),
        title: Text(title),
        subtitle: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: done ? Colors.blue[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: done ? Colors.blue : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
