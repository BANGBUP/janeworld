import 'dart:ui' as ui;
import 'dart:io';

import 'package:flame/components.dart';
import 'package:path/path.dart' as path;

import '../data/datasources/local/pack_file_manager.dart';
import '../domain/entities/level_config.dart';

/// 로드된 팩 데이터
class LoadedPack {
  final String packId;
  final PackManifest manifest;
  final Map<String, LevelConfig> levels;
  final Map<String, Map<String, String>> locales;
  final PackAssetBundle assets;

  const LoadedPack({
    required this.packId,
    required this.manifest,
    required this.levels,
    required this.locales,
    required this.assets,
  });

  LevelConfig? getLevel(String levelId) => levels[levelId];

  String getLocalizedString(String key, String locale) {
    return locales[locale]?[key] ??
        locales[manifest.defaultLocale]?[key] ??
        key;
  }

  List<LevelConfig> getLevelsSorted() {
    return levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
  }
}

/// 팩 매니페스트
class PackManifest {
  final String packId;
  final String version;
  final Map<String, String> name;
  final Map<String, String> description;
  final String author;
  final String gameType;
  final int totalLevels;
  final String levelsIndexPath;
  final bool supportsCharacterIntegration;
  final String defaultLocale;
  final List<String> supportedLocales;
  final String minAppVersion;
  final int storageSizeMb;
  final int minAge;
  final int maxAge;
  final List<String> skillTags;

  const PackManifest({
    required this.packId,
    required this.version,
    required this.name,
    required this.description,
    required this.author,
    required this.gameType,
    required this.totalLevels,
    required this.levelsIndexPath,
    required this.supportsCharacterIntegration,
    required this.defaultLocale,
    required this.supportedLocales,
    required this.minAppVersion,
    required this.storageSizeMb,
    required this.minAge,
    required this.maxAge,
    required this.skillTags,
  });

  factory PackManifest.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final requirements = json['requirements'] as Map<String, dynamic>? ?? {};
    final targeting = json['targeting'] as Map<String, dynamic>? ?? {};
    final content = json['content'] as Map<String, dynamic>? ?? {};

    return PackManifest(
      packId: json['pack_id'] as String,
      version: json['version'] as String,
      name: Map<String, String>.from(metadata['name'] ?? json['name'] ?? {}),
      description: Map<String, String>.from(
          metadata['description'] ?? json['description'] ?? {}),
      author: metadata['author'] as String? ?? 'Unknown',
      gameType: content['game_type'] as String? ??
          json['game_type'] as String? ??
          'unknown',
      totalLevels: content['total_levels'] as int? ?? 0,
      levelsIndexPath:
          content['levels_index'] as String? ?? 'levels/index.json',
      supportsCharacterIntegration:
          content['supports_character_integration'] as bool? ?? false,
      defaultLocale: content['default_locale'] as String? ?? 'ko',
      supportedLocales:
          List<String>.from(content['supported_locales'] ?? ['ko']),
      minAppVersion: requirements['min_app_version'] as String? ?? '1.0.0',
      storageSizeMb: requirements['storage_size_mb'] as int? ?? 0,
      minAge: targeting['age_range']?['min'] as int? ?? 0,
      maxAge: targeting['age_range']?['max'] as int? ?? 99,
      skillTags: List<String>.from(targeting['skill_tags'] ?? []),
    );
  }
}

/// 팩 에셋 번들
class PackAssetBundle {
  final String basePath;
  final Map<String, ui.Image> _imageCache = {};

  PackAssetBundle({required this.basePath});

  /// 이미지 로드
  Future<ui.Image> loadImage(String relativePath) async {
    final fullPath = path.join(basePath, relativePath);

    if (_imageCache.containsKey(fullPath)) {
      return _imageCache[fullPath]!;
    }

    final bytes = await File(fullPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    _imageCache[fullPath] = frame.image;
    return frame.image;
  }

  /// Flame용 스프라이트 로드
  Future<Sprite> loadSprite(String relativePath) async {
    final image = await loadImage(relativePath);
    return Sprite(image);
  }

  /// 에셋 전체 경로 반환
  String getAssetPath(String relativePath) {
    return path.join(basePath, relativePath);
  }

  /// 에셋 파일 존재 확인
  Future<bool> assetExists(String relativePath) async {
    final fullPath = path.join(basePath, relativePath);
    return await File(fullPath).exists();
  }

  /// 리소스 해제
  void dispose() {
    _imageCache.clear();
  }
}

/// 런타임 팩 로더
class PackLoader {
  final PackFileManager _fileManager;
  final Map<String, LoadedPack> _cache = {};

  PackLoader({required PackFileManager fileManager})
      : _fileManager = fileManager;

  /// 팩 로드 (캐시 활용)
  Future<LoadedPack> loadPack(String packId) async {
    if (_cache.containsKey(packId)) {
      return _cache[packId]!;
    }

    final packPath = _fileManager.getPackPath(packId);

    // 1. Manifest 로드
    final manifestJson = await _fileManager.readJson(
      path.join(packPath, 'manifest.json'),
    );
    final manifest = PackManifest.fromJson(manifestJson);

    // 2. 레벨 인덱스 로드
    final levelsIndexPath = path.join(packPath, manifest.levelsIndexPath);
    final levelsIndexJson = await _fileManager.readJson(levelsIndexPath);
    final levelRefs =
        List<Map<String, dynamic>>.from(levelsIndexJson['levels'] ?? []);

    // 3. 개별 레벨 설정 로드
    final levels = <String, LevelConfig>{};
    for (final levelRef in levelRefs) {
      final configPath = levelRef['config_path'] as String;
      final levelJson = await _fileManager.readJson(
        path.join(packPath, configPath),
      );
      final levelConfig = LevelConfig.fromJson(levelJson);
      levels[levelConfig.levelId] = levelConfig;
    }

    // 4. 로케일 로드
    final locales = <String, Map<String, String>>{};
    for (final locale in manifest.supportedLocales) {
      try {
        final localePath = path.join(packPath, 'locales', '$locale.json');
        final localeJson = await _fileManager.readJson(localePath);
        locales[locale] = Map<String, String>.from(localeJson['strings'] ?? {});
      } catch (_) {
        // 로케일 파일이 없으면 무시
      }
    }

    // 5. 에셋 번들 생성
    final assetBundle = PackAssetBundle(basePath: packPath);

    final loadedPack = LoadedPack(
      packId: packId,
      manifest: manifest,
      levels: levels,
      locales: locales,
      assets: assetBundle,
    );

    _cache[packId] = loadedPack;
    return loadedPack;
  }

  /// 특정 레벨만 로드
  Future<LevelConfig> loadLevel(String packId, String levelId) async {
    final pack = await loadPack(packId);
    final level = pack.levels[levelId];
    if (level == null) {
      throw Exception('Level not found: $levelId in pack $packId');
    }
    return level;
  }

  /// 캐시에서 제거
  void unloadPack(String packId) {
    final pack = _cache.remove(packId);
    pack?.assets.dispose();
  }

  /// 전체 캐시 클리어
  void clearCache() {
    for (final pack in _cache.values) {
      pack.assets.dispose();
    }
    _cache.clear();
  }

  /// 팩 로드 여부 확인
  bool isPackLoaded(String packId) => _cache.containsKey(packId);
}
