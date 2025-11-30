import 'package:flutter/material.dart';
import 'package:hai_time_app/page/bottom_navigator_firebase.dart';
import 'package:hai_time_app/page/forget_password_firebase.dart';
import 'package:hai_time_app/page/form_register_firebase.dart';
import 'package:hai_time_app/preferences/preferences_handler.dart';
import 'package:hai_time_app/services/firebase.dart';

class LoginPageFireBase extends StatefulWidget {
  const LoginPageFireBase({super.key});
  static const id = "/HaiTime";

  @override
  State<LoginPageFireBase> createState() => _LoginPageFireBaseState();
}

class _LoginPageFireBaseState extends State<LoginPageFireBase> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isHidden = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final emailInput = emailController.text.trim();
    final passwordInput = passwordController.text.trim();

    //LOGIN ADMIN (tetap sama)
    // if (emailInput == 'admin@haitime.com' && passwordInput == 'admin123') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Login sebagai Admin berhasil!')),
    //   );

    //   await PreferenceHandler.saveLogin(true);
    //   await PreferenceHandler.setEmail(emailInput);

    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (_) => const DashboardAdminPage()),
    //   );
    //   return;
    // }

    //  LOGIN USER FIREBASE
    try {
      final user = await FirebaseService.loginUser(
        email: emailInput,
        password: passwordInput,
      );

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau Kata Sandi salah")),
        );
        return;
      }

      // ✔ simpan sesi login
      await PreferenceHandler.saveLogin(true);
      await PreferenceHandler.setEmail(user.email ?? "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selamat datang, ${user.username}!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavigatorFirebase()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          // Form Login
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo/logo_login.png', height: 190),
                    
                    const Text(
                      "HaiTime",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.85),
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email wajib diisi";
                        }
                        if (!value.contains("@")) {
                          return "Email tidak valid";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: _isHidden,
                      decoration: InputDecoration(
                        hintText: "Kata Sandi",
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.85),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isHidden ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _isHidden = !_isHidden),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password wajib diisi";
                        }
                        if (value.length < 6) {
                          return "Minimal 6 karakter";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lupa Kata Sandi",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F4B7A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          "Masuk",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pembatas
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            indent: 20,
                            endIndent: 10,
                            color: Colors.white70,
                          ),
                        ),
                        // Text(
                        //   "Or continue with",
                        //   style: TextStyle(color: Colors.white70, fontSize: 14),
                        // ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            indent: 10,
                            endIndent: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tombol Sosial Media
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     _socialButton("assets/images/icon/google.jpg"),
                    //     const SizedBox(width: 20),
                    //     _socialButton("assets/images/icon/apple.jpg"),
                    //     const SizedBox(width: 20),
                    //     _socialButton("assets/images/icon/twitter.jpg"),
                    //   ],
                    // ),

                    // Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Belum punya akun? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterPageFireBase(),
                              ),
                            );
                          },
                          child: const Text(
                            "Daftar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tombol sosial media
// Widget _socialButton(String assetPath) {
//   return Container(
//     padding: const EdgeInsets.all(10),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.1),
//           blurRadius: 5,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Image.asset(assetPath, width: 30, height: 30),
//   );
// }
