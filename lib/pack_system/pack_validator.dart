import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// 팩 검증 결과
class PackValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const PackValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// 팩 파일 검증
class PackValidator {
  // 허용된 파일 확장자
  static const _allowedImageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
  static const _allowedAudioExtensions = ['.mp3', '.ogg', '.wav', '.m4a', '.aac'];
  static const _allowedAnimationExtensions = ['.json', '.riv'];
  static const _allowedTextExtensions = ['.json', '.txt'];

  /// 다운로드된 팩 파일의 SHA-256 해시 검증
  Future<bool> validatePackFileHash(String filePath, String expectedHash) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = 'sha256:${digest}';

    return actualHash == expectedHash;
  }

  /// 팩 파일 기본 검증 (해시 없이)
  Future<bool> validatePackFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    // 최소 크기 검사 (빈 ZIP 파일 방지)
    final size = await file.length();
    if (size < 100) {
      return false;
    }

    // ZIP 매직 넘버 확인
    final bytes = await file.openRead(0, 4).first;
    if (bytes.length < 4) return false;

    // ZIP 파일 시그니처: 0x50 0x4B 0x03 0x04
    return bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }

  /// 설치된 팩 구조 검증
  Future<PackValidationResult> validateInstalledPack(String packPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. manifest.json 존재 확인
    final manifestFile = File(path.join(packPath, 'manifest.json'));
    if (!await manifestFile.exists()) {
      errors.add('manifest.json not found');
      return PackValidationResult(isValid: false, errors: errors);
    }

    // 2. manifest 파싱 및 스키마 검증
    try {
      final manifestContent = await manifestFile.readAsString();
      final manifestJson = jsonDecode(manifestContent) as Map<String, dynamic>;

      // 필수 필드 확인
      final requiredFields = ['pack_id', 'version'];
      for (final field in requiredFields) {
        if (!manifestJson.containsKey(field)) {
          errors.add('Missing required field in manifest: $field');
        }
      }

      // 3. 레벨 인덱스 파일 확인
      final content = manifestJson['content'] as Map<String, dynamic>?;
      final levelsIndexPath = content?['levels_index'] as String? ?? 'levels/index.json';
      final levelsIndexFile = File(path.join(packPath, levelsIndexPath));

      if (!await levelsIndexFile.exists()) {
        errors.add('Levels index file not found: $levelsIndexPath');
      } else {
        // 레벨 파일들 확인
        try {
          final levelsIndexContent = await levelsIndexFile.readAsString();
          final levelsIndex = jsonDecode(levelsIndexContent) as Map<String, dynamic>;
          final levels = levelsIndex['levels'] as List<dynamic>?;

          if (levels != null) {
            for (final level in levels) {
              final configPath = level['config_path'] as String?;
              if (configPath != null) {
                final levelFile = File(path.join(packPath, configPath));
                if (!await levelFile.exists()) {
                  warnings.add('Level config file not found: $configPath');
                }
              }
            }
          }
        } catch (e) {
          errors.add('Failed to parse levels index: $e');
        }
      }

      // 4. 파일 타입 검증
      final fileTypeResult = await validateFileTypes(packPath);
      if (!fileTypeResult.isValid) {
        errors.addAll(fileTypeResult.errors);
      }

    } catch (e) {
      errors.add('Failed to parse manifest: $e');
    }

    return PackValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 팩 내 파일 확장자 검증
  Future<PackValidationResult> validateFileTypes(String packPath) async {
    final errors = <String>[];
    final directory = Directory(packPath);

    if (!await directory.exists()) {
      return PackValidationResult(
        isValid: false,
        errors: ['Pack directory not found'],
      );
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        final relativePath = path.relative(entity.path, from: packPath);

        // JSON, 텍스트, 이미지, 오디오, 애니메이션만 허용
        final isAllowed = _allowedTextExtensions.contains(extension) ||
            _allowedImageExtensions.contains(extension) ||
            _allowedAudioExtensions.contains(extension) ||
            _allowedAnimationExtensions.contains(extension);

        if (!isAllowed && extension.isNotEmpty) {
          errors.add('Unsupported file type: $relativePath');
        }

        // 경로 탐색 공격 검사
        if (relativePath.contains('..')) {
          errors.add('Invalid path detected: $relativePath');
        }
      }
    }

    return PackValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 경로 안전성 검사
  bool isPathSafe(String relativePath) {
    // ../ 또는 절대 경로 차단
    if (relativePath.contains('..') || path.isAbsolute(relativePath)) {
      return false;
    }
    return true;
  }
}
