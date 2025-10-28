import 'package:flutter/material.dart';
import 'package:hai_time_app/page/home_page.dart';
import 'package:hai_time_app/page/login_page.dart';

// Variabel global agar tema bisa digunakan lintas halaman
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isAutoLocation = true;
  bool isPushNotif = true;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkMode.value;
    final Color textColor = dark ? Colors.white : Colors.black87;
    final Color cardColor = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color bgColor = dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F6FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Pengaturan", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
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
            _buildSectionTitle("Tampilan", textColor),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ValueListenableBuilder(
                valueListenable: isDarkMode,
                builder: (context, value, _) {
                  return SwitchListTile(
                    title: Text(
                      "Mode Gelap",
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      "Aktifkan tema gelap",
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    value: value,
                    onChanged: (val) {
                      isDarkMode.value = val;
                      setState(() {});
                    },
                    secondary: const Icon(Icons.dark_mode, color: Colors.blue),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Lokasi & Waktu", textColor),
            _buildSwitchTile(
              Icons.location_on,
              "Lokasi Otomatis",
              "Jakarta, Indonesia",
              isAutoLocation,
              (v) => setState(() => isAutoLocation = v),
              cardColor,
              textColor,
            ),
            _buildNavTile(
              Icons.access_time,
              "Zona Waktu",
              "WIB (GMT+7)",
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
              (v) => setState(() => isPushNotif = v),
              cardColor,
              textColor,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Bahasa", textColor),
            _buildNavTile(
              Icons.language,
              "Bahasa Aplikasi",
              "Bahasa Indonesia",
              cardColor,
              textColor,
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Tentang", textColor),
            _buildInfoTile("Versi Aplikasi", "1.0.0", cardColor, textColor),
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
                      content: const Text("Yakin ingin keluar dari HaiTrip?"),
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
                        builder: (context) =>
                            const LoginPage(), // kembali ke login
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
    Color textColor,
  ) {
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
      ),
    );
  }

  Widget _buildNavTile(
    IconData icon,
    String title,
    String? subtitle,
    Color cardColor,
    Color textColor,
  ) {
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
        onTap: () {},
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
