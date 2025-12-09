import 'package:equatable/equatable.dart';

/// 게임팩 상태
enum PackStatus {
  available,       // 다운로드 가능
  downloading,     // 다운로드 중
  installing,      // 설치 중
  installed,       // 설치됨
  updateAvailable, // 업데이트 있음
  error,           // 오류 상태
}

/// 게임팩 엔티티
class GamePack extends Equatable {
  final String packId;
  final String version;
  final Map<String, String> name;
  final Map<String, String> description;
  final String author;
  final String gameType;
  final int totalLevels;
  final int storageSizeMb;
  final int minAge;
  final int maxAge;
  final List<String> skillTags;
  final String difficulty;
  final int estimatedPlayTimeMinutes;
  final String? thumbnailPath;
  final String? iconPath;
  final List<String> supportedLocales;
  final String minAppVersion;
  final PackStatus status;
  final DateTime? installedAt;
  final DateTime? lastPlayedAt;
  final double downloadProgress;

  const GamePack({
    required this.packId,
    required this.version,
    required this.name,
    required this.description,
    required this.author,
    required this.gameType,
    required this.totalLevels,
    required this.storageSizeMb,
    required this.minAge,
    required this.maxAge,
    required this.skillTags,
    required this.difficulty,
    required this.estimatedPlayTimeMinutes,
    this.thumbnailPath,
    this.iconPath,
    required this.supportedLocales,
    required this.minAppVersion,
    this.status = PackStatus.available,
    this.installedAt,
    this.lastPlayedAt,
    this.downloadProgress = 0,
  });

  String getLocalizedName(String locale) =>
      name[locale] ?? name['en'] ?? name.values.first;

  String getLocalizedDescription(String locale) =>
      description[locale] ?? description['en'] ?? description.values.first;

  bool get isInstalled => status == PackStatus.installed;
  bool get isDownloading => status == PackStatus.downloading;
  bool get hasUpdate => status == PackStatus.updateAvailable;

  GamePack copyWith({
    String? packId,
    String? version,
    Map<String, String>? name,
    Map<String, String>? description,
    String? author,
    String? gameType,
    int? totalLevels,
    int? storageSizeMb,
    int? minAge,
    int? maxAge,
    List<String>? skillTags,
    String? difficulty,
    int? estimatedPlayTimeMinutes,
    String? thumbnailPath,
    String? iconPath,
    List<String>? supportedLocales,
    String? minAppVersion,
    PackStatus? status,
    DateTime? installedAt,
    DateTime? lastPlayedAt,
    double? downloadProgress,
  }) {
    return GamePack(
      packId: packId ?? this.packId,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      gameType: gameType ?? this.gameType,
      totalLevels: totalLevels ?? this.totalLevels,
      storageSizeMb: storageSizeMb ?? this.storageSizeMb,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      skillTags: skillTags ?? this.skillTags,
      difficulty: difficulty ?? this.difficulty,
      estimatedPlayTimeMinutes:
          estimatedPlayTimeMinutes ?? this.estimatedPlayTimeMinutes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      iconPath: iconPath ?? this.iconPath,
      supportedLocales: supportedLocales ?? this.supportedLocales,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      status: status ?? this.status,
      installedAt: installedAt ?? this.installedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  List<Object?> get props => [
        packId,
        version,
        name,
        description,
        author,
        gameType,
        totalLevels,
        storageSizeMb,
        minAge,
        maxAge,
        skillTags,
        difficulty,
        estimatedPlayTimeMinutes,
        thumbnailPath,
        iconPath,
        supportedLocales,
        minAppVersion,
        status,
        installedAt,
        lastPlayedAt,
        downloadProgress,
      ];
}
