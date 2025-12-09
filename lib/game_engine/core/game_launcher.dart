import '../../domain/entities/game_result.dart';
import '../../pack_system/pack_loader.dart';
import '../../pack_system/pack_manager.dart';
import '../../data/datasources/local/pack_database.dart';
import 'base_mini_game.dart';
import 'game_registry.dart';

/// 게임 실행 관리
class GameLauncher {
  final PackLoader _packLoader;
  final GameRegistry _gameRegistry;
  final PackManager _packManager;
  final PackDatabase _packDatabase;

  BaseMiniGame? _currentGame;

  GameLauncher({
    required PackLoader packLoader,
    required GameRegistry gameRegistry,
    required PackManager packManager,
    required PackDatabase packDatabase,
  })  : _packLoader = packLoader,
        _gameRegistry = gameRegistry,
        _packManager = packManager,
        _packDatabase = packDatabase;

  /// 게임 실행
  Future<BaseMiniGame> launchGame({
    required String packId,
    required String levelId,
    String childId = 'default',
  }) async {
    // 1. 팩 로드
    final loadedPack = await _packLoader.loadPack(packId);

    // 2. 레벨 설정 가져오기
    final levelConfig = loadedPack.getLevel(levelId);
    if (levelConfig == null) {
      throw GameLaunchException(
        'Level not found: $levelId in pack $packId',
      );
    }

    // 3. 게임 타입 확인 및 엔진 생성
    final gameType = levelConfig.gameConfig.type;
    if (!_gameRegistry.isSupported(gameType)) {
      throw GameLaunchException(
        'This pack requires game engine: $gameType, '
        'but it is not available in this app version.',
      );
    }

    final game = _gameRegistry.createGame(gameType);

    // 4. 게임 초기화
    await game.initialize(
      packId: packId,
      levelConfig: levelConfig,
      assets: loadedPack.assets,
      childId: childId,
    );

    // 5. 마지막 플레이 시간 업데이트
    await _packManager.updateLastPlayedAt(packId);

    _currentGame = game;
    return game;
  }

  /// 현재 게임 시작
  void startCurrentGame() {
    _currentGame?.startGame();
  }

  /// 현재 게임 일시정지
  void pauseCurrentGame() {
    _currentGame?.pauseGame();
  }

  /// 현재 게임 재개
  void resumeCurrentGame() {
    _currentGame?.resumeGame();
  }

  /// 현재 게임 종료 및 결과 저장
  Future<GameResult?> finishCurrentGame({bool saveResult = true}) async {
    if (_currentGame == null) {
      return null;
    }

    final result = _currentGame!.getResult();

    if (saveResult && result.completed) {
      // 결과 저장
      await _packDatabase.insertGameSession(result);

      // 레벨 진행도 업데이트
      await _updateLevelProgress(result);
    }

    _currentGame = null;
    return result;
  }

  /// 레벨 진행도 업데이트
  Future<void> _updateLevelProgress(GameResult result) async {
    final existing = await _packDatabase.getLevelProgress(
      result.packId,
      result.levelId,
      result.childId,
    );

    final progress = LevelProgress(
      packId: result.packId,
      levelId: result.levelId,
      childId: result.childId,
      bestScore:
          existing != null && existing.bestScore > result.score
              ? existing.bestScore
              : result.score,
      bestStars:
          existing != null && existing.bestStars > result.stars
              ? existing.bestStars
              : result.stars,
      attempts: (existing?.attempts ?? 0) + 1,
      totalPlayTime:
          (existing?.totalPlayTime ?? Duration.zero) + result.playDuration,
      firstCompletedAt: existing?.firstCompletedAt ??
          (result.completed ? result.completedAt : null),
      lastPlayedAt: result.completedAt,
      unlocked: true,
    );

    await _packDatabase.upsertLevelProgress(progress);
  }

  /// 현재 게임 참조
  BaseMiniGame? get currentGame => _currentGame;

  /// 게임 실행 중 여부
  bool get isGameRunning => _currentGame != null;
}

/// 게임 실행 예외
class GameLaunchException implements Exception {
  final String message;

  GameLaunchException(this.message);

  @override
  String toString() => 'GameLaunchException: $message';
}
