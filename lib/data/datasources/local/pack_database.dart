import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/game_pack.dart';
import '../../../domain/entities/game_result.dart';

/// 팩 데이터베이스 접근 클래스
class PackDatabase {
  final Database _db;

  PackDatabase(this._db);

  // ==================== Installed Packs ====================

  /// 설치된 팩 저장
  Future<void> insertInstalledPack(GamePack pack, String manifestJson) async {
    await _db.insert(
      'installed_packs',
      {
        'pack_id': pack.packId,
        'version': pack.version,
        'name_ko': pack.name['ko'],
        'name_en': pack.name['en'],
        'description_ko': pack.description['ko'],
        'description_en': pack.description['en'],
        'game_type': pack.gameType,
        'total_levels': pack.totalLevels,
        'storage_size_mb': pack.storageSizeMb,
        'min_age': pack.minAge,
        'max_age': pack.maxAge,
        'skill_tags': jsonEncode(pack.skillTags),
        'installed_at': DateTime.now().toIso8601String(),
        'manifest_json': manifestJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 설치된 팩 목록 조회
  Future<List<GamePack>> getInstalledPacks() async {
    final results = await _db.query('installed_packs');
    return results.map(_mapToGamePack).toList();
  }

  /// 특정 팩 조회
  Future<GamePack?> getInstalledPack(String packId) async {
    final results = await _db.query(
      'installed_packs',
      where: 'pack_id = ?',
      whereArgs: [packId],
    );
    if (results.isEmpty) return null;
    return _mapToGamePack(results.first);
  }

  /// 팩 삭제
  Future<void> deleteInstalledPack(String packId) async {
    await _db.delete(
      'installed_packs',
      where: 'pack_id = ?',
      whereArgs: [packId],
    );
  }

  /// 마지막 플레이 시간 업데이트
  Future<void> updateLastPlayedAt(String packId) async {
    await _db.update(
      'installed_packs',
      {'last_played_at': DateTime.now().toIso8601String()},
      where: 'pack_id = ?',
      whereArgs: [packId],
    );
  }

  GamePack _mapToGamePack(Map<String, dynamic> row) {
    final skillTags = row['skill_tags'] != null
        ? List<String>.from(jsonDecode(row['skill_tags'] as String))
        : <String>[];

    return GamePack(
      packId: row['pack_id'] as String,
      version: row['version'] as String,
      name: {
        if (row['name_ko'] != null) 'ko': row['name_ko'] as String,
        if (row['name_en'] != null) 'en': row['name_en'] as String,
      },
      description: {
        if (row['description_ko'] != null)
          'ko': row['description_ko'] as String,
        if (row['description_en'] != null)
          'en': row['description_en'] as String,
      },
      author: 'JaneWorld',
      gameType: row['game_type'] as String,
      totalLevels: row['total_levels'] as int,
      storageSizeMb: row['storage_size_mb'] as int,
      minAge: row['min_age'] as int? ?? 0,
      maxAge: row['max_age'] as int? ?? 99,
      skillTags: skillTags,
      difficulty: 'normal',
      estimatedPlayTimeMinutes: 30,
      supportedLocales: ['ko', 'en'],
      minAppVersion: '1.0.0',
      status: PackStatus.installed,
      installedAt: row['installed_at'] != null
          ? DateTime.parse(row['installed_at'] as String)
          : null,
      lastPlayedAt: row['last_played_at'] != null
          ? DateTime.parse(row['last_played_at'] as String)
          : null,
    );
  }

  // ==================== Level Progress ====================

  /// 레벨 진행도 저장/업데이트
  Future<void> upsertLevelProgress(LevelProgress progress) async {
    await _db.insert(
      'level_progress',
      progress.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 팩의 레벨 진행도 목록
  Future<List<LevelProgress>> getLevelProgressList(
      String packId, String childId) async {
    final results = await _db.query(
      'level_progress',
      where: 'pack_id = ? AND child_id = ?',
      whereArgs: [packId, childId],
    );
    return results.map((r) => LevelProgress.fromJson(r)).toList();
  }

  /// 특정 레벨 진행도 조회
  Future<LevelProgress?> getLevelProgress(
      String packId, String levelId, String childId) async {
    final results = await _db.query(
      'level_progress',
      where: 'pack_id = ? AND level_id = ? AND child_id = ?',
      whereArgs: [packId, levelId, childId],
    );
    if (results.isEmpty) return null;
    return LevelProgress.fromJson(results.first);
  }

  // ==================== Game Sessions ====================

  /// 게임 세션 저장
  Future<void> insertGameSession(GameResult result) async {
    await _db.insert('game_sessions', result.toJson());
  }

  /// 최근 게임 세션 조회
  Future<List<GameResult>> getRecentSessions(String childId,
      {int limit = 10}) async {
    final results = await _db.query(
      'game_sessions',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return results.map((r) => GameResult.fromJson(r)).toList();
  }
}
