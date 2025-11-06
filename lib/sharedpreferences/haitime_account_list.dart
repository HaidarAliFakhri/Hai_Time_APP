import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DaftarAkunHaitime extends StatefulWidget {
  const DaftarAkunHaitime({super.key});

  @override
  State<DaftarAkunHaitime> createState() => _DaftarAkunHaitimeState();
}

class _DaftarAkunHaitimeState extends State<DaftarAkunHaitime> {
  String? _email;
  String? _password;
  bool _obscure = true; // kontrol show/hide password

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('registered_email');
      _password = prefs.getString('registered_password');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF8),
      appBar: AppBar(
        title: const Text("Daftar User"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: _email == null
          ? const Center(
              child: Text(
                "Belum ada akun terdaftar.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(
                            "assets/images/logo/logo_app.png",
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Akun HaiTime",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _infoTile("Email", _email ?? "-"),
                      const SizedBox(height: 12),
                      _passwordTile(),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('registered_email');
                            await prefs.remove('registered_password');
                            setState(() {
                              _email = null;
                              _password = null;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Akun dihapus!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text(
                            "Hapus Akun",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.email, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text("$title: $value", style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _passwordTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _obscure
                  ? "Password: ${'*' * (_password?.length ?? 0)}"
                  : "Password: $_password",
              style: const TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade700,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ],
      ),
    );
  }
}
