import 'dart:math';
import 'package:flutter/material.dart';

//  Widget utama untuk memilih animasi sesuai kondisi cuaca
class WeatherAnimation extends StatelessWidget {
  final String condition;
  const WeatherAnimation({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    switch (condition.toLowerCase()) {
      case 'hujan':
      case 'rain':
      case 'light rain':
      case 'shower rain':
        return const RainAnimation();

      case 'awan':
      case 'clouds':
      case 'partly cloudy':
        return const CloudAnimation();

      case 'cerah':
      case 'clear':
      case 'sunny':
        return const SunAnimation();

      case 'badai':
      case 'storm':
      case 'thunderstorm':
        return const ThunderstormAnimation();

      case 'salju':
      case 'snow':
        return const SnowAnimation();

      case 'kabut':
      case 'mist':
      case 'fog':
        return const FogAnimation();

      default:
        return const CloudAnimation();
    }
  }
}

//
//  Animasi Hujan
//
class RainAnimation extends StatefulWidget {
  const RainAnimation({super.key});

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _drops = List.generate(
    150,
    (_) => Offset(Random().nextDouble(), Random().nextDouble()),
  );

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _RainPainter(_drops, _controller.value),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final List<Offset> drops;
  final double progress;

  _RainPainter(this.drops, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2;

    for (var drop in drops) {
      final dx = drop.dx * size.width;
      final dy = (drop.dy * size.height + progress * size.height) % size.height;
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy + 10), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

//
//  Animasi Awan
//
class CloudAnimation extends StatefulWidget {
  const CloudAnimation({super.key});

  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<CloudAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              left: _controller.value * MediaQuery.of(context).size.width - 200,
              top: 60,
              child: _cloud(),
            ),
            Positioned(
              left:
                  _controller.value * MediaQuery.of(context).size.width * 1.5 - 200,
              top: 120,
              child: _cloud(),
            ),
          ],
        );
      },
    );
  }

  Widget _cloud() {
    return Opacity(
      opacity: 0.8,
      child: Icon(Icons.cloud, size: 100, color: Colors.white.withOpacity(0.8)),
    );
  }
}

//
//  Animasi Matahari Cerah
//
class SunAnimation extends StatefulWidget {
  const SunAnimation({super.key});

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<SunAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Icon(Icons.wb_sunny,
            color: Colors.yellow.shade300.withOpacity(0.9), size: 120),
      ),
    );
  }
}

//
//  Animasi Petir / Badai
//
class ThunderstormAnimation extends StatefulWidget {
  const ThunderstormAnimation({super.key});

  @override
  State<ThunderstormAnimation> createState() => _ThunderstormAnimationState();
}

class _ThunderstormAnimationState extends State<ThunderstormAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final showFlash = _random.nextDouble() > 0.8;
        return Stack(
          children: [
            const RainAnimation(),
            if (showFlash)
              Container(
                color: Colors.white.withOpacity(0.5),
              ),
            Center(
              child: Icon(Icons.flash_on,
                  color: Colors.yellowAccent.withOpacity(showFlash ? 1 : 0),
                  size: 100),
            ),
          ],
        );
      },
    );
  }
}

//
//  Animasi Salju
//
class SnowAnimation extends StatefulWidget {
  const SnowAnimation({super.key});

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _flakes =
      List.generate(100, (_) => Offset(Random().nextDouble(), Random().nextDouble()));

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _SnowPainter(_flakes, _controller.value),
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<Offset> flakes;
  final double progress;

  _SnowPainter(this.flakes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    for (var flake in flakes) {
      final dx = flake.dx * size.width;
      final dy = (flake.dy * size.height + progress * size.height) % size.height;
      canvas.drawCircle(Offset(dx, dy), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//
//  Animasi Kabut
//
class FogAnimation extends StatelessWidget {
  const FogAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.15),
    );
  }
}
