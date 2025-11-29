import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/services/firebase.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailC = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailC.text.trim();
    try {
      await FirebaseService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email reset terkirim ke $email. Cek inbox atau spam.")),
      );
      Navigator.pop(context); // kembali ke login
    } on Exception catch (e) {
      String msg = "Gagal mengirim email reset";
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') msg = "Email tidak terdaftar";
        else if (e.code == 'invalid-email') msg = "Format email tidak valid";
        else msg = e.message ?? msg;
      } else {
        msg = e.toString();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Masukkan email yang terdaftar. Kami akan mengirimkan tautan untuk mereset password.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Email wajib diisi";
                  if (!v.contains('@')) return "Email tidak valid";
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendReset,
                child: _loading ? const CircularProgressIndicator.adaptive() : const Text("Kirim Email Reset"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
