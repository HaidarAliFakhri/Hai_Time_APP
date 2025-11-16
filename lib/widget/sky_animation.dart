import 'package:flutter/material.dart';
import 'package:hai_time_app/page/home_page.dart';


class SkyAnimation extends StatefulWidget {
  final SkyTime time;

  const SkyAnimation({super.key, required this.time});

  @override
  State<SkyAnimation> createState() => _SkyAnimationState();
}

class _SkyAnimationState extends State<SkyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final skyColors = _getSkyGradient(widget.time);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: skyColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // 🌞 Matahari (hanya muncul Subuh–Ashar)
              if (widget.time == SkyTime.subuh ||
                  widget.time == SkyTime.dzuhur ||
                  widget.time == SkyTime.ashar)
                Positioned(
                  top: 40 + controller.value * 40,
                  left: 80 + controller.value * 30,
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 70,
                    color: Colors.yellow.withOpacity(0.85),
                  ),
                ),

              // 🌙 Bulan muncul saat Isya
              if (widget.time == SkyTime.isya)
                Positioned(
                  top: 40 + controller.value * 20,
                  right: 60,
                  child: Icon(
                    Icons.brightness_3_rounded,
                    size: 70,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),

              // ✨ Bintang – hanya malam
              if (widget.time == SkyTime.isya)
                _buildStars(),

              // ☁️ Awan bergerak
              Positioned(
                top: 30,
                left: -80 + controller.value * 250,
                child: Icon(
                  Icons.cloud,
                  size: 90,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStars() {
    return Opacity(
      opacity: 0.6 + (controller.value * 0.3),
      child: Stack(
        children: List.generate(
          20,
          (i) => Positioned(
            top: (i * 12) % 180,
            left: (i * 23) % 250,
            child: Icon(
              Icons.star,
              size: 6,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getSkyGradient(SkyTime t) {
    switch (t) {
      case SkyTime.subuh:
        return [const Color(0xFF081830), const Color(0xFF264E94)];
      case SkyTime.dzuhur:
        return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
      case SkyTime.ashar:
        return [const Color(0xFFFFD54F), const Color(0xFFFFA726)];
      case SkyTime.maghrib:
        return [const Color(0xFFFF7043), const Color(0xFF5D4037)];
      case SkyTime.isya:
        return [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
