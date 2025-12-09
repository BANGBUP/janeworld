import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// 팩 파일 시스템 관리
class PackFileManager {
  final String packsDirectory;
  final String downloadsDirectory;

  PackFileManager({
    required this.packsDirectory,
    required this.downloadsDirectory,
  });

  /// 초기화 - 필요한 디렉토리 생성
  Future<void> init() async {
    await Directory(packsDirectory).create(recursive: true);
    await Directory(downloadsDirectory).create(recursive: true);
  }

  /// 팩 디렉토리 경로
  String getPackPath(String packId) {
    return path.join(packsDirectory, packId);
  }

  /// 다운로드 임시 파일 경로
  String getDownloadTempPath(String packId) {
    return path.join(downloadsDirectory, '$packId.janepack.tmp');
  }

  /// 팩이 설치되어 있는지 확인
  Future<bool> isPackInstalled(String packId) async {
    final packDir = Directory(getPackPath(packId));
    final manifestFile = File(path.join(packDir.path, 'manifest.json'));
    return await packDir.exists() && await manifestFile.exists();
  }

  /// JSON 파일 읽기
  Future<Map<String, dynamic>> readJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// JSON 파일 쓰기
  Future<void> writeJson(String filePath, Map<String, dynamic> data) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  /// 팩 압축 해제 및 설치
  Future<void> extractPack(String packId, String archivePath) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw FileSystemException('Archive not found', archivePath);
    }

    final bytes = await archiveFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final packDir = Directory(getPackPath(packId));

    // 기존 팩 삭제
    if (await packDir.exists()) {
      await packDir.delete(recursive: true);
    }
    await packDir.create(recursive: true);

    // 압축 해제
    for (final file in archive) {
      final filename = file.name;

      // 보안: 경로 탐색 공격 방지
      if (filename.contains('..')) {
        continue;
      }

      final filePath = path.join(packDir.path, filename);

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  /// 팩 삭제
  Future<void> deletePack(String packId) async {
    final packDir = Directory(getPackPath(packId));
    if (await packDir.exists()) {
      await packDir.delete(recursive: true);
    }
  }

  /// 다운로드 임시 파일 삭제
  Future<void> cleanupDownload(String packId) async {
    final tempFile = File(getDownloadTempPath(packId));
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  /// 팩 저장 용량 계산 (MB)
  Future<int> getPackSize(String packId) async {
    final packDir = Directory(getPackPath(packId));
    if (!await packDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in packDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return (totalSize / 1024 / 1024).ceil();
  }

  /// 전체 팩 저장 용량 계산 (MB)
  Future<int> getTotalPacksSize() async {
    final packsDir = Directory(packsDirectory);
    if (!await packsDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in packsDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return (totalSize / 1024 / 1024).ceil();
  }

  /// 파일 존재 확인
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// 파일 바이트 읽기
  Future<List<int>> readBytes(String filePath) async {
    return await File(filePath).readAsBytes();
  }

  /// 설치된 팩 ID 목록
  Future<List<String>> getInstalledPackIds() async {
    final packsDir = Directory(packsDirectory);
    if (!await packsDir.exists()) return [];

    final packIds = <String>[];
    await for (final entity in packsDir.list()) {
      if (entity is Directory) {
        final packId = path.basename(entity.path);
        final manifestFile = File(path.join(entity.path, 'manifest.json'));
        if (await manifestFile.exists()) {
          packIds.add(packId);
        }
      }
    }
    return packIds;
  }
}
