import 'package:flame_audio/flame_audio.dart';
import '../../pack_system/pack_loader.dart';

/// 게임 오디오 관리
class GameAudioManager {
  final PackAssetBundle _assets;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;

  GameAudioManager(this._assets);

  /// 배경음 재생
  Future<void> playBgm(String relativePath, {bool loop = true}) async {
    if (_isMuted) return;

    try {
      final fullPath = _assets.getAssetPath(relativePath);
      // Flame Audio로 재생
      await FlameAudio.bgm.play(fullPath, volume: _bgmVolume);
    } catch (e) {
      // 오디오 로드 실패 무시
      print('Failed to play BGM: $e');
    }
  }

  /// 배경음 중지
  void stopBgm() {
    FlameAudio.bgm.stop();
  }

  /// 효과음 재생
  Future<void> playSfx(String relativePath) async {
    if (_isMuted) return;

    try {
      final fullPath = _assets.getAssetPath(relativePath);
      await FlameAudio.play(fullPath, volume: _sfxVolume);
    } catch (e) {
      print('Failed to play SFX: $e');
    }
  }

  /// 정답 효과음
  Future<void> playCorrect() async {
    // 내장 효과음 또는 기본 효과음
    await playSfx('assets/audio/sfx/correct.mp3');
  }

  /// 오답 효과음
  Future<void> playWrong() async {
    await playSfx('assets/audio/sfx/wrong.mp3');
  }

  /// 버튼 클릭 효과음
  Future<void> playClick() async {
    await playSfx('assets/audio/sfx/click.mp3');
  }

  /// 성공 효과음
  Future<void> playSuccess() async {
    await playSfx('assets/audio/sfx/success.mp3');
  }

  /// 음성 재생
  Future<void> playVoice(String relativePath) async {
    if (_isMuted) return;

    try {
      final fullPath = _assets.getAssetPath(relativePath);
      await FlameAudio.play(fullPath, volume: 1.0);
    } catch (e) {
      print('Failed to play voice: $e');
    }
  }

  /// 모든 오디오 일시정지
  void pauseAll() {
    FlameAudio.bgm.pause();
  }

  /// 모든 오디오 재개
  void resumeAll() {
    FlameAudio.bgm.resume();
  }

  /// 음소거 토글
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      pauseAll();
    } else {
      resumeAll();
    }
  }

  /// 음소거 설정
  void setMute(bool mute) {
    _isMuted = mute;
    if (_isMuted) {
      pauseAll();
    }
  }

  /// 배경음 볼륨 설정
  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
  }

  /// 효과음 볼륨 설정
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// 리소스 해제
  void dispose() {
    FlameAudio.bgm.stop();
  }
}
