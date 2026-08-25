import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

enum Sfx { card, deal, move, capture, swap, home, win }

/// Plays effects and the background loop. Mute flags are reactive and
/// bound to persisted settings by [SettingsController].
class AudioService extends GetxService {
  final _sfx = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  final _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  final sfxEnabled = true.obs;
  final musicEnabled = false.obs;

  static const _files = {
    Sfx.card: 'sounds/card.wav',
    Sfx.deal: 'sounds/deal.wav',
    Sfx.move: 'sounds/move.wav',
    Sfx.capture: 'sounds/capture.wav',
    Sfx.swap: 'sounds/swap.wav',
    Sfx.home: 'sounds/home.wav',
    Sfx.win: 'sounds/win.wav',
  };

  Future<AudioService> init() async {
    await _music.setVolume(0.35);
    ever(musicEnabled, (on) => on ? _startMusic() : _music.stop());
    return this;
  }

  void play(Sfx s) {
    if (!sfxEnabled.value) return;
    // Fire-and-forget; browsers may reject audio before a user gesture.
    _sfx.play(AssetSource(_files[s]!), volume: 0.8).catchError((_) {});
  }

  void _startMusic() =>
      _music.play(AssetSource('sounds/music.wav')).catchError((_) {});

  @override
  void onClose() {
    _sfx.dispose();
    _music.dispose();
    super.onClose();
  }
}
