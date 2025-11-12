import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_time_app/page/bottom_navigator.dart';
import 'package:hai_time_app/page/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔹 Notifier global untuk tema gelap
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

class SettingPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  const SettingPage({super.key, required this.onLanguageChanged});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String selectedLanguage = "Bahasa Indonesia";
  bool isAutoLocation = true;
  bool isPushNotif = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String _currentLocation = "Jakarta, Indonesia";
  String _timezone = "";

  @override
  void initState() {
    _loadLanguagePreference();
    super.initState();
    _initNotifications();
    _loadPreferences();
    _getTimeZone();
    if (isAutoLocation) {
      _getCurrentLocation();
    }
  }

  Future<void> _saveLanguagePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage =
          prefs.getString('selectedLanguage') ?? "Bahasa Indonesia";
    });
  }

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'adzan_channel',
          'Notifikasi Adzan',
          channelDescription: 'Pengingat waktu sholat',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails notifDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'HaiTime',
      'Contoh notifikasi aktif!',
      notifDetails,
    );
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPushNotif = prefs.getBool('isPushNotif') ?? true;
    });
  }

  Future<void> _savePreferences(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPushNotif', value);
  }

  // 🔹 Fungsi ambil lokasi otomatis
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(
        title: "Layanan Lokasi Tidak Aktif",
        message: "Aktifkan GPS agar aplikasi bisa mendeteksi lokasi kamu.",
        openSettings: true,
      );
      setState(() => _currentLocation = "Layanan lokasi tidak aktif");
      return;
    }

    // Cek dan minta izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog(
          title: "Izin Lokasi Ditolak",
          message:
              "Aplikasi memerlukan izin lokasi untuk menampilkan lokasi otomatis.",
        );
        setState(() => _currentLocation = "Izin lokasi ditolak");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
        title: "Izin Lokasi Ditolak Permanen",
        message: "Buka pengaturan untuk mengaktifkan izin lokasi.",
        openSettings: true,
      );
      setState(() => _currentLocation = "Izin lokasi permanen ditolak");
      return;
    }

    // Jika sudah diizinkan
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;
    setState(() {
      _currentLocation = "${place.locality}, ${place.country}";
    });
  }

  Future<void> _openInGoogleMaps() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final Uri uri = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}",
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat membuka Google Maps")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka peta: $e")));
    }
  }

  void _getTimeZone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? "-" : "+";
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    _timezone = "GMT$sign$hours";
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  AppLocalizations.of(context).translate('choose_language'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: const Text("Bahasa Indonesia"),
                trailing: selectedLanguage == "Bahasa Indonesia"
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => selectedLanguage = "Bahasa Indonesia");
                  _saveLanguagePreference("Bahasa Indonesia");
                  widget.onLanguageChanged(const Locale('id'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('language_set_to_indonesia'),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: const Text("English"),
                trailing: selectedLanguage == "English"
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => selectedLanguage = "English");
                  _saveLanguagePreference("English");
                  widget.onLanguageChanged(const Locale('en'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('language_set_to_english'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Dialog Peringatan Lokasi
  void _showLocationDialog({
    required String title,
    required String message,
    bool openSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Tutup"),
            onPressed: () => Navigator.pop(context),
          ),
          if (openSettings)
            TextButton(
              child: const Text("Buka Pengaturan"),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkMode.value;
    final Color textColor = dark ? Colors.white : Colors.black87;
    final Color cardColor = dark ? const Color(0xFF1E1E1E) : Colors.white;
    //final Color bgColor = dark
    //? const Color(0xFF121212);
    // : const Color(0xFFF2F6FC);

    return Scaffold(
      // backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Pengaturan", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavigator()),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAEFE), Color(0xFF007BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSectionTitle("Tampilan", textColor),

            // Card(
            //   color: cardColor,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: ValueListenableBuilder(
            //     valueListenable: isDarkMode,
            //     builder: (context, value, _) {
            //       return SwitchListTile(
            //         title: Text(
            //           "Mode Gelap",
            //           style: TextStyle(color: textColor),
            //         ),
            //         subtitle: Text(
            //           "Aktifkan tema gelap",
            //           style: TextStyle(color: textColor.withOpacity(0.7)),
            //         ),
            //         value: value,
            //         onChanged: (val) {
            //           isDarkMode.value = val;
            //           setState(() {});
            //         },
            //         secondary: const Icon(Icons.dark_mode, color: Colors.blue),
            //       );
            //     },
            //   ),
            // ),
            const SizedBox(height: 16),
            _buildSectionTitle("Lokasi & Waktu", textColor),

            _buildSwitchTile(
              Icons.location_on,
              "Lokasi Otomatis",
              _currentLocation,
              isAutoLocation,
              (v) {
                setState(() {
                  isAutoLocation = v;
                });
                if (v) _getCurrentLocation();
              },
              cardColor,
              textColor,
              onTap: _openInGoogleMaps, // 🔹 Tambahan
            ),

            _buildNavTile(
              Icons.access_time,
              "Zona Waktu",
              "WIB ($_timezone)",
              cardColor,
              textColor,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Notifikasi", textColor),
            _buildSwitchTile(
              Icons.notifications,
              "Notifikasi Push",
              "Pengingat kegiatan & sholat",
              isPushNotif,
              (v) async {
                setState(() => isPushNotif = v);
                await _savePreferences(v);

                if (v) {
                  // Aktifkan (bisa langsung uji coba)
                  await _showTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notifikasi diaktifkan")),
                  );
                } else {
                  // Nonaktifkan
                  await flutterLocalNotificationsPlugin.cancelAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notifikasi dimatikan")),
                  );
                }
              },
              cardColor,
              textColor,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Bahasa", textColor),
            _buildNavTile(
              Icons.language,
              "Bahasa Aplikasi",
              selectedLanguage, // 🔹 Tampilkan bahasa yang dipilih
              cardColor,
              textColor,
              onTap: _showLanguageBottomSheet, // 🔹 Tambahkan aksi klik
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Tentang", textColor),
            _buildInfoTile("Versi Aplikasi", "1.0.3", cardColor, textColor),
            _buildNavTile(
              Icons.article,
              "Syarat & Ketentuan",
              null,
              cardColor,
              textColor,
            ),
            _buildNavTile(
              Icons.privacy_tip,
              "Kebijakan Privasi",
              null,
              cardColor,
              textColor,
            ),

            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: const Text("Yakin ingin keluar dari HaiTime?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Keluar dari Akun",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget pendukung
  Widget _buildSectionTitle(String title, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 16,
      ),
    ),
  );

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color cardColor,
    Color textColor, {
    VoidCallback? onTap, // 🔹 Tambahan opsional
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: onTap, // 🔹 Tambahan agar bisa ditekan
      ),
    );
  }

  Widget _buildNavTile(
    IconData icon,
    String title,
    String? subtitle,
    Color cardColor,
    Color textColor, {
    VoidCallback? onTap, // ✅ jadikan named argument opsional
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: textColor.withOpacity(0.7)),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: TextStyle(color: textColor)),
        trailing: Text(value, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
