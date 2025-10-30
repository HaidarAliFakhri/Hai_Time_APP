import 'package:flutter/material.dart';
import 'package:hai_time_app/db/db_helper.dart';
import 'package:hai_time_app/model/participant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _cityC = TextEditingController();
  final _passwordC = TextEditingController();

  bool _isSaving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _cityC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final participant = Participant(
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      city: _cityC.text.trim(),
      password: _passwordC.text.trim(),
    );

    try {
      await DBHelperTime().insertParticipant(participant);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registered_email', _emailC.text.trim());
      await prefs.setString('registered_password', _passwordC.text.trim());
      await prefs.setString('registered_name', _nameC.text.trim());
      await prefs.setString('registered_phone', _phoneC.text.trim());
      await prefs.setString('registered_city', _cityC.text.trim());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pendaftaran berhasil!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // biru muda
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kembali',
          style: TextStyle(color: Colors.blue, fontSize: 16),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🔹 Logo jam di atas
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Daftar Akun Baru",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Mulai atur waktu Anda lebih baik",
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 30),

                // 🔹 Input Username
                _buildTextField(
                  controller: _nameC,
                  label: 'Username',
                  hint: 'username',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                ),

                const SizedBox(height: 16),

                // 🔹 Input Email
                _buildTextField(
                  controller: _emailC,
                  label: 'Email',
                  hint: 'nama@email.com',
                  icon: Icons.email_outlined,
                  validator: (v) {
                    if (v!.isEmpty) return 'Email wajib diisi';
                    final regex = RegExp(
                      r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
                    );
                    return !regex.hasMatch(v) ? 'Format email salah' : null;
                  },
                ),

                const SizedBox(height: 16),

                // 🔹 Password
                _buildTextField(
                  controller: _passwordC,
                  label: 'Password',
                  hint: '********',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blue,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 🔹 Konfirmasi Password
                _buildTextField(
                  label: 'Konfirmasi Password',
                  hint: '********',
                  icon: Icons.lock_outline,
                  obscure: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Konfirmasi wajib diisi';
                    if (v != _passwordC.text) return 'Password tidak sama';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 🔹 Tombol daftar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Link login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sudah punya akun? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Masuk di sini",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Widget Reusable TextField
  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: suffix,
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
