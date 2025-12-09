import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/datasources/local/pack_database.dart';
import '../data/datasources/local/pack_file_manager.dart';
import '../domain/entities/game_pack.dart';
import 'download_manager.dart';
import 'pack_validator.dart';
import 'pack_loader.dart';

/// 게임팩 생명주기 관리
class PackManager {
  final PackDatabase _packDatabase;
  final PackFileManager _fileManager;
  final DownloadManager _downloadManager;
  final PackValidator _validator;
  final Dio _dio;

  // 다운로드 진행률 스트림
  final _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  PackManager({
    required PackDatabase packDatabase,
    required PackFileManager fileManager,
    required DownloadManager downloadManager,
    required PackValidator validator,
    required Dio dio,
  })  : _packDatabase = packDatabase,
        _fileManager = fileManager,
        _downloadManager = downloadManager,
        _validator = validator,
        _dio = dio;

  /// 다운로드 진행률 스트림
  Stream<DownloadProgress> get downloadProgress =>
      _downloadProgressController.stream;

  /// 설치된 팩 목록 조회
  Future<List<GamePack>> getInstalledPacks() async {
    return _packDatabase.getInstalledPacks();
  }

  /// 특정 팩 조회
  Future<GamePack?> getInstalledPack(String packId) async {
    return _packDatabase.getInstalledPack(packId);
  }

  /// 팩 설치 여부 확인
  Future<bool> isPackInstalled(String packId) async {
    return await _fileManager.isPackInstalled(packId);
  }

  /// 서버에서 사용 가능한 팩 목록 조회
  Future<List<GamePack>> fetchAvailablePacks({
    String? baseUrl,
    List<String>? skillTags,
    int? minAge,
    int? maxAge,
  }) async {
    // TODO: 실제 서버 API 연동
    // 현재는 빈 목록 반환 (내장 팩만 사용)
    return [];
  }

  /// 팩 다운로드 시작
  Stream<DownloadProgress> downloadPack({
    required String packId,
    required String downloadUrl,
    required int expectedSizeBytes,
  }) async* {
    yield* _downloadManager.download(
      url: downloadUrl,
      packId: packId,
      expectedSize: expectedSizeBytes,
    );
  }

  /// 팩 설치 (다운로드 완료 후)
  Future<void> installPack(String packId) async {
    final downloadPath = _downloadManager.getDownloadPath(packId);

    // 1. 파일 검증
    final isValid = await _validator.validatePackFile(downloadPath);
    if (!isValid) {
      throw PackInstallException('Pack file validation failed');
    }

    // 2. 압축 해제 및 설치
    await _fileManager.extractPack(packId, downloadPath);

    // 3. 설치된 팩 구조 검증
    final packPath = _fileManager.getPackPath(packId);
    final validation = await _validator.validateInstalledPack(packPath);
    if (!validation.isValid) {
      // 설치 실패시 정리
      await _fileManager.deletePack(packId);
      throw PackInstallException(
          'Pack structure validation failed: ${validation.errors.join(", ")}');
    }

    // 4. manifest 읽기
    final manifestJson = await _fileManager.readJson('$packPath/manifest.json');
    final manifest = PackManifest.fromJson(manifestJson);

    // 5. 데이터베이스에 등록
    final pack = GamePack(
      packId: manifest.packId,
      version: manifest.version,
      name: manifest.name,
      description: manifest.description,
      author: manifest.author,
      gameType: manifest.gameType,
      totalLevels: manifest.totalLevels,
      storageSizeMb: manifest.storageSizeMb,
      minAge: manifest.minAge,
      maxAge: manifest.maxAge,
      skillTags: manifest.skillTags,
      difficulty: 'normal',
      estimatedPlayTimeMinutes: 30,
      supportedLocales: manifest.supportedLocales,
      minAppVersion: manifest.minAppVersion,
      status: PackStatus.installed,
    );

    await _packDatabase.insertInstalledPack(pack, jsonEncode(manifestJson));

    // 6. 임시 파일 정리
    await _downloadManager.cleanup(packId);
  }

  /// 내장 팩 설치 (assets에서 복사)
  Future<void> installBuiltInPack(String packId, String assetPath) async {
    // 내장 팩은 이미 압축 해제된 상태로 assets에 포함
    // TODO: 실제 앱에서는 assets에서 복사하는 로직 필요
  }

  /// 팩 제거
  Future<void> uninstallPack(String packId) async {
    // 1. 파일 시스템에서 삭제
    await _fileManager.deletePack(packId);

    // 2. 데이터베이스에서 삭제
    await _packDatabase.deleteInstalledPack(packId);
  }

  /// 팩 업데이트 확인
  Future<List<GamePack>> checkUpdates() async {
    final installed = await getInstalledPacks();
    final updates = <GamePack>[];

    // TODO: 서버에서 버전 정보 조회하여 비교

    return updates;
  }

  /// 마지막 플레이 시간 업데이트
  Future<void> updateLastPlayedAt(String packId) async {
    await _packDatabase.updateLastPlayedAt(packId);
  }

  /// 전체 팩 저장 용량
  Future<int> getTotalStorageUsage() async {
    return await _fileManager.getTotalPacksSize();
  }

  /// 다운로드 취소
  void cancelDownload(String packId) {
    _downloadManager.cancel(packId);
  }

  void dispose() {
    _downloadProgressController.close();
  }
}

/// 팩 설치 예외
class PackInstallException implements Exception {
  final String message;

  PackInstallException(this.message);

  @override
  String toString() => 'PackInstallException: $message';
}
