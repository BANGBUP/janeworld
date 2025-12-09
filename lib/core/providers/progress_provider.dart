import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_result.dart';
import '../di/service_locator.dart';
import '../di/service_locator_native.dart'
    if (dart.library.html) '../di/service_locator_web.dart';

/// 현재 아이 ID (추후 멀티 프로필 지원)
final currentChildIdProvider = StateProvider<String>((ref) => 'default');

/// 특정 팩의 레벨 진행도 Provider
final packProgressProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, packId) async {
    // 웹에서는 빈 맵 반환
    if (ServiceLocator.isWeb) {
      return {};
    }

    final childId = ref.watch(currentChildIdProvider);
    final progressList =
        await NativeServices.packDatabase.getLevelProgressList(packId, childId);

    // levelId -> bestStars 매핑
    return {
      for (final progress in progressList) progress.levelId: progress.bestStars
    };
  },
);

/// 특정 레벨의 진행도 Provider
final levelProgressProvider =
    FutureProvider.family<LevelProgress?, LevelProgressKey>(
  (ref, key) async {
    // 웹에서는 null 반환
    if (ServiceLocator.isWeb) {
      return null;
    }

    return await NativeServices.packDatabase.getLevelProgress(
      key.packId,
      key.levelId,
      key.childId,
    );
  },
);

/// 레벨 진행도 키
class LevelProgressKey {
  final String packId;
  final String levelId;
  final String childId;

  const LevelProgressKey({
    required this.packId,
    required this.levelId,
    required this.childId,
  });

  @override
  bool operator ==(Object other) =>
      other is LevelProgressKey &&
      other.packId == packId &&
      other.levelId == levelId &&
      other.childId == childId;

  @override
  int get hashCode => Object.hash(packId, levelId, childId);
}

/// 게임 결과 저장 및 진행도 업데이트 서비스
class ProgressService {
  /// 게임 결과 저장 및 진행도 업데이트
  static Future<void> saveGameResult(GameResult result) async {
    // 웹에서는 저장 기능 비활성화
    if (ServiceLocator.isWeb) return;

    final db = NativeServices.packDatabase;

    // 1. 게임 세션 저장
    await db.insertGameSession(result);

    // 2. 기존 진행도 조회
    final existing = await db.getLevelProgress(
      result.packId,
      result.levelId,
      result.childId,
    );

    // 3. 진행도 업데이트
    final newProgress = LevelProgress(
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
      firstCompletedAt:
          result.completed && existing?.firstCompletedAt == null
              ? DateTime.now()
              : existing?.firstCompletedAt,
      lastPlayedAt: DateTime.now(),
      unlocked: true,
    );

    await db.upsertLevelProgress(newProgress);

    // 4. 다음 레벨 잠금 해제
    if (result.completed && result.stars > 0) {
      await _unlockNextLevel(result.packId, result.levelId, result.childId);
    }

    // 5. 마지막 플레이 시간 업데이트
    await db.updateLastPlayedAt(result.packId);
  }

  /// 다음 레벨 잠금 해제
  static Future<void> _unlockNextLevel(
    String packId,
    String currentLevelId,
    String childId,
  ) async {
    if (ServiceLocator.isWeb) return;

    final db = NativeServices.packDatabase;

    // 현재 레벨 번호 파싱
    final currentNum =
        int.tryParse(currentLevelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final nextLevelId = 'level_${(currentNum + 1).toString().padLeft(3, '0')}';

    // 다음 레벨 진행도 조회
    final nextProgress = await db.getLevelProgress(packId, nextLevelId, childId);

    // 없으면 새로 생성, 있으면 업데이트
    final updated = LevelProgress(
      packId: packId,
      levelId: nextLevelId,
      childId: childId,
      bestScore: nextProgress?.bestScore ?? 0,
      bestStars: nextProgress?.bestStars ?? 0,
      attempts: nextProgress?.attempts ?? 0,
      totalPlayTime: nextProgress?.totalPlayTime ?? Duration.zero,
      firstCompletedAt: nextProgress?.firstCompletedAt,
      lastPlayedAt: nextProgress?.lastPlayedAt,
      unlocked: true, // 잠금 해제
    );

    await db.upsertLevelProgress(updated);
  }

  /// 첫 번째 레벨 잠금 해제 (팩 시작시)
  static Future<void> initializePackProgress(
    String packId,
    String childId,
  ) async {
    if (ServiceLocator.isWeb) return;

    final db = NativeServices.packDatabase;

    // 첫 번째 레벨 진행도 확인
    final firstProgress =
        await db.getLevelProgress(packId, 'level_001', childId);

    // 없으면 첫 번째 레벨 잠금 해제
    if (firstProgress == null) {
      await db.upsertLevelProgress(
        LevelProgress(
          packId: packId,
          levelId: 'level_001',
          childId: childId,
          unlocked: true,
        ),
      );
    }
  }

  /// 팩 전체 진행률 계산
  static Future<double> getPackProgressPercentage(
    String packId,
    String childId,
    int totalLevels,
  ) async {
    if (ServiceLocator.isWeb) return 0.0;

    final db = NativeServices.packDatabase;
    final progressList = await db.getLevelProgressList(packId, childId);

    final completedCount =
        progressList.where((p) => p.bestStars > 0).length;
    return totalLevels > 0 ? completedCount / totalLevels : 0.0;
  }

  /// 팩 전체 별점 합계
  static Future<int> getPackTotalStars(
    String packId,
    String childId,
  ) async {
    if (ServiceLocator.isWeb) return 0;

    final db = NativeServices.packDatabase;
    final progressList = await db.getLevelProgressList(packId, childId);

    return progressList.fold<int>(0, (sum, p) => sum + p.bestStars);
  }
}
