import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/pack_provider.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../domain/entities/level_config.dart';
import '../widgets/level_button.dart';

class LevelSelectScreen extends ConsumerStatefulWidget {
  final String packId;

  const LevelSelectScreen({
    super.key,
    required this.packId,
  });

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen> {
  List<LevelConfig> _levels = [];
  bool _isLoading = true;
  String _packName = '';
  int _totalLevels = 5;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    await Future.delayed(const Duration(milliseconds: 100));

    // 팩 정보 가져오기
    final packAsync = ref.read(packByIdProvider(widget.packId));
    final pack = packAsync.valueOrNull;

    if (pack != null) {
      _packName = pack.name['ko'] ?? pack.name['en'] ?? '게임팩';
      _totalLevels = pack.totalLevels;
    } else {
      _packName = _getPackName(widget.packId);
    }

    // 첫 번째 레벨 잠금 해제 초기화
    final childId = ref.read(currentChildIdProvider);
    await ProgressService.initializePackProgress(widget.packId, childId);

    setState(() {
      _isLoading = false;
      _levels = _generateLevelConfigs(widget.packId, _totalLevels);
    });
  }

  String _getPackName(String packId) {
    switch (packId) {
      case 'demo_numbers':
        return '숫자 세기';
      case 'demo_memory':
        return '기억력 게임';
      case 'demo_shapes':
        return '모양 맞추기';
      default:
        return '게임팩';
    }
  }

  List<LevelConfig> _generateLevelConfigs(String packId, int totalLevels) {
    final gameType = _getGameType(packId);

    return List.generate(totalLevels, (index) {
      final levelNum = index + 1;
      return LevelConfig(
        levelId: 'level_${levelNum.toString().padLeft(3, '0')}',
        levelNumber: levelNum,
        title: {'ko': '레벨 $levelNum', 'en': 'Level $levelNum'},
        difficulty: levelNum,
        estimatedTimeSeconds: 60,
        unlockCondition: index == 0
            ? const UnlockCondition(type: 'none')
            : UnlockCondition(
                type: 'previous_level',
                previousLevelId: 'level_${index.toString().padLeft(3, '0')}',
                minStars: 1,
              ),
        gameConfig: GameConfig(
          type: gameType,
          mode: 'counting',
          settings: {'target_number': levelNum + 1},
        ),
        assets: const LevelAssets(),
        rewards: const LevelRewards(starsPossible: 3, completionXp: 10),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(packProgressProvider(widget.packId));

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : progressAsync.when(
                loading: () => _buildContent(context, {}),
                error: (_, __) => _buildContent(context, {}),
                data: (levelStars) => _buildContent(context, levelStars),
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, int> levelStars) {
    return Column(
      children: [
        // 헤더
        _buildHeader(levelStars),

        // 레벨 그리드
        Expanded(
          child: _buildLevelGrid(levelStars),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, int> levelStars) {
    final totalStars = levelStars.values.fold(0, (a, b) => a + b);
    final maxStars = _levels.length * 3;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            iconSize: 28,
          ),
          const SizedBox(width: 16),
          Text(
            _packName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 진행률
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.star, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalStars / $maxStars',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid(Map<String, int> levelStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          final stars = levelStars[level.levelId] ?? 0;

          // 잠금 해제 조건 확인
          bool isUnlocked = false;
          if (index == 0) {
            isUnlocked = true;
          } else {
            final prevLevelId = _levels[index - 1].levelId;
            final prevStars = levelStars[prevLevelId] ?? 0;
            isUnlocked = prevStars > 0;
          }

          return LevelButton(
            levelNumber: level.levelNumber,
            stars: stars,
            maxStars: level.rewards.starsPossible,
            isUnlocked: isUnlocked,
            onTap: isUnlocked ? () => _onLevelTap(level) : null,
          );
        },
      ),
    );
  }

  void _onLevelTap(LevelConfig level) {
    context.push('/play/${widget.packId}/${level.levelId}');
  }
}
