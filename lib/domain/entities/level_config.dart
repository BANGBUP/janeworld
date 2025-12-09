import 'package:equatable/equatable.dart';

/// 레벨 설정 엔티티
class LevelConfig extends Equatable {
  final String levelId;
  final int levelNumber;
  final Map<String, String> title;
  final Map<String, String>? description;
  final int difficulty;
  final int estimatedTimeSeconds;
  final UnlockCondition unlockCondition;
  final GameConfig gameConfig;
  final LevelAssets assets;
  final LevelRewards rewards;

  const LevelConfig({
    required this.levelId,
    required this.levelNumber,
    required this.title,
    this.description,
    required this.difficulty,
    required this.estimatedTimeSeconds,
    required this.unlockCondition,
    required this.gameConfig,
    required this.assets,
    required this.rewards,
  });

  String getLocalizedTitle(String locale) =>
      title[locale] ?? title['en'] ?? title.values.first;

  String? getLocalizedDescription(String locale) =>
      description?[locale] ?? description?['en'] ?? description?.values.first;

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    return LevelConfig(
      levelId: json['level_id'] as String,
      levelNumber: json['level_number'] as int,
      title: Map<String, String>.from(json['metadata']['title'] ?? {}),
      description: json['metadata']['description'] != null
          ? Map<String, String>.from(json['metadata']['description'])
          : null,
      difficulty: json['metadata']['difficulty'] as int? ?? 1,
      estimatedTimeSeconds:
          json['metadata']['estimated_time_seconds'] as int? ?? 60,
      unlockCondition: UnlockCondition.fromJson(
          json['unlock_condition'] as Map<String, dynamic>? ?? {'type': 'none'}),
      gameConfig:
          GameConfig.fromJson(json['game_config'] as Map<String, dynamic>),
      assets: LevelAssets.fromJson(
          json['assets'] as Map<String, dynamic>? ?? {}),
      rewards: LevelRewards.fromJson(
          json['rewards'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'level_id': levelId,
        'level_number': levelNumber,
        'metadata': {
          'title': title,
          'description': description,
          'difficulty': difficulty,
          'estimated_time_seconds': estimatedTimeSeconds,
        },
        'unlock_condition': unlockCondition.toJson(),
        'game_config': gameConfig.toJson(),
        'assets': assets.toJson(),
        'rewards': rewards.toJson(),
      };

  @override
  List<Object?> get props => [
        levelId,
        levelNumber,
        title,
        description,
        difficulty,
        estimatedTimeSeconds,
        unlockCondition,
        gameConfig,
        assets,
        rewards,
      ];
}

/// 잠금 해제 조건
class UnlockCondition extends Equatable {
  final String type;
  final String? previousLevelId;
  final int? minStars;

  const UnlockCondition({
    required this.type,
    this.previousLevelId,
    this.minStars,
  });

  bool isSatisfied(Map<String, int> levelStars) {
    if (type == 'none') return true;
    if (type == 'previous_level' && previousLevelId != null) {
      final stars = levelStars[previousLevelId] ?? 0;
      return stars >= (minStars ?? 1);
    }
    return false;
  }

  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      type: json['type'] as String? ?? 'none',
      previousLevelId: json['previous_level_id'] as String?,
      minStars: json['min_stars'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (previousLevelId != null) 'previous_level_id': previousLevelId,
        if (minStars != null) 'min_stars': minStars,
      };

  @override
  List<Object?> get props => [type, previousLevelId, minStars];
}

/// 게임 설정
class GameConfig extends Equatable {
  final String type;
  final String mode;
  final Map<String, dynamic> settings;

  const GameConfig({
    required this.type,
    required this.mode,
    required this.settings,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      type: json['type'] as String,
      mode: json['mode'] as String? ?? 'default',
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'mode': mode,
        'settings': settings,
      };

  @override
  List<Object?> get props => [type, mode, settings];
}

/// 레벨 에셋
class LevelAssets extends Equatable {
  final String? background;
  final String? bgm;
  final Map<String, String>? additionalAssets;

  const LevelAssets({
    this.background,
    this.bgm,
    this.additionalAssets,
  });

  factory LevelAssets.fromJson(Map<String, dynamic> json) {
    return LevelAssets(
      background: json['background'] as String?,
      bgm: json['bgm'] as String?,
      additionalAssets: json['additional_assets'] != null
          ? Map<String, String>.from(json['additional_assets'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (background != null) 'background': background,
        if (bgm != null) 'bgm': bgm,
        if (additionalAssets != null) 'additional_assets': additionalAssets,
      };

  @override
  List<Object?> get props => [background, bgm, additionalAssets];
}

/// 레벨 보상
class LevelRewards extends Equatable {
  final int starsPossible;
  final int completionXp;

  const LevelRewards({
    this.starsPossible = 3,
    this.completionXp = 10,
  });

  factory LevelRewards.fromJson(Map<String, dynamic> json) {
    return LevelRewards(
      starsPossible: json['stars_possible'] as int? ?? 3,
      completionXp: json['completion_xp'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'stars_possible': starsPossible,
        'completion_xp': completionXp,
      };

  @override
  List<Object?> get props => [starsPossible, completionXp];
}
