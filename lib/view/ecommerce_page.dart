// ============================================================
// ecomerce_page.dart — HaiTime Food Marketplace
// ============================================================
// INSTALASI (pubspec.yaml):
//   dependencies:
//     url_launcher: ^6.2.5
//     geolocator: ^11.0.0
//
// AndroidManifest.xml (dalam <manifest>):
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//   <queries>
//     <intent>
//       <action android:name="android.intent.action.VIEW"/>
//       <data android:scheme="https"/>
//     </intent>
//     <intent>
//       <action android:name="android.intent.action.DIAL"/>
//     </intent>
//   </queries>
//
// Info.plist (iOS):
//   NSLocationWhenInUseUsageDescription → "Untuk menampilkan UMKM terdekat"
//
// Setelah install package, aktifkan bagian yang diberi komentar TODO.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// TODO: Uncomment setelah flutter pub get
import 'package:url_launcher/url_launcher.dart';
 import 'package:geolocator/geolocator.dart';

// ══════════════════════════════════════════════════════════════
//  MODEL
// ══════════════════════════════════════════════════════════════

class LatLng {
  final double lat, lng;
  const LatLng(this.lat, this.lng);
}

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final String category;
  final bool isBestSeller;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
    this.isBestSeller = false,
  });
}

class CartItem {
  final FoodItem food;
  int quantity;
  CartItem({required this.food, this.quantity = 1});
  double get subtotal => food.price * quantity;
}

class Umkm {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String emoji;
  final String tag;
  final LatLng location;
  final List<FoodItem> menu;
  double? distanceKm;

  Umkm({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.emoji,
    required this.tag,
    required this.location,
    required this.menu,
    this.distanceKm,
  });
}

// ══════════════════════════════════════════════════════════════
//  DATA UMKM — Setiabudi, Jakarta Selatan
// ══════════════════════════════════════════════════════════════

