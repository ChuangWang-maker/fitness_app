import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> _vibrate(int duration) async {
    try {
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(duration: duration);
      }
    } catch (_) {}
  }

  Future<void> playLightMode() async {
    await _player.stop();
    await _player.play(AssetSource('hint.wav'), volume: 1.0);
    _vibrate(80);
  }

  Future<void> playDarkMode() async {
    await _player.stop();
    await _player.play(AssetSource('bursting.mp3'), volume: 1.0);
    _vibrate(80);
  }

  void dispose() {
    _player.dispose();
  }
}
