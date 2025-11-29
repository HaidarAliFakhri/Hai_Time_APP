// import tambahan
import 'package:audioplayers/audioplayers.dart';

// -------------------- AdzanService singleton --------------------
class AdzanService {
  AdzanService._internal();
  static final AdzanService instance = AdzanService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  // untuk mencegah multi-trigger dalam satu menit yang sama
  String? _lastTriggeredKey;

  Future<void> playAsset(String assetPath) async {
    if (isPlaying) return; // already playing, ignore
    try {
      // assetPath: 'assets/adzan.mp3' but AudioPlayer AssetSource expects relative path
      await _player.play(AssetSource(assetPath));
      isPlaying = true;

      // optional: otomatis stop setelah durasi (misal 2 menit) bila ingin fallback
      Future.delayed(const Duration(minutes: 5), () {
        if (isPlaying) stop();
      });
    } catch (e) {
      print('AdzanService.play error: $e');
      isPlaying = false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('AdzanService.stop error: $e');
    } finally {
      isPlaying = false;
    }
  }

  /// return true jika berhasil menandai trigger untuk key ini (misal "2025-11-28|04:45")
  /// false jika sudah pernah ter-trigger
  bool markTriggered(String key) {
    if (_lastTriggeredKey == key) return false;
    _lastTriggeredKey = key;
    return true;
  }

  void resetTrigger() {
    _lastTriggeredKey = null;
  }
}