final List<Umkm> _allUmkm = [
  Umkm(
    id: 'u1',
    name: 'Warteg Karunia Jaya',
    phone: '081944368941',
    address: 'Jl. Setiabudi Tengah No.12, Setiabudi',
    emoji: '🍛',
    tag: 'Masakan rumahan • Murah meriah',
    location: const LatLng(-6.2088, 106.8228),
    menu: const [
      FoodItem(id: 'u1f1', name: 'Nasi + Ayam Goreng', description: 'Nasi putih dengan ayam goreng bumbu kuning gurih', price: 18000, emoji: '🍗', category: 'Makanan Berat', isBestSeller: true),
      FoodItem(id: 'u1f2', name: 'Nasi + Ikan Asin', description: 'Ikan asin goreng renyah dengan sambal terasi', price: 13000, emoji: '🐟', category: 'Makanan Berat'),
      FoodItem(id: 'u1f3', name: 'Sayur Asem', description: 'Sayur asem segar dengan aneka sayuran pilihan', price: 8000, emoji: '🥬', category: 'Sayuran'),
      FoodItem(id: 'u1f4', name: 'Tempe Orek', description: 'Tempe manis pedas digoreng kering', price: 7000, emoji: '🟫', category: 'Sayuran', isBestSeller: true),
      FoodItem(id: 'u1f5', name: 'Es Teh Manis', description: 'Teh manis dingin segar', price: 5000, emoji: '🧋', category: 'Minuman'),
    ],
  ),
  Umkm(
    id: 'u2',
    name: 'Warkop Pinggir',
    phone: '082134567890',
    address: 'Jl. HR Rasuna Said Kav.1, Kuningan',
    emoji: '☕',
    tag: 'Kopi & gorengan • Buka 24 jam',
    location: const LatLng(-6.2155, 106.8310),
    menu: const [
      FoodItem(id: 'u2f1', name: 'Kopi Tubruk', description: 'Kopi hitam robusta tubruk asli, kuat dan harum', price: 8000, emoji: '☕', category: 'Minuman', isBestSeller: true),
      FoodItem(id: 'u2f2', name: 'Teh Tarik', description: 'Teh susu kental manis ditarik ala mamak', price: 10000, emoji: '🍵', category: 'Minuman'),
      FoodItem(id: 'u2f3', name: 'Roti Bakar Coklat', description: 'Roti bakar dengan selai coklat keju yang lumer', price: 12000, emoji: '🍞', category: 'Cemilan', isBestSeller: true),
      FoodItem(id: 'u2f4', name: 'Pisang Goreng', description: 'Pisang kepok goreng garing dengan taburan gula', price: 10000, emoji: '🍌', category: 'Cemilan'),
      FoodItem(id: 'u2f5', name: 'Indomie Rebus Telur', description: 'Indomie rebus dengan telur dan daun bawang', price: 13000, emoji: '🍜', category: 'Makanan Berat'),
    ],
  ),
  Umkm(
    id: 'u3',
    name: 'Nasi Goreng Gila',
    phone: '085298765432',
    address: 'Jl. Gatot Subroto No.55, Menteng Atas',
    emoji: '🍳',
    tag: 'Nasi goreng ekstrem • 5 level pedas',
    location: const LatLng(-6.2203, 106.8198),
    menu: const [
      FoodItem(id: 'u3f1', name: 'Nasgor Gila Original', description: 'Nasi goreng spesial dengan sosis, bakso, dan telur ceplok', price: 25000, emoji: '🍳', category: 'Nasi Goreng', isBestSeller: true),
      FoodItem(id: 'u3f2', name: 'Nasgor Seafood', description: 'Nasi goreng dengan udang, cumi, dan kerang segar', price: 32000, emoji: '🦐', category: 'Nasi Goreng', isBestSeller: true),
      FoodItem(id: 'u3f3', name: 'Nasgor Kambing', description: 'Nasi goreng kambing dengan rempah khas arab', price: 35000, emoji: '🐑', category: 'Nasi Goreng'),
      FoodItem(id: 'u3f4', name: 'Mie Goreng Gila', description: 'Mie goreng topping lengkap, level pedas pilihan', price: 23000, emoji: '🍜', category: 'Mie Goreng'),
      FoodItem(id: 'u3f5', name: 'Es Jeruk Segar', description: 'Jeruk peras langsung dengan es batu melimpah', price: 8000, emoji: '🍊', category: 'Minuman'),
    ],
  ),
  Umkm(
    id: 'u4',
    name: 'Pempek Palembang',
    phone: '081356789012',
    address: 'Jl. Setiabudi Selatan No.7, Setiabudi',
    emoji: '🐠',
    tag: 'Pempek asli Palembang • Cuko original',
    location: const LatLng(-6.2120, 106.8245),
    menu: const [
      FoodItem(id: 'u4f1', name: 'Pempek Kapal Selam', description: 'Pempek besar isi telur ayam, digoreng dengan cuko pedas manis', price: 15000, emoji: '🐠', category: 'Pempek', isBestSeller: true),
      FoodItem(id: 'u4f2', name: 'Pempek Lenjer', description: 'Pempek ikan tenggiri asli, kenyal dan gurih', price: 10000, emoji: '🐟', category: 'Pempek', isBestSeller: true),
      FoodItem(id: 'u4f3', name: 'Pempek Adaan', description: 'Pempek bulat kecil dengan bumbu bawang putih dan kucai', price: 8000, emoji: '⚪', category: 'Pempek'),
      FoodItem(id: 'u4f4', name: 'Tekwan', description: 'Sup ikan dengan bihun, jamur kuping, dan ebi harum', price: 18000, emoji: '🍲', category: 'Berkuah'),
      FoodItem(id: 'u4f5', name: 'Es Kacang Merah', description: 'Es serut dengan kacang merah dan sirup merah segar', price: 12000, emoji: '🧊', category: 'Minuman'),
    ],
  ),
  Umkm(
    id: 'u5',
    name: 'Bubur Cianjur',
    phone: '089612345678',
    address: 'Jl. Imam Bonjol No.3, Menteng',
    emoji: '🥣',
    tag: 'Bubur ayam otentik • Buka pagi',
    location: const LatLng(-6.1998, 106.8320),
    menu: const [
      FoodItem(id: 'u5f1', name: 'Bubur Ayam Komplit', description: 'Bubur lembut dengan ayam suwir, cakwe, kerupuk, dan kecap', price: 18000, emoji: '🥣', category: 'Bubur', isBestSeller: true),
      FoodItem(id: 'u5f2', name: 'Bubur Ayam Spesial', description: 'Bubur komplit ditambah telur pindang dan hati ampela', price: 23000, emoji: '🍳', category: 'Bubur', isBestSeller: true),
      FoodItem(id: 'u5f3', name: 'Bubur Polos', description: 'Bubur putih panas dengan bawang goreng dan kecap', price: 12000, emoji: '⚪', category: 'Bubur'),
      FoodItem(id: 'u5f4', name: 'Lontong Sayur', description: 'Lontong dengan sayur lodeh dan serundeng kelapa', price: 15000, emoji: '🍱', category: 'Makanan Berat'),
      FoodItem(id: 'u5f5', name: 'Teh Hangat', description: 'Teh panas manis untuk menemani bubur pagi', price: 5000, emoji: '🍵', category: 'Minuman'),
    ],
  ),
];

