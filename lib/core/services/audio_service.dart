import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/screens/settings_screen.dart';

/// 앱 전역 오디오 서비스
final audioServiceProvider = Provider<AudioService>((ref) {
  final settings = ref.watch(settingsProvider);
  return AudioService(
    soundEnabled: settings.soundEnabled,
    musicEnabled: settings.musicEnabled,
    soundVolume: settings.soundVolume,
    musicVolume: settings.musicVolume,
  );
});

class AudioService {
  final bool soundEnabled;
  final bool musicEnabled;
  final double soundVolume;
  final double musicVolume;

  AudioService({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = 1.0,
    this.musicVolume = 0.5,
  });

  /// 효과음 재생 (내장 사운드)
  Future<void> playSfx(SoundEffect effect) async {
    if (!soundEnabled) return;

    try {
      // 내장 사운드 파일 경로
      final path = _getSfxPath(effect);
      await FlameAudio.play(path, volume: soundVolume);
    } catch (e) {
      // 사운드 파일이 없으면 무시
      // print('SFX not available: $effect');
    }
  }

  String _getSfxPath(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.correct:
        return 'sfx/correct.mp3';
      case SoundEffect.wrong:
        return 'sfx/wrong.mp3';
      case SoundEffect.click:
        return 'sfx/click.mp3';
      case SoundEffect.success:
        return 'sfx/success.mp3';
      case SoundEffect.levelUp:
        return 'sfx/level_up.mp3';
      case SoundEffect.star:
        return 'sfx/star.mp3';
      case SoundEffect.flip:
        return 'sfx/flip.mp3';
      case SoundEffect.match:
        return 'sfx/match.mp3';
    }
  }

  /// 정답 효과음
  Future<void> playCorrect() => playSfx(SoundEffect.correct);

  /// 오답 효과음
  Future<void> playWrong() => playSfx(SoundEffect.wrong);

  /// 버튼 클릭
  Future<void> playClick() => playSfx(SoundEffect.click);

  /// 성공
  Future<void> playSuccess() => playSfx(SoundEffect.success);

  /// 레벨업
  Future<void> playLevelUp() => playSfx(SoundEffect.levelUp);

  /// 별 획득
  Future<void> playStar() => playSfx(SoundEffect.star);

  /// 카드 뒤집기
  Future<void> playFlip() => playSfx(SoundEffect.flip);

  /// 매칭 성공
  Future<void> playMatch() => playSfx(SoundEffect.match);

  /// 배경음악 재생
  Future<void> playBgm(String path) async {
    if (!musicEnabled) return;

    try {
      await FlameAudio.bgm.play(path, volume: musicVolume);
    } catch (e) {
      // print('BGM not available: $path');
    }
  }

  /// 배경음악 중지
  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      // ignore
    }
  }

  /// 배경음악 일시정지
  void pauseBgm() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      // ignore
    }
  }

  /// 배경음악 재개
  void resumeBgm() {
    if (!musicEnabled) return;
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      // ignore
    }
  }
}

/// 효과음 종류
enum SoundEffect {
  correct,
  wrong,
  click,
  success,
  levelUp,
  star,
  flip,
  match,
}
