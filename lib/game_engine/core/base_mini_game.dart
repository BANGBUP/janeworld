import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/level_config.dart';
import '../../domain/entities/game_result.dart';
import '../../pack_system/pack_loader.dart';
import 'game_audio_manager.dart';

/// 게임 상태
enum GameState {
  initial,
  loading,
  ready,
  playing,
  paused,
  completed,
  failed,
}

/// 모든 미니게임의 기본 클래스
abstract class BaseMiniGame extends FlameGame with TapCallbacks, DragCallbacks {
  // 메타데이터 - 서브클래스에서 구현
  String get gameId;
  String get gameType;
  List<String> get supportedModes;

  // 상태
  GameState _state = GameState.initial;
  GameState get state => _state;

  // 설정
  LevelConfig? _levelConfig;
  LevelConfig get levelConfig => _levelConfig!;

  PackAssetBundle? _packAssets;
  PackAssetBundle get packAssets => _packAssets!;

  GameAudioManager? _audioManager;
  GameAudioManager get audioManager => _audioManager!;

  String _packId = '';
  String get packId => _packId;

  String _childId = 'default';
  String get childId => _childId;

  // 초기화 완료 플래그
  bool _configParsed = false;
  bool _initialized = false;
  bool _autoStart = false;

  // 결과
  int _score = 0;
  int get score => _score;

  int _stars = 0;
  int get stars => _stars;

  int _mistakes = 0;
  int get mistakes => _mistakes;

  DateTime? _startTime;
  Duration? _playDuration;

  // 콜백
  VoidCallback? onGameComplete;
  VoidCallback? onGameFail;
  Function(int score, int stars)? onScoreUpdate;

  /// 게임 설정 저장 (실제 초기화는 onLoad에서)
  Future<void> initialize({
    required String packId,
    required LevelConfig levelConfig,
    required PackAssetBundle assets,
    String childId = 'default',
    bool autoStart = true,
  }) async {
    _packId = packId;
    _levelConfig = levelConfig;
    _packAssets = assets;
    _childId = childId;
    _autoStart = autoStart;
    _audioManager = GameAudioManager(_packAssets!);

    _state = GameState.loading;

    // 게임 설정 파싱
    parseGameConfig(levelConfig.gameConfig.settings);
    _configParsed = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 설정이 파싱되었으면 초기화 수행
    if (_configParsed && !_initialized) {
      await onInitialize();
      _initialized = true;
      _state = GameState.ready;

      // 자동 시작
      if (_autoStart) {
        startGame();
      }
    }
  }

  /// 서브클래스에서 구현: 초기화 로직 (이 시점에서 size 사용 가능)
  Future<void> onInitialize();

  /// 서브클래스에서 구현: 게임 설정 파싱
  void parseGameConfig(Map<String, dynamic> settings);

  /// 게임 시작
  void startGame() {
    if (_state != GameState.ready) {
      return;
    }

    _state = GameState.playing;
    _startTime = DateTime.now();
    _score = 0;
    _mistakes = 0;
    _stars = 0;

    onGameStart();
  }

  /// 서브클래스에서 구현: 게임 시작 로직
  void onGameStart();

  /// 일시정지
  void pauseGame() {
    if (_state != GameState.playing) return;

    _state = GameState.paused;
    pauseEngine();
    _audioManager?.pauseAll();

    onGamePause();
  }

  /// 서브클래스에서 오버라이드: 일시정지 로직
  void onGamePause() {}

  /// 재개
  void resumeGame() {
    if (_state != GameState.paused) return;

    _state = GameState.playing;
    resumeEngine();
    _audioManager?.resumeAll();

    onGameResume();
  }

  /// 서브클래스에서 오버라이드: 재개 로직
  void onGameResume() {}

  /// 게임 종료
  void endGame({required bool completed}) {
    if (_state == GameState.completed || _state == GameState.failed) return;

    _state = completed ? GameState.completed : GameState.failed;
    _playDuration = DateTime.now().difference(_startTime ?? DateTime.now());

    _calculateStars();

    onGameEnd(completed);

    if (completed) {
      onGameComplete?.call();
    } else {
      onGameFail?.call();
    }
  }

  /// 서브클래스에서 오버라이드: 게임 종료 로직
  void onGameEnd(bool completed) {}

  /// 점수 추가
  void addScore(int points) {
    _score += points;
    onScoreUpdate?.call(_score, _stars);
  }

  /// 점수 설정
  void setScore(int points) {
    _score = points;
    onScoreUpdate?.call(_score, _stars);
  }

  /// 실수 기록
  void addMistake() {
    _mistakes++;
  }

  /// 별점 계산 (서브클래스에서 오버라이드 가능)
  void _calculateStars() {
    final maxStars = _levelConfig?.rewards.starsPossible ?? 3;

    if (_mistakes == 0) {
      _stars = maxStars;
    } else if (_mistakes <= 2) {
      _stars = maxStars - 1;
    } else if (_mistakes <= 5) {
      _stars = (maxStars - 2).clamp(1, maxStars);
    } else {
      _stars = 1;
    }
  }

  /// 별점 직접 설정
  void setStars(int value) {
    _stars = value.clamp(0, _levelConfig?.rewards.starsPossible ?? 3);
  }

  /// 게임 결과
  GameResult getResult() {
    return GameResult(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      packId: _packId,
      levelId: _levelConfig?.levelId ?? '',
      childId: _childId,
      score: _score,
      stars: _stars,
      mistakes: _mistakes,
      playDuration: _playDuration ?? Duration.zero,
      completed: _state == GameState.completed,
      startedAt: _startTime ?? DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  /// 게임 리셋
  void resetGame() {
    _state = GameState.ready;
    _score = 0;
    _stars = 0;
    _mistakes = 0;
    _startTime = null;
    _playDuration = null;

    // 기존 컴포넌트 제거
    removeAll(children);

    // 다시 초기화
    _initialized = false;
    onInitialize().then((_) {
      _initialized = true;
    });
  }

  /// 로컬라이즈된 문자열 가져오기
  String tr(String key, {String locale = 'ko'}) {
    return key;
  }

  @override
  Color backgroundColor() => const Color(0xFFF5F6FA);

  @override
  void onRemove() {
    _audioManager?.dispose();
    super.onRemove();
  }
}