// ══════════════════════════════════════════════════════════════
//  HELPER
// ══════════════════════════════════════════════════════════════

double _haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  final dLat = _deg2rad(b.lat - a.lat);
  final dLng = _deg2rad(b.lng - a.lng);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(a.lat)) *
          math.cos(_deg2rad(b.lat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _deg2rad(double deg) => deg * math.pi / 180;

Future<void> _launchUrl(BuildContext context, String url) async {
  // TODO: Ganti dengan:
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
   throw Exception('Tidak bisa membuka $url');
   }
  debugPrint('Launch: $url'); 
}

String _fmt(double price) => price
    .toStringAsFixed(0)
    .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

// ══════════════════════════════════════════════════════════════
//  TEMA WARNA
// ══════════════════════════════════════════════════════════════

class _C {
  static const primary   = Color(0xFFFF6B35);
  static const secondary = Color(0xFF2EC4B6);
  static const gold      = Color(0xFFFFB703);
  static const bg        = Color(0xFFFFF8F5);
  static const dark      = Color(0xFF1A1A2E);
  static const muted     = Color(0xFF8E8E9A);
  static const wa        = Color(0xFF25D366);
}

// ══════════════════════════════════════════════════════════════
//  HALAMAN UTAMA — Daftar UMKM
// ══════════════════════════════════════════════════════════════

class EcomercePage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const EcomercePage({super.key, this.onBackToHome});

  @override
  State<EcomercePage> createState() => _EcomercePageState();
}

class _EcomercePageState extends State<EcomercePage> {
  LatLng _userLoc = const LatLng(-6.2088, 106.8228); // default: Setiabudi
  bool _locating = false;
  bool _locGranted = false;
  String _sortMode = 'Terdekat';
  late List<Umkm> _sorted;

  @override
  void initState() {
    super.initState();
    _computeAndSort();
  }

  void _computeAndSort() {
    for (final u in _allUmkm) {
      u.distanceKm = _haversineKm(_userLoc, u.location);
    }
    _sorted = List.from(_allUmkm);
    _applySort();
  }

