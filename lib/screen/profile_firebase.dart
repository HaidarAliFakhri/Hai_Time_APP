import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_time_app/model/user_firebase_model.dart';
import 'package:hai_time_app/page/bottom_navigator_firebase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_activity.dart';

class ProfilePageFirebase extends StatefulWidget {
  const ProfilePageFirebase({super.key});

  @override
  State<ProfilePageFirebase> createState() => _ProfilePageFirebaseState();
}

class _ProfilePageFirebaseState extends State<ProfilePageFirebase> {
  String nama = "";
  String email = "";
  String username = "";
  File? _imageFile;
  String lokasi = "Mendeteksi lokasi...";
  String bergabung = "";
  String? profileUrl;

  final DBKegiatan db = DBKegiatan();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    DBKegiatan().periksaKegiatanOtomatis();
    _loadUserData();
    _getCurrentLocation();
    _loadJoinDate();
  }

  Stream<Map<String, int>> streamFirebaseStatistik() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('kegiatan');

    // Stream Total
    final totalStream = ref.snapshots().map((snap) => snap.size);

    // Stream Selesai
    final selesaiStream = ref
        .where('status', isEqualTo: 'Selesai')
        .snapshots()
        .map((snap) => snap.size);

    // Stream Minggu Ini
    final now = DateTime.now();
    final mingguLalu = now.subtract(Duration(days: 7));

    final mingguIniStream = ref
        .where('createdAt', isGreaterThanOrEqualTo: mingguLalu)
        .snapshots()
        .map((snap) => snap.size);

    // Gabungkan 3 stream jadi 1 data Map<String,int>
    return Rx.combineLatest3(totalStream, selesaiStream, mingguIniStream, (
      int total,
      int selesai,
      int mingguIni,
    ) {
      return {"total": total, "selesai": selesai, "mingguIni": mingguIni};
    });
  }

  Future<Map<String, int>> getFirebaseStatistik() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('kegiatan');

    // Total
    final totalSnap = await ref.get();

    // Selesai
    final selesaiSnap = await ref.where('status', isEqualTo: 'Selesai').get();

    // Minggu ini
    final now = DateTime.now();
    final mingguLalu = now.subtract(Duration(days: 7));

    final mingguIniSnap = await ref
        .where('createdAt', isGreaterThanOrEqualTo: mingguLalu)
        .get();

    return {
      "total": totalSnap.size,
      "selesai": selesaiSnap.size,
      "mingguIni": mingguIniSnap.size,
    };
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snap.exists) return;

    final data = UserFirebaseModel.fromMap(snap.data()!);

    setState(() {
      username = data.username ?? "user_${user.uid.substring(0, 5)}";
      nama = username;
      email = data.email ?? user.email ?? "email@example.com";
      profileUrl = data.profileUrl ?? ""; // AMBIL FOTO PROFIL
    });
  }

  Future<void> _loadJoinDate() async {
  try {
    // coba ambil dari Firebase Auth jika user login via Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.metadata.creationTime != null) {
      final DateTime created = user.metadata.creationTime!.toLocal();
      final formatted = "${created.day.toString().padLeft(2, '0')} ${_namaBulan(created.month)} ${created.year}";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('join_date', formatted); // simpan lokal juga
      if (mounted) setState(() => bergabung = formatted);
      return;
    }
  } catch (e) {
    debugPrint("Gagal ambil join date dari Firebase: $e");
    // lanjut ke fallback
  }

  // fallback: jika tidak ada Firebase user / error, gunakan SharedPreferences (saat pendaftaran lokal)
  final prefs = await SharedPreferences.getInstance();
  final storedDate = prefs.getString('join_date');

  if (storedDate == null || storedDate.trim().isEmpty) {
    final now = DateTime.now();
    final formatted = "${now.day.toString().padLeft(2, '0')} ${_namaBulan(now.month)} ${now.year}";
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
    final emailController = TextEditingController(text: email);
    final usernameController = TextEditingController(text: username);

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
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),

                const SizedBox(height: 12),

                // TextField(
                //   controller: emailController,
                //   decoration: const InputDecoration(
                //     labelText: "Email",
                //     border: OutlineInputBorder(),
                //     prefixIcon: Icon(Icons.email),
                //   ),
                // ),
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
                        final user = FirebaseAuth.instance.currentUser;

                        // Cegah error jika user null
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User tidak ditemukan"),
                            ),
                          );
                          return;
                        }

                        final newUsername = usernameController.text.trim();
                        final newEmail = emailController.text.trim();

                        // Validasi form
                        if (newUsername.isEmpty || newEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Username & Email wajib diisi"),
                            ),
                          );
                          return;
                        }

                        try {
                          // Update Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set({
                                "username": newUsername,
                                "email": newEmail,
                                "updated_at": DateTime.now().toIso8601String(),
                              }, SetOptions(merge: true));

                          // Update local state
                          setState(() {
                            username = newUsername;
                            nama = newUsername; // Update ke AppBar
                            email = newEmail;
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profil berhasil diperbarui"),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Gagal memperbarui profil: $e"),
                            ),
                          );
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

  Future<String?> uploadProfileImage(String uid) async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return null;

    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    // Simpan ke Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileUrl': url,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return url;
  }

  // ---------------------------
  // Helper untuk bottom sheet konfirmasi HAPUS (dipanggil dari StreamBuilder)
  // ---------------------------
  Widget _buildBottomSheetConfirm(String judul) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Hapus Aktivitas?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Apakah kamu yakin ingin menghapus aktivitas ini?\n\n‘$judul’",
            style: TextStyle(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
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
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BottomNavigatorFirebase()),
                );
              },
            ),
            title: Text(
              username,
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
                final current = constraints.maxHeight.clamp(
                  minHeight,
                  expandedHeight,
                );
                final t = (current - minHeight) / (expandedHeight - minHeight);
                final avatarOpacity = t.clamp(0.0, 1.0);
                final avatarFast =
                    avatarOpacity * avatarOpacity * avatarOpacity;
                final avatarScale = 0.6 + (0.4 * avatarFast);

                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
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
                          Align(
                            alignment: const Alignment(-0.0, 0.15),
                            child: Opacity(
                              opacity: avatarFast,
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
                                            color: Colors.black.withOpacity(
                                              0.12 * avatarFast,
                                            ),
                                            blurRadius: 10 * avatarFast,
                                            offset: Offset(0, 4 * avatarFast),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _imageFile != null
                                            ? Image.file(
                                                _imageFile!,
                                                width: 110,
                                                height: 110,
                                                fit: BoxFit.cover,
                                                filterQuality:
                                                    FilterQuality.high,
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
                          Align(
                            alignment: const Alignment(0.38, 0.45),
                            // child: Opacity(
                            //   opacity: avatarFast,
                            //   child: Transform.scale(
                            //     scale: avatarScale,
                            //     alignment: Alignment.center,
                            //     child: Container(
                            //       width: 34,
                            //       height: 34,
                            //       decoration: BoxDecoration(
                            //         color: Colors.blueAccent,
                            //         shape: BoxShape.circle,
                            //         border: Border.all(
                            //           color: Colors.white,
                            //           width: 2,
                            //         ),
                            //       ),
                            //       // child: IconButton(
                            //       //   padding: EdgeInsets.zero,
                            //       //   icon: const Icon(
                            //       //     Icons.edit,
                            //       //     color: Colors.white,
                            //       //     size: 18,
                            //       //   ),
                            //       //   onPressed: () async {
                            //       //     final user =
                            //       //         FirebaseAuth.instance.currentUser;
                            //       //     if (user == null) return;

                            //       //     final url = await uploadProfileImage(
                            //       //       user.uid,
                            //       //     );
                            //       //     if (url != null)
                            //       //       setState(() => profileUrl = url);
                            //       //   },
                            //       // ),
                            //     ),
                            //   ),
                            // ),
                          ),
                          Align(
                            alignment: const Alignment(0, 0.7),
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Info dasar (tidak diubah)
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
                          
                          // ListTile(
                          //   leading: const Icon(Icons.tag, color: Colors.blue),
                          //   title: const Text("Username"),
                          //   subtitle: Text(username),
                          // ),
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

                  // Statistik Aktivitas (menggunakan DB lokal sesuai permintaan)
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

                  StreamBuilder<Map<String, int>>(
                    stream: streamFirebaseStatistik(),
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

                  // Aktivitas Terakhir — Firestore stream (stabil & terurut)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Aktivitas Terakhir",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: const [
                                Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(
                                  width: 145,
                                  child: Text(
                                    "Tekan & Tahan untuk Menghapus",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // -------------- StreamBuilder Firestore --------------
                  if (user == null)
                    const Text("Silakan login untuk melihat aktivitas")
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('kegiatan')
                          .where('status', isEqualTo: 'Selesai')
                          .orderBy(
                            'createdAt',
                            descending: true,
                          ) // cuma ini saja
                          .snapshots(),

                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text("Belum ada aktivitas selesai"),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        // tampilkan dengan ListView.builder (shrinkWrap)
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;

                            final judul = data['judul'] ?? "-";
                            final tanggal = data['tanggal'] ?? "-";

                            return GestureDetector(
                              onLongPress: () async {
                                final confirm =
                                    await showModalBottomSheet<bool>(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (ctx) =>
                                          _buildBottomSheetConfirm(judul),
                                    );

                                if (confirm != true) return;

                                final deletedData = Map<String, dynamic>.from(
                                  data,
                                );

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user!.uid)
                                      .collection('kegiatan')
                                      .doc(docId)
                                      .delete();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Gagal menghapus: $e"),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 4),
                                    content: Row(
                                      children: [
                                        Expanded(
                                          child: Text("‘$judul’ telah dihapus"),
                                        ),
                                        TextButton(
                                          child: const Text("Undo"),
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection("users")
                                                  .doc(user!.uid)
                                                  .collection("kegiatan")
                                                  .doc(docId)
                                                  .set(deletedData);
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Dibatalkan (Undo)",
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Gagal mengembalikan: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: _buildActivityCard(
                                judul,
                                tanggal,
                                "Selesai",
                                true,
                              ),
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
                            colors: [
                              Color.fromARGB(255, 17, 0, 112),
                              Color(0xFF007BFF),
                            ],
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
      padding: const EdgeInsets.only(right: 14),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              const Color.fromARGB(255, 149, 208, 250).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.blue.shade100.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CircleAvatar(
            //   radius: 20,
            //   backgroundColor: Colors.blue.shade100,
            //   child: Icon(icon, color: Colors.blue.shade700, size: 22),
            // ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.event_note, color: Colors.blue.shade700, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
