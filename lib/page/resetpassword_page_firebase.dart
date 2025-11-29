import 'package:flutter/material.dart';
import 'package:hai_time_app/services/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;
  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passC = TextEditingController();
  final TextEditingController _confirmC = TextEditingController();
  bool _loading = false;
  String? _email; // email terverifikasi dari code

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() => _loading = true);
    try {
      final email = await FirebaseService.verifyPasswordResetCode(widget.oobCode);
      setState(() => _email = email);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Kode reset tidak valid")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      Navigator.pop(context);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passC.text != _confirmC.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak cocok")));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseService.confirmPasswordReset(
        oobCode: widget.oobCode,
        newPassword: _passC.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah. Silakan login dengan password baru.")));
      Navigator.pop(context); // kembali ke login
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Gagal mengganti password")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Password Baru")),
      body: _loading && _email == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_email != null) Text("Reset password untuk: $_email"),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passC,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Password baru",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Password wajib diisi";
                            if (v.length < 6) return "Minimal 6 karakter";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmC,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Konfirmasi password",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Konfirmasi password wajib diisi";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submitNewPassword,
                            child: _loading ? const CircularProgressIndicator.adaptive() : const Text("Set Password Baru"),
                          ),
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
