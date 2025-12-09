import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../domain/entities/game_result.dart';
import '../../../game_engine/core/base_mini_game.dart';
import '../../../game_engine/core/game_registry.dart';
import '../../../domain/entities/level_config.dart';
import '../../../pack_system/pack_loader.dart';
import '../widgets/game_result_overlay.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String packId;
  final String levelId;

  const GameScreen({
    super.key,
    required this.packId,
    required this.levelId,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  BaseMiniGame? _game;
  bool _isLoading = true;
  String? _error;
  bool _showPauseOverlay = false;
  bool _showResultOverlay = false;
  GameResult? _gameResult;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      // 데모용 게임 생성
      final gameType = _getGameType(widget.packId);
      final levelConfig = _getDemoLevelConfig(widget.packId, widget.levelId);

      final game = GameRegistry().createGame(gameType);

      // 임시 PackAssetBundle 생성 (실제로는 PackLoader에서)
      final dummyAssets = PackAssetBundle(basePath: '');

      await game.initialize(
        packId: widget.packId,
        levelConfig: levelConfig,
        assets: dummyAssets,
      );

      // 콜백 설정
      game.onGameComplete = _onGameComplete;
      game.onGameFail = _onGameFail;

      setState(() {
        _game = game;
        _isLoading = false;
      });
      // 게임은 onLoad에서 자동 시작됨
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getGameType(String packId) {
    switch (packId) {
      case 'demo_numbers':
        return 'NumberLetterGame';
      case 'demo_memory':
        return 'MemoryCardGame';
      case 'demo_shapes':
        return 'ShapeColorGame';
      default:
        return 'NumberLetterGame';
    }
  }

  LevelConfig _getDemoLevelConfig(String packId, String levelId) {
    final levelNum = int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final gameType = _getGameType(packId);

    Map<String, dynamic> settings;

    switch (gameType) {
      case 'NumberLetterGame':
        final objectNames = ['사과', '별', '공', '꽃', '하트'];
        final particles = ['가', '이', '이', '이', '가']; // 받침 유무에 따른 조사
        final objIndex = levelNum % 5;
        settings = {
          'mode': 'counting',
          'target_number': levelNum + 1,
          'count_objects': ['apple', 'star', 'ball', 'flower', 'heart'][objIndex],
          'choices': _generateChoices(levelNum + 1),
          'show_hint': true,
          'instruction': '${objectNames[objIndex]}${particles[objIndex]} 몇 개일까요?',
        };
        break;
      case 'MemoryCardGame':
        settings = {
          'mode': 'match_pairs',
          'grid': {'rows': 2, 'cols': 3},
          'flip_duration_ms': 300,
          'mismatch_delay_ms': 1000,
        };
        break;
      case 'ShapeColorGame':
        final shapes = ['circle', 'square', 'triangle', 'star'];
        final colors = ['#FF0000', '#0000FF', '#00FF00', '#FFFF00'];
        settings = {
          'mode': 'match',
          'target': {
            'shape': shapes[levelNum % shapes.length],
            'color': colors[levelNum % colors.length],
          },
          'match_criteria': ['shape', 'color'],
        };
        break;
      default:
        settings = {};
    }

    return LevelConfig(
      levelId: levelId,
      levelNumber: levelNum,
      title: {'ko': '레벨 $levelNum', 'en': 'Level $levelNum'},
      difficulty: levelNum,
      estimatedTimeSeconds: 60,
      unlockCondition: const UnlockCondition(type: 'none'),
      gameConfig: GameConfig(
        type: gameType,
        mode: settings['mode'] as String? ?? 'default',
        settings: settings,
      ),
      assets: const LevelAssets(),
      rewards: const LevelRewards(starsPossible: 3, completionXp: 10),
    );
  }

  List<int> _generateChoices(int target) {
    final choices = <int>[target];
    for (int i = 1; i <= 10 && choices.length < 4; i++) {
      if (i != target) {
        choices.add(i);
      }
      if (choices.length >= 4) break;
    }
    choices.shuffle();
    return choices;
  }

  void _onGameComplete() async {
    final result = _game?.getResult();
    if (result != null) {
      // 진행 상황 저장
      await ProgressService.saveGameResult(result);
      // Provider 새로고침
      ref.invalidate(packProgressProvider(widget.packId));
    }
    setState(() {
      _gameResult = result;
      _showResultOverlay = true;
    });
  }

  void _onGameFail() async {
    final result = _game?.getResult();
    if (result != null) {
      // 진행 상황 저장 (실패해도 기록)
      await ProgressService.saveGameResult(result);
    }
    setState(() {
      _gameResult = result;
      _showResultOverlay = true;
    });
  }

  void _onPause() {
    _game?.pauseGame();
    setState(() {
      _showPauseOverlay = true;
    });
  }

  void _onResume() {
    setState(() {
      _showPauseOverlay = false;
    });
    _game?.resumeGame();
  }

  void _onRetry() {
    setState(() {
      _showResultOverlay = false;
      _isLoading = true;
    });
    _loadGame();
  }

  void _onNextLevel() {
    // 다음 레벨로 이동
    final currentNum =
        int.tryParse(widget.levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final nextLevelId = 'level_${(currentNum + 1).toString().padLeft(3, '0')}';
    context.pushReplacement('/play/${widget.packId}/$nextLevelId');
  }

  void _onQuit() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.gradientPrimary,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  '게임 로딩 중...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('오류: $_error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onQuit,
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _onPause();
          }
        },
        child: Stack(
          children: [
            // 게임 위젯
            GameWidget(game: _game!),

            // 일시정지 버튼
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: _onPause,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // 일시정지 오버레이
            if (_showPauseOverlay)
              PauseOverlay(
                onResume: _onResume,
                onRetry: _onRetry,
                onQuit: _onQuit,
              ),

            // 결과 오버레이
            if (_showResultOverlay && _gameResult != null)
              GameResultOverlay(
                result: _gameResult!,
                onRetry: _onRetry,
                onNext: _onNextLevel,
                onQuit: _onQuit,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _game?.pauseGame();
    super.dispose();
  }
}
