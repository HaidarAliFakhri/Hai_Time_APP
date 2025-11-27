import 'package:flutter/material.dart';

import '../page/home_page_firebase.dart';

PreferredSizeWidget buildCustomAppBar(
  BuildContext context, {
  required String title,
  bool showBack = true,
}) {
  return PreferredSize(
    // Naikkan tinggi appbar supaya gelombang lebih tinggi dan teks tidak terpotong
    preferredSize: const Size.fromHeight(160),
    child: ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        // Tambah padding top supaya judul tidak "tersumbat" di notch
        padding: const EdgeInsets.only(top: 20, bottom: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // === BACK BUTTON ===
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomePageFirebase(),
                          ),
                        );
                      }
                    },
                  )
                else
                  const SizedBox(width: 48), // balance agar judul tetap center
                // === TITLE CENTER ===
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Spacer untuk menjaga alignment kanan
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Turunkan sedikit → 18 pixel
    path.lineTo(0, size.height - 29);

    // Gelombang 1 (lebih kecil & smooth)
    final firstControlPoint = Offset(size.width * 0.25, size.height + 10);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 12);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Gelombang 2 (lebih kecil & rapih)
    final secondControlPoint = Offset(size.width * 0.75, size.height - 55);
    final secondEndPoint = Offset(size.width, size.height - 18);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
