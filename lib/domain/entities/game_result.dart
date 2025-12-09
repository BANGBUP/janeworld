import 'package:equatable/equatable.dart';

/// 게임 결과 엔티티
class GameResult extends Equatable {
  final String sessionId;
  final String packId;
  final String levelId;
  final String childId;
  final int score;
  final int stars;
  final int mistakes;
  final Duration playDuration;
  final bool completed;
  final DateTime startedAt;
  final DateTime completedAt;

  const GameResult({
    required this.sessionId,
    required this.packId,
    required this.levelId,
    required this.childId,
    required this.score,
    required this.stars,
    required this.mistakes,
    required this.playDuration,
    required this.completed,
    required this.startedAt,
    required this.completedAt,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      sessionId: json['session_id'] as String,
      packId: json['pack_id'] as String,
      levelId: json['level_id'] as String,
      childId: json['child_id'] as String,
      score: json['score'] as int,
      stars: json['stars'] as int,
      mistakes: json['mistakes'] as int,
      playDuration: Duration(seconds: json['play_duration_seconds'] as int),
      completed: json['completed'] == 1 || json['completed'] == true,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'pack_id': packId,
        'level_id': levelId,
        'child_id': childId,
        'score': score,
        'stars': stars,
        'mistakes': mistakes,
        'play_duration_seconds': playDuration.inSeconds,
        'completed': completed ? 1 : 0,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        sessionId,
        packId,
        levelId,
        childId,
        score,
        stars,
        mistakes,
        playDuration,
        completed,
        startedAt,
        completedAt,
      ];
}

/// 레벨 진행도
class LevelProgress extends Equatable {
  final String packId;
  final String levelId;
  final String childId;
  final int bestScore;
  final int bestStars;
  final int attempts;
  final Duration totalPlayTime;
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;
  final bool unlocked;

  const LevelProgress({
    required this.packId,
    required this.levelId,
    required this.childId,
    this.bestScore = 0,
    this.bestStars = 0,
    this.attempts = 0,
    this.totalPlayTime = Duration.zero,
    this.firstCompletedAt,
    this.lastPlayedAt,
    this.unlocked = false,
  });

  bool get isCompleted => bestStars > 0;

  LevelProgress copyWith({
    String? packId,
    String? levelId,
    String? childId,
    int? bestScore,
    int? bestStars,
    int? attempts,
    Duration? totalPlayTime,
    DateTime? firstCompletedAt,
    DateTime? lastPlayedAt,
    bool? unlocked,
  }) {
    return LevelProgress(
      packId: packId ?? this.packId,
      levelId: levelId ?? this.levelId,
      childId: childId ?? this.childId,
      bestScore: bestScore ?? this.bestScore,
      bestStars: bestStars ?? this.bestStars,
      attempts: attempts ?? this.attempts,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      packId: json['pack_id'] as String,
      levelId: json['level_id'] as String,
      childId: json['child_id'] as String,
      bestScore: json['best_score'] as int? ?? 0,
      bestStars: json['best_stars'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      totalPlayTime:
          Duration(seconds: json['total_play_time_seconds'] as int? ?? 0),
      firstCompletedAt: json['first_completed_at'] != null
          ? DateTime.parse(json['first_completed_at'] as String)
          : null,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
      unlocked: json['unlocked'] == 1 || json['unlocked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'pack_id': packId,
        'level_id': levelId,
        'child_id': childId,
        'best_score': bestScore,
        'best_stars': bestStars,
        'attempts': attempts,
        'total_play_time_seconds': totalPlayTime.inSeconds,
        'first_completed_at': firstCompletedAt?.toIso8601String(),
        'last_played_at': lastPlayedAt?.toIso8601String(),
        'unlocked': unlocked ? 1 : 0,
      };

  @override
  List<Object?> get props => [
        packId,
        levelId,
        childId,
        bestScore,
        bestStars,
        attempts,
        totalPlayTime,
        firstCompletedAt,
        lastPlayedAt,
        unlocked,
      ];
}