  void _applySort() {
    setState(() {
      if (_sortMode == 'Terdekat') {
        _sorted.sort(
            (a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
      } else {
        _sorted.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);

    // TODO: Ganti blok ini dengan geolocator asli:
     bool svcEnabled = await Geolocator.isLocationServiceEnabled();
     if (!svcEnabled) { setState(() => _locating = false); return; }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) { setState(() => _locating = false); return; }
     }
     Position pos = await Geolocator.getCurrentPosition();
     _userLoc = LatLng(pos.latitude, pos.longitude);

    // Simulasi delay (hapus saat pakai geolocator asli):
    await Future.delayed(const Duration(milliseconds: 1400));
    _userLoc = const LatLng(-6.2100, 106.8240);

    setState(() {
      _locGranted = true;
      _locating = false;
    });
    _computeAndSort();
  }

  void _openUmkm(Umkm umkm) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _UmkmDetailPage(umkm: umkm)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Dekorasi
          Positioned(top: -50, right: -30,
              child: _circle(180, _C.primary.withOpacity(0.07))),
          Positioned(top: 130, left: -20,
              child: _circle(110, _C.secondary.withOpacity(0.06))),

          CustomScrollView(
            slivers: [
              // ── APP BAR ──
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: _C.bg,
                elevation: 0,
                leading: widget.onBackToHome != null
                    ? IconButton(
                        icon: _iconBox(Icons.arrow_back_ios_new, 16),
                        onPressed: widget.onBackToHome)
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 76, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill('🍽️  HaiTime Food', _C.primary),
                        const SizedBox(height: 6),
                        const Text('UMKM Sekitarmu',
                            style: TextStyle(
                                color: _C.dark,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),

              // ── BANNER LOKASI ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: _locating ? null : _detectLocation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _locGranted
                              ? [_C.secondary.withOpacity(0.11),
                                 _C.secondary.withOpacity(0.05)]
                              : [_C.primary.withOpacity(0.09),
                                 _C.gold.withOpacity(0.07)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _locGranted
                              ? _C.secondary.withOpacity(0.25)
                              : _C.primary.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)),
                            child: _locating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _C.primary))
                                : Icon(
                                    _locGranted
                                        ? Icons.my_location
                                        : Icons.location_searching,
                                    color: _locGranted
                                        ? _C.secondary
                                        : _C.primary,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locGranted
                                      ? 'Lokasi terdeteksi ✓'
                                      : 'Aktifkan lokasi',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _C.dark),
                                ),
                                Text(
                                  _locGranted
                                      ? 'Setiabudi, Jakarta Selatan'
                                      : 'Tap untuk urut UMKM terdekat',
                                  style: const TextStyle(
                                      color: _C.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!_locGranted && !_locating)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: _C.primary,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text('Aktifkan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── SORT BAR ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text('${_sorted.length} warung ditemukan',
                          style: const TextStyle(
                              color: _C.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Terdekat', 'Nama'].map((mode) {
                            final active = _sortMode == mode;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _sortMode = mode);
                                _applySort();
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active
                                      ? _C.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      mode == 'Terdekat'
                                          ? Icons.near_me
                                          : Icons.sort_by_alpha,
                                      size: 13,
                                      color: active
                                          ? Colors.white
                                          : _C.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(mode,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: active
                                                ? Colors.white
                                                : _C.muted)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── LIST UMKM ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _UmkmCard(
                      umkm: _sorted[i],
                      rank: _sortMode == 'Terdekat' ? i + 1 : null,
                      onTap: () => _openUmkm(_sorted[i]),
                    ),
                    childCount: _sorted.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double s, Color c) => Container(
      width: s, height: s,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  Widget _iconBox(IconData icon, double size) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8)
          ],
        ),
        child: Icon(icon, size: size, color: _C.dark),
      );

  Widget _pill(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

// ══════════════════════════════════════════════════════════════
//  KARTU UMKM
// ══════════════════════════════════════════════════════════════

class _UmkmCard extends StatelessWidget {
  final Umkm umkm;
  final int? rank;
  final VoidCallback onTap;

  const _UmkmCard(
      {required this.umkm, this.rank, required this.onTap});

  String get _distLabel {
    final d = umkm.distanceKm;
    if (d == null) return '';
    return d < 1 ? '${(d * 1000).round()} m' : '${d.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isFirst
              ? Border.all(
                  color: _C.primary.withOpacity(0.35), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isFirst
                  ? _C.primary.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon + badge ranking
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                        child: Text(umkm.emoji,
                            style: const TextStyle(fontSize: 32))),
                  ),
                  if (rank != null)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isFirst ? _C.gold : _C.muted,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text('$rank',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(umkm.name,
                              style: const TextStyle(
                                  color: _C.dark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: _C.primary,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('Terdekat',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(umkm.tag,
                        style: const TextStyle(
                            color: _C.muted, fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: _C.muted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(umkm.address,
                              style: const TextStyle(
                                  color: _C.muted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (umkm.distanceKm != null)
                          _chip(Icons.near_me, _distLabel,
                              _C.secondary.withOpacity(0.12), _C.secondary),
                        const SizedBox(width: 6),
                        _chip(Icons.restaurant_menu,
                            '${umkm.menu.length} menu',
                            _C.primary.withOpacity(0.10), _C.primary),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              color: _C.primary,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('Lihat Menu',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  HALAMAN DETAIL UMKM
// ══════════════════════════════════════════════════════════════

class _UmkmDetailPage extends StatefulWidget {
  final Umkm umkm;
  const _UmkmDetailPage({required this.umkm});

  @override
  State<_UmkmDetailPage> createState() => _UmkmDetailPageState();
}

class _UmkmDetailPageState extends State<_UmkmDetailPage>
    with SingleTickerProviderStateMixin {
  final Map<String, CartItem> _cart = {};
  String _selectedCat = 'Semua';
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeAnim;

  List<String> get _cats {
    final c = widget.umkm.menu.map((f) => f.category).toSet().toList();
    return ['Semua', ...c];
  }

  List<FoodItem> get _filtered => _selectedCat == 'Semua'
      ? widget.umkm.menu
      : widget.umkm.menu.where((f) => f.category == _selectedCat).toList();

  int get _totalItems =>
      _cart.values.fold(0, (s, i) => s + i.quantity);
  double get _totalPrice =>
      _cart.values.fold(0.0, (s, i) => s + i.subtotal);

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _badgeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  void _add(FoodItem f) {
    setState(() {
      if (_cart.containsKey(f.id)) {
        _cart[f.id]!.quantity++;
      } else {
        _cart[f.id] = CartItem(food: f);
      }
    });
    _badgeCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _remove(FoodItem f) {
    setState(() {
      if (_cart.containsKey(f.id)) {
        if (_cart[f.id]!.quantity <= 1) {
          _cart.remove(f.id);
        } else {
          _cart[f.id]!.quantity--;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  int _qty(String id) => _cart[id]?.quantity ?? 0;

  String _buildWaMsg() {
    final b = StringBuffer();
    b.writeln('Halo *${widget.umkm.name}*, saya ingin memesan 🍽️');
    b.writeln('');
    b.writeln('*Detail Pesanan:*');
    for (final item in _cart.values) {
      b.writeln(
          '• ${item.food.name} x${item.quantity} = Rp ${_fmt(item.subtotal)}');
    }
    b.writeln('');
    b.writeln('*Total: Rp ${_fmt(_totalPrice)}*');
    b.writeln('');
    b.writeln('Mohon konfirmasi. Terima kasih! 🙏');
    return Uri.encodeComponent(b.toString());
  }

  Future<void> _openWa() async {
    if (_cart.isEmpty) {
      _snack('Pilih menu terlebih dahulu', isError: true);
      return;
    }
    final phone = widget.umkm.phone.replaceAll(RegExp(r'^0'), '62');
    final url = 'https://wa.me/$phone?text=${_buildWaMsg()}';
    await _launchUrl(context, url);
    if (mounted) _showWaDialog(url);
  }

  Future<void> _callPhone() async {
    await _launchUrl(context, 'tel:${widget.umkm.phone}');
    _snack('Menghubungi ${widget.umkm.phone}...');
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : _C.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showWaDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Text('💬 ', style: TextStyle(fontSize: 22)),
          Text('WhatsApp', style: TextStyle(fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'membuka WhatsApp otomatis.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10)),
              child: SelectableText(
                'Nomor: ${widget.umkm.phone}',
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.wa,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.umkm.phone));
              Navigator.pop(ctx);
              _snack('Nomor disalin!');
            },
            child: const Text('Salin Nomor'),
          ),
        ],
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart: _cart,
        totalPrice: _totalPrice,
        umkmName: widget.umkm.name,
        onAdd: _add,
        onRemove: _remove,
        onWa: _openWa,
        onCall: _callPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── AppBar ──
              SliverAppBar(
                pinned: true,
                backgroundColor: _C.bg,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: _C.dark),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.phone,
                          size: 18, color: _C.secondary),
                    ),
                    onPressed: _callPhone,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: _showCart,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Icon(
                                Icons.shopping_basket_rounded,
                                size: 20,
                                color: _C.primary),
                          ),
                          if (_totalItems > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: ScaleTransition(
                                scale: _badgeAnim,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _C.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text('$_totalItems',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
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

              // ── Header UMKM ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      // Info toko
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _C.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                  child: Text(widget.umkm.emoji,
                                      style: const TextStyle(
                                          fontSize: 28))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(widget.umkm.name,
                                      style: const TextStyle(
                                          color: _C.dark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text(widget.umkm.tag,
                                      style: const TextStyle(
                                          color: _C.muted, fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: _C.muted),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(widget.umkm.address,
                                            style: const TextStyle(
                                                color: _C.muted,
                                                fontSize: 11),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Banner kontak
                      _ContactBanner(
                        phone: widget.umkm.phone,
                        onWa: _openWa,
                        onCall: _callPhone,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Kategori ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: _cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = _cats[i];
                      final sel = cat == _selectedCat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCat = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? _C.primary : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: sel
                                    ? _C.primary.withOpacity(0.28)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 7,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: sel ? Colors.white : _C.muted,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Daftar menu ──
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final food = _filtered[i];
                      return _FoodCard(
                        food: food,
                        quantity: _qty(food.id),
                        onAdd: () => _add(food),
                        onRemove: () => _remove(food),
                      );
                    },
                    childCount: _filtered.length,
                  ),
                ),
              ),
            ],
          ),

          // Bottom bar
          if (_totalItems > 0)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _CartBar(
                totalItems: _totalItems,
                totalPrice: _totalPrice,
                onTap: _showCart,
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGET: KONTAK BANNER
// ══════════════════════════════════════════════════════════════

class _ContactBanner extends StatelessWidget {
  final String phone;
  final VoidCallback onWa, onCall;

  const _ContactBanner(
      {required this.phone, required this.onWa, required this.onCall});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.primary.withOpacity(0.07),
              _C.secondary.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary.withOpacity(0.13)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('📞', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hubungi Penjual',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _C.dark)),
                  Text(phone,
                      style: const TextStyle(
                          color: _C.muted, fontSize: 11)),
                ],
              ),
            ),
            _Btn('💬', 'WA', _C.wa, onWa),
            const SizedBox(width: 6),
            _Btn('📱', 'Telp', _C.secondary, onCall),
          ],
        ),
      );
}

class _Btn extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(9)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  WIDGET: KARTU MENU
// ══════════════════════════════════════════════════════════════

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final int quantity;
  final VoidCallback onAdd, onRemove;

  const _FoodCard({
    required this.food,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(food.emoji,
                          style: const TextStyle(fontSize: 32))),
                ),
                if (food.isBestSeller)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: _C.gold,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('⭐',
                          style: TextStyle(fontSize: 9)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style: const TextStyle(
                          color: _C.dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(food.description,
                      style: const TextStyle(
                          color: _C.muted, fontSize: 11.5, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rp ${_fmt(food.price)}',
                          style: const TextStyle(
                              color: _C.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const Spacer(),
                      if (quantity == 0)
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                                color: _C.primary,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('+ Tambah',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                              color: _C.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QBtn(Icons.remove, onRemove),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text('$quantity',
                                    style: const TextStyle(
                                        color: _C.dark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ),
                              _QBtn(Icons.add, onAdd),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  WIDGET: BOTTOM BAR KERANJANG
// ══════════════════════════════════════════════════════════════

class _CartBar extends StatelessWidget {
  final int totalItems;
  final double totalPrice;
  final VoidCallback onTap;

  const _CartBar(
      {required this.totalItems,
      required this.totalPrice,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, -4))
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _C.primary.withOpacity(0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$totalItems item',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                const Text('Lihat Keranjang',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const Spacer(),
                Text('Rp ${_fmt(totalPrice)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  WIDGET: CART BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _CartSheet extends StatelessWidget {
  final Map<String, CartItem> cart;
  final double totalPrice;
  final String umkmName;
  final void Function(FoodItem) onAdd, onRemove;
  final VoidCallback onWa, onCall;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.umkmName,
    required this.onAdd,
    required this.onRemove,
    required this.onWa,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final items = cart.values.toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      maxChildSize: 0.92,
      minChildSize: 0.38,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.shopping_basket_rounded,
                      color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Keranjang — $umkmName',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🛒', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 10),
                          Text('Keranjang kosong',
                              style: TextStyle(
                                  color: _C.muted, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: Center(
                                    child: Text(item.food.emoji,
                                        style: const TextStyle(
                                            fontSize: 20))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.food.name,
                                        style: const TextStyle(
                                            color: _C.dark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
                                    Text(
                                        'Rp ${_fmt(item.food.price)}',
                                        style: const TextStyle(
                                            color: _C.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _QBtn(Icons.remove,
                                      () => onRemove(item.food)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            color: _C.dark,
                                            fontWeight:
                                                FontWeight.w800)),
                                  ),
                                  _QBtn(Icons.add,
                                      () => onAdd(item.food)),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Text('Rp ${_fmt(item.subtotal)}',
                                  style: const TextStyle(
                                      color: _C.dark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                color: _C.dark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const Spacer(),
                        Text('Rp ${_fmt(totalPrice)}',
                            style: const TextStyle(
                                color: _C.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onCall,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _C.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color: _C.secondary.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.phone,
                                color: _C.secondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: onWa,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: _C.wa,
                                borderRadius:
                                    BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: _C.wa.withOpacity(0.32),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('💬',
                                      style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('Pesan via WhatsApp',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}