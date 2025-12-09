import 'package:dio/dio.dart';

import '../../domain/entities/game_pack.dart';
import '../../domain/entities/game_result.dart';

/// 웹용 PackDatabase stub
class WebPackDatabase {
  Future<List<GamePack>> getInstalledPacks() async => [];
  Future<GamePack?> getInstalledPack(String packId) async => null;
  Future<List<LevelProgress>> getLevelProgressList(String packId, String childId) async => [];
  Future<LevelProgress?> getLevelProgress(String packId, String levelId, String childId) async => null;
  Future<void> insertGameSession(GameResult result) async {}
  Future<void> upsertLevelProgress(LevelProgress progress) async {}
  Future<void> updateLastPlayedAt(String packId) async {}
}

/// 웹 플랫폼 - 로컬 DB/파일 시스템 미지원
class NativeServices {
  static final WebPackDatabase packDatabase = WebPackDatabase();
}

Future<void> initPlatform(Dio dio) async {
  // 웹에서는 로컬 DB 초기화 불필요
}
