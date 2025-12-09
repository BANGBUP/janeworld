# 동적 게임팩 확장 시스템 상세 설계 문서

## 목차

1. [개요](#1-개요)
2. [시스템 아키텍처](#2-시스템-아키텍처)
3. [게임팩 포맷 명세](#3-게임팩-포맷-명세)
4. [클라이언트 앱 구조](#4-클라이언트-앱-구조)
5. [핵심 클래스 설계](#5-핵심-클래스-설계)
6. [데이터베이스 스키마](#6-데이터베이스-스키마)
7. [서버 API 명세](#7-서버-api-명세)
8. [다운로드 및 설치 플로우](#8-다운로드-및-설치-플로우)
9. [게임 실행 플로우](#9-게임-실행-플로우)
10. [오프라인 지원](#10-오프라인-지원)
11. [보안 고려사항](#11-보안-고려사항)
12. [버전 관리 및 업데이트](#12-버전-관리-및-업데이트)
13. [에러 처리](#13-에러-처리)
14. [성능 최적화](#14-성능-최적화)

---

## 1. 개요

### 1.1 목표

앱을 재설치하거나 업데이트하지 않고도 새로운 게임 콘텐츠(게임팩)를 다운로드하여 즉시 사용할 수 있는 확장 시스템을 구축한다.

### 1.2 핵심 원칙

| 원칙 | 설명 |
|-----|------|
| **엔진-콘텐츠 분리** | 게임 로직(엔진)은 앱에 내장, 콘텐츠(레벨, 에셋)는 팩으로 분리 |
| **데이터 드리븐** | 모든 게임 설정은 JSON으로 정의, 코드 변경 없이 콘텐츠 확장 |
| **오프라인 우선** | 한번 다운로드한 팩은 인터넷 없이도 완전히 동작 |
| **점진적 다운로드** | 필요한 팩만 다운로드하여 저장공간 효율화 |

### 1.3 용어 정의

- **Game Pack (게임팩)**: 특정 학습 콘텐츠를 담은 독립적인 패키지
- **Game Engine (게임 엔진)**: 특정 유형의 게임을 실행하는 Flame 기반 런타임
- **Manifest**: 게임팩의 메타데이터와 구조를 정의하는 JSON 파일
- **Level Config**: 개별 레벨의 설정을 담은 JSON 파일

---

## 2. 시스템 아키텍처

### 2.1 전체 구조도

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              클라이언트 앱                               │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Flutter   │  │    Flame    │  │  Pack Core  │  │   Storage   │   │
│  │     UI      │  │   Engine    │  │   System    │  │   Manager   │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│         │                │                │                │           │
│         └────────────────┴────────────────┴────────────────┘           │
│                                    │                                    │
│  ┌─────────────────────────────────┴─────────────────────────────────┐ │
│  │                        Game Pack Runtime                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │ │
│  │  │ Built-in │  │ Pack #1  │  │ Pack #2  │  │ Pack #N  │         │ │
│  │  │   Pack   │  │(다운로드) │  │(다운로드) │  │(다운로드) │         │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘         │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              백엔드 서버                                 │
├──────────────────┬──────────────────┬───────────────────────────────────┤
│    API Server    │   Pack Registry  │           CDN/Storage             │
│  (팩 목록/인증)   │   (버전 관리)    │         (팩 파일 호스팅)           │
└──────────────────┴──────────────────┴───────────────────────────────────┘
```

### 2.2 레이어 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                          │
│  (Flutter Widgets, Screens, Pack Store UI, Game UI)            │
├─────────────────────────────────────────────────────────────────┤
│                     Application Layer                           │
│  (Use Cases, Game Launcher, Pack Manager, Download Manager)    │
├─────────────────────────────────────────────────────────────────┤
│                       Domain Layer                              │
│  (Entities, Game Interfaces, Pack Models, Business Logic)      │
├─────────────────────────────────────────────────────────────────┤
│                        Data Layer                               │
│  (Repositories, Local DB, File System, API Client)             │
├─────────────────────────────────────────────────────────────────┤
│                     Infrastructure Layer                        │
│  (Flame Engine, SQLite, HTTP Client, File I/O)                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 게임팩 포맷 명세

### 3.1 팩 파일 구조

게임팩은 `.janepack` 확장자를 가진 ZIP 압축 파일이다.

```
korean_numbers_v1.janepack (ZIP)
│
├── manifest.json                 # 필수: 팩 메타데이터
├── icon.png                      # 필수: 팩 아이콘 (256x256)
├── thumbnail.png                 # 필수: 썸네일 (512x288)
│
├── levels/                       # 필수: 레벨 설정들
│   ├── index.json               # 레벨 목록 및 순서
│   ├── level_001.json
│   ├── level_002.json
│   └── ...
│
├── assets/                       # 필수: 에셋 파일들
│   ├── images/
│   │   ├── sprites/             # 게임 스프라이트
│   │   ├── backgrounds/         # 배경 이미지
│   │   ├── ui/                  # UI 요소
│   │   └── items/               # 아이템 이미지
│   │
│   ├── audio/
│   │   ├── bgm/                 # 배경 음악
│   │   ├── sfx/                 # 효과음
│   │   └── voice/               # 음성 (TTS 또는 녹음)
│   │       ├── ko/              # 한국어
│   │       └── en/              # 영어
│   │
│   └── animations/              # Lottie/Rive 애니메이션
│       └── *.json or *.riv
│
├── locales/                      # 선택: 다국어 지원
│   ├── ko.json
│   └── en.json
│
└── scripts/                      # 선택: 게임 로직 확장
    └── custom_logic.json        # 선언적 로직 정의
```

### 3.2 manifest.json 명세

```json
{
  "$schema": "https://janeworld.app/schemas/pack-manifest-v1.json",

  "pack_id": "korean_numbers_basic",
  "version": "1.2.0",
  "pack_format_version": 1,

  "metadata": {
    "name": {
      "ko": "숫자 나라 대모험",
      "en": "Number Adventure"
    },
    "description": {
      "ko": "1부터 20까지 숫자를 재미있게 배워요!",
      "en": "Learn numbers 1-20 in a fun way!"
    },
    "author": "JaneWorld Team",
    "created_at": "2024-01-15T00:00:00Z",
    "updated_at": "2024-03-20T00:00:00Z"
  },

  "requirements": {
    "min_app_version": "1.0.0",
    "required_engines": ["NumberLetterGame"],
    "required_features": ["audio", "touch"],
    "storage_size_mb": 45
  },

  "targeting": {
    "age_range": {
      "min": 3,
      "max": 6
    },
    "skill_tags": ["number", "counting", "korean", "memory"],
    "difficulty": "beginner",
    "estimated_play_time_minutes": 30
  },

  "content": {
    "game_type": "NumberLetterGame",
    "total_levels": 20,
    "levels_index": "levels/index.json",
    "supports_character_integration": true,
    "default_locale": "ko",
    "supported_locales": ["ko", "en"]
  },

  "assets": {
    "icon": "icon.png",
    "thumbnail": "thumbnail.png",
    "preview_images": [
      "assets/images/preview_1.png",
      "assets/images/preview_2.png"
    ]
  },

  "monetization": {
    "type": "free",
    "iap_product_id": null
  }
}
```

### 3.3 레벨 설정 파일 (level_XXX.json)

#### 3.3.1 공통 레벨 구조

```json
{
  "level_id": "level_001",
  "level_number": 1,

  "metadata": {
    "title": { "ko": "숫자 1 배우기", "en": "Learn Number 1" },
    "description": { "ko": "숫자 1을 알아봐요" },
    "difficulty": 1,
    "estimated_time_seconds": 60
  },

  "unlock_condition": {
    "type": "none"
  },

  "game_config": {
    "type": "NumberLetterGame",
    "mode": "learning",
    "settings": { }
  },

  "assets": {
    "background": "assets/images/backgrounds/sky.png",
    "bgm": "assets/audio/bgm/happy.mp3"
  },

  "rewards": {
    "stars_possible": 3,
    "completion_xp": 10
  }
}
```

#### 3.3.2 게임 타입별 game_config 예시

**NumberLetterGame (숫자/문자 학습):**
```json
{
  "game_config": {
    "type": "NumberLetterGame",
    "mode": "counting",
    "settings": {
      "target_number": 5,
      "count_objects": "apple",
      "object_image": "assets/images/items/apple.png",
      "show_hint": true,
      "choices": [3, 4, 5, 6],
      "voice_prompt": "assets/audio/voice/ko/count_apples.mp3",
      "success_animation": "assets/animations/star_burst.json",
      "time_limit_seconds": null
    }
  }
}
```

**ShapeColorGame (모양/색깔 맞추기):**
```json
{
  "game_config": {
    "type": "ShapeColorGame",
    "mode": "match",
    "settings": {
      "target": {
        "shape": "circle",
        "color": "#FF0000",
        "image": "assets/images/sprites/red_circle.png"
      },
      "choices": [
        { "shape": "circle", "color": "#FF0000", "image": "..." },
        { "shape": "square", "color": "#FF0000", "image": "..." },
        { "shape": "circle", "color": "#0000FF", "image": "..." }
      ],
      "match_criteria": ["shape", "color"],
      "drag_and_drop": false,
      "time_limit_seconds": 30
    }
  }
}
```

**PuzzleGame (퍼즐):**
```json
{
  "game_config": {
    "type": "PuzzleGame",
    "mode": "jigsaw",
    "settings": {
      "image": "assets/images/items/elephant.png",
      "use_character": true,
      "grid": { "rows": 2, "cols": 2 },
      "shuffle_level": "medium",
      "show_outline": true,
      "snap_distance": 30
    }
  }
}
```

**MemoryCardGame (메모리 카드):**
```json
{
  "game_config": {
    "type": "MemoryCardGame",
    "mode": "match_pairs",
    "settings": {
      "grid": { "rows": 2, "cols": 3 },
      "card_pairs": [
        {
          "id": "pair_1",
          "card_a": {
            "type": "image",
            "content": "assets/images/items/cat.png"
          },
          "card_b": {
            "type": "text",
            "content": "고양이",
            "voice": "assets/audio/voice/ko/cat.mp3"
          }
        }
      ],
      "flip_duration_ms": 300,
      "mismatch_delay_ms": 1000,
      "max_attempts": null
    }
  }
}
```

**TapCoordinationGame (터치 반응):**
```json
{
  "game_config": {
    "type": "TapCoordinationGame",
    "mode": "whack_a_mole",
    "settings": {
      "spawn_interval_ms": 1500,
      "visible_duration_ms": 2000,
      "target_count": 10,
      "target_image": "assets/images/sprites/mole.png",
      "decoy_image": "assets/images/sprites/flower.png",
      "decoy_ratio": 0.2,
      "use_character_as_target": true,
      "spawn_zones": ["center", "corners"]
    }
  }
}
```

### 3.4 다국어 지원 (locales/ko.json)

```json
{
  "locale": "ko",
  "strings": {
    "pack.title": "숫자 나라 대모험",
    "pack.description": "1부터 20까지 숫자를 재미있게 배워요!",

    "level.001.title": "숫자 1 배우기",
    "level.001.instruction": "사과가 몇 개인지 세어볼까요?",

    "common.correct": "정답이에요!",
    "common.try_again": "다시 해볼까요?",
    "common.well_done": "잘했어요!",

    "voice.instruction_count": "사과를 세어보세요"
  }
}
```

---

## 4. 클라이언트 앱 구조

### 4.1 디렉토리 구조

```
lib/
├── main.dart
├── app.dart
│
├── core/                                 # 핵심 시스템
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── pack_constants.dart
│   │
│   ├── errors/
│   │   ├── app_exception.dart
│   │   ├── pack_exception.dart
│   │   └── game_exception.dart
│   │
│   ├── utils/
│   │   ├── file_utils.dart
│   │   ├── json_utils.dart
│   │   └── crypto_utils.dart
│   │
│   └── di/
│       └── injection_container.dart      # 의존성 주입
│
├── domain/                               # 도메인 레이어
│   ├── entities/
│   │   ├── game_pack.dart
│   │   ├── pack_manifest.dart
│   │   ├── level_config.dart
│   │   ├── game_session.dart
│   │   ├── game_result.dart
│   │   ├── child_profile.dart
│   │   └── character.dart
│   │
│   ├── repositories/
│   │   ├── pack_repository.dart          # 인터페이스
│   │   ├── game_repository.dart
│   │   └── character_repository.dart
│   │
│   └── usecases/
│       ├── pack/
│       │   ├── fetch_available_packs.dart
│       │   ├── download_pack.dart
│       │   ├── install_pack.dart
│       │   ├── uninstall_pack.dart
│       │   └── check_pack_update.dart
│       │
│       └── game/
│           ├── launch_game.dart
│           ├── save_game_result.dart
│           └── get_recommended_games.dart
│
├── data/                                 # 데이터 레이어
│   ├── models/                           # DTO / Data Models
│   │   ├── pack_manifest_model.dart
│   │   ├── level_config_model.dart
│   │   └── api_response_model.dart
│   │
│   ├── repositories/                     # 구현체
│   │   ├── pack_repository_impl.dart
│   │   └── game_repository_impl.dart
│   │
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── pack_local_datasource.dart
│   │   │   ├── pack_database.dart        # SQLite
│   │   │   └── pack_file_manager.dart
│   │   │
│   │   └── remote/
│   │       ├── pack_remote_datasource.dart
│   │       └── pack_api_client.dart
│   │
│   └── mappers/
│       └── pack_mapper.dart
│
├── pack_system/                          # ⭐ 게임팩 핵심 시스템
│   ├── pack_manager.dart                 # 팩 생명주기 관리
│   ├── pack_loader.dart                  # 런타임 로딩
│   ├── pack_validator.dart               # 무결성 검증
│   ├── pack_installer.dart               # 설치/제거
│   ├── asset_resolver.dart               # 에셋 경로 해석
│   ├── download_manager.dart             # 다운로드 관리
│   │
│   └── models/
│       ├── loaded_pack.dart
│       ├── pack_status.dart
│       └── download_progress.dart
│
├── game_engine/                          # ⭐ 게임 엔진 시스템
│   ├── core/
│   │   ├── base_mini_game.dart           # 추상 게임 클래스
│   │   ├── game_registry.dart            # 엔진 등록소
│   │   ├── game_launcher.dart            # 게임 실행기
│   │   ├── game_state_manager.dart       # 상태 관리
│   │   └── game_event_bus.dart           # 이벤트 시스템
│   │
│   ├── common/
│   │   ├── components/
│   │   │   ├── game_background.dart
│   │   │   ├── game_hud.dart
│   │   │   ├── pause_overlay.dart
│   │   │   ├── result_overlay.dart
│   │   │   └── character_sprite.dart
│   │   │
│   │   ├── audio/
│   │   │   └── game_audio_manager.dart
│   │   │
│   │   └── input/
│   │       ├── tap_handler.dart
│   │       └── drag_handler.dart
│   │
│   └── engines/                          # 개별 게임 엔진들
│       ├── shape_color/
│       │   ├── shape_color_engine.dart
│       │   ├── shape_color_config.dart
│       │   └── components/
│       │
│       ├── puzzle/
│       │   ├── puzzle_engine.dart
│       │   └── components/
│       │
│       ├── memory_card/
│       │   ├── memory_card_engine.dart
│       │   └── components/
│       │
│       ├── number_letter/
│       │   ├── number_letter_engine.dart
│       │   └── components/
│       │
│       ├── tap_coordination/
│       │   ├── tap_coordination_engine.dart
│       │   └── components/
│       │
│       └── story_coding/
│           ├── story_coding_engine.dart
│           └── components/
│
├── features/                             # UI 기능별
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── widgets/
│   │   └── bloc/
│   │
│   ├── pack_store/                       # 팩 스토어
│   │   ├── screens/
│   │   │   ├── pack_store_screen.dart
│   │   │   └── pack_detail_screen.dart
│   │   ├── widgets/
│   │   │   ├── pack_card.dart
│   │   │   ├── pack_list.dart
│   │   │   ├── download_button.dart
│   │   │   └── download_progress_indicator.dart
│   │   └── bloc/
│   │       ├── pack_store_bloc.dart
│   │       ├── pack_store_event.dart
│   │       └── pack_store_state.dart
│   │
│   ├── my_packs/                         # 내 게임팩
│   │   ├── screens/
│   │   │   └── my_packs_screen.dart
│   │   └── widgets/
│   │
│   ├── game/                             # 게임 플레이
│   │   ├── screens/
│   │   │   ├── level_select_screen.dart
│   │   │   └── game_screen.dart
│   │   └── widgets/
│   │
│   ├── character/                        # 캐릭터 관리
│   │   └── ...
│   │
│   └── parent/                           # 부모 전용
│       └── ...
│
└── shared/                               # 공유 위젯/유틸
    ├── widgets/
    ├── themes/
    └── extensions/
```

### 4.2 로컬 저장소 구조

```
[앱 데이터 디렉토리]/
├── databases/
│   └── janeworld.db                      # SQLite 데이터베이스
│
├── packs/                                # 설치된 게임팩
│   ├── korean_numbers_basic/
│   │   ├── manifest.json
│   │   ├── icon.png
│   │   ├── levels/
│   │   ├── assets/
│   │   └── locales/
│   │
│   └── animal_puzzle_pack/
│       └── ...
│
├── downloads/                            # 다운로드 임시 폴더
│   └── *.janepack.tmp
│
├── cache/                                # 에셋 캐시
│   ├── images/
│   └── audio/
│
└── characters/                           # 사용자 캐릭터
    └── [child_id]/
        └── [character_id].png
```

---

## 5. 핵심 클래스 설계

### 5.1 도메인 엔티티

#### GamePack
```dart
/// 게임팩 엔티티
class GamePack {
  final String packId;
  final String version;
  final PackMetadata metadata;
  final PackRequirements requirements;
  final PackTargeting targeting;
  final PackContent content;
  final PackStatus status;
  final DateTime? installedAt;
  final DateTime? lastPlayedAt;

  const GamePack({
    required this.packId,
    required this.version,
    required this.metadata,
    required this.requirements,
    required this.targeting,
    required this.content,
    this.status = PackStatus.available,
    this.installedAt,
    this.lastPlayedAt,
  });

  bool get isInstalled => status == PackStatus.installed;
  bool get isDownloading => status == PackStatus.downloading;
  bool get hasUpdate => status == PackStatus.updateAvailable;

  /// 현재 앱 버전과 호환되는지 확인
  bool isCompatibleWith(String appVersion) {
    return Version.parse(appVersion) >=
           Version.parse(requirements.minAppVersion);
  }
}

class PackMetadata {
  final Map<String, String> name;          // 다국어 이름
  final Map<String, String> description;   // 다국어 설명
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;

  String getLocalizedName(String locale) =>
      name[locale] ?? name['en'] ?? name.values.first;
}

class PackRequirements {
  final String minAppVersion;
  final List<String> requiredEngines;
  final List<String> requiredFeatures;
  final int storageSizeMb;
}

class PackTargeting {
  final int minAge;
  final int maxAge;
  final List<String> skillTags;
  final String difficulty;
  final int estimatedPlayTimeMinutes;
}

class PackContent {
  final String gameType;
  final int totalLevels;
  final String levelsIndexPath;
  final bool supportsCharacterIntegration;
  final String defaultLocale;
  final List<String> supportedLocales;
}

enum PackStatus {
  available,       // 다운로드 가능
  downloading,     // 다운로드 중
  installing,      // 설치 중
  installed,       // 설치됨
  updateAvailable, // 업데이트 있음
  error,           // 오류 상태
}
```

#### LevelConfig
```dart
/// 레벨 설정 엔티티
class LevelConfig {
  final String levelId;
  final int levelNumber;
  final LevelMetadata metadata;
  final UnlockCondition unlockCondition;
  final GameConfig gameConfig;
  final LevelAssets assets;
  final LevelRewards rewards;

  const LevelConfig({
    required this.levelId,
    required this.levelNumber,
    required this.metadata,
    required this.unlockCondition,
    required this.gameConfig,
    required this.assets,
    required this.rewards,
  });
}

class LevelMetadata {
  final Map<String, String> title;
  final Map<String, String>? description;
  final int difficulty;
  final int estimatedTimeSeconds;
}

abstract class UnlockCondition {
  bool isSatisfied(PlayerProgress progress);
}

class NoCondition extends UnlockCondition {
  @override
  bool isSatisfied(PlayerProgress progress) => true;
}

class PreviousLevelCondition extends UnlockCondition {
  final String previousLevelId;
  final int minStars;

  @override
  bool isSatisfied(PlayerProgress progress) {
    final result = progress.getLevelResult(previousLevelId);
    return result != null && result.stars >= minStars;
  }
}

class GameConfig {
  final String type;           // 게임 엔진 타입
  final String mode;           // 게임 모드
  final Map<String, dynamic> settings;  // 게임별 설정
}

class LevelAssets {
  final String? background;
  final String? bgm;
  final Map<String, String>? additionalAssets;
}

class LevelRewards {
  final int starsPossible;
  final int completionXp;
}
```

### 5.2 게임팩 시스템

#### PackManager
```dart
/// 게임팩 생명주기 관리
class PackManager {
  final PackRepository _repository;
  final PackInstaller _installer;
  final DownloadManager _downloadManager;
  final PackValidator _validator;

  PackManager({
    required PackRepository repository,
    required PackInstaller installer,
    required DownloadManager downloadManager,
    required PackValidator validator,
  })  : _repository = repository,
        _installer = installer,
        _downloadManager = downloadManager,
        _validator = validator;

  /// 사용 가능한 팩 목록 조회 (서버)
  Future<List<GamePack>> fetchAvailablePacks({
    List<String>? skillTags,
    int? minAge,
    int? maxAge,
  }) async {
    final remotePacks = await _repository.fetchRemotePacks(
      skillTags: skillTags,
      minAge: minAge,
      maxAge: maxAge,
    );

    // 로컬 설치 상태와 병합
    final localPacks = await _repository.getInstalledPacks();
    return _mergePackStatus(remotePacks, localPacks);
  }

  /// 설치된 팩 목록 조회
  Future<List<GamePack>> getInstalledPacks() async {
    return _repository.getInstalledPacks();
  }

  /// 팩 다운로드 시작
  Stream<DownloadProgress> downloadPack(String packId) async* {
    final packInfo = await _repository.getPackInfo(packId);
    final downloadUrl = await _repository.getDownloadUrl(packId);

    yield* _downloadManager.download(
      url: downloadUrl,
      packId: packId,
      expectedSize: packInfo.requirements.storageSizeMb * 1024 * 1024,
    );
  }

  /// 팩 설치
  Future<void> installPack(String packId) async {
    final downloadPath = _downloadManager.getDownloadPath(packId);

    // 1. 무결성 검증
    final isValid = await _validator.validatePackFile(downloadPath);
    if (!isValid) {
      throw PackValidationException('Pack validation failed: $packId');
    }

    // 2. 압축 해제 및 설치
    await _installer.install(packId, downloadPath);

    // 3. 데이터베이스 업데이트
    await _repository.markAsInstalled(packId);

    // 4. 임시 파일 정리
    await _downloadManager.cleanup(packId);
  }

  /// 팩 제거
  Future<void> uninstallPack(String packId) async {
    await _installer.uninstall(packId);
    await _repository.markAsUninstalled(packId);
  }

  /// 업데이트 확인
  Future<List<GamePack>> checkUpdates() async {
    final installed = await getInstalledPacks();
    final updates = <GamePack>[];

    for (final pack in installed) {
      final remote = await _repository.getPackInfo(pack.packId);
      if (Version.parse(remote.version) > Version.parse(pack.version)) {
        updates.add(remote.copyWith(status: PackStatus.updateAvailable));
      }
    }

    return updates;
  }
}
```

#### PackLoader
```dart
/// 런타임 팩 로딩
class PackLoader {
  final PackFileManager _fileManager;
  final AssetResolver _assetResolver;

  final Map<String, LoadedPack> _cache = {};

  PackLoader({
    required PackFileManager fileManager,
    required AssetResolver assetResolver,
  })  : _fileManager = fileManager,
        _assetResolver = assetResolver;

  /// 팩 로드 (캐시 활용)
  Future<LoadedPack> loadPack(String packId) async {
    if (_cache.containsKey(packId)) {
      return _cache[packId]!;
    }

    final packPath = _fileManager.getPackPath(packId);

    // 1. Manifest 로드
    final manifestJson = await _fileManager.readJson(
      '$packPath/manifest.json',
    );
    final manifest = PackManifest.fromJson(manifestJson);

    // 2. 레벨 인덱스 로드
    final levelsIndexJson = await _fileManager.readJson(
      '$packPath/${manifest.content.levelsIndexPath}',
    );
    final levelIndex = LevelIndex.fromJson(levelsIndexJson);

    // 3. 개별 레벨 설정 로드
    final levels = <String, LevelConfig>{};
    for (final levelRef in levelIndex.levels) {
      final levelJson = await _fileManager.readJson(
        '$packPath/${levelRef.configPath}',
      );
      levels[levelRef.levelId] = LevelConfig.fromJson(levelJson);
    }

    // 4. 로케일 로드
    final locales = <String, Map<String, String>>{};
    for (final locale in manifest.content.supportedLocales) {
      final localeJson = await _fileManager.readJson(
        '$packPath/locales/$locale.json',
      );
      locales[locale] = Map<String, String>.from(localeJson['strings']);
    }

    // 5. 에셋 리졸버 초기화
    final assetBundle = PackAssetBundle(
      basePath: packPath,
      resolver: _assetResolver,
    );

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
      throw LevelNotFoundException(packId, levelId);
    }
    return level;
  }

  /// 캐시에서 제거
  void unloadPack(String packId) {
    _cache.remove(packId);
  }

  /// 전체 캐시 클리어
  void clearCache() {
    _cache.clear();
  }
}

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
           locales[manifest.content.defaultLocale]?[key] ??
           key;
  }

  List<LevelConfig> getLevelsSorted() {
    return levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
  }
}
```

#### PackAssetBundle
```dart
/// 팩 에셋 번들
class PackAssetBundle {
  final String basePath;
  final AssetResolver _resolver;

  final Map<String, ui.Image> _imageCache = {};
  final Map<String, AudioSource> _audioCache = {};

  PackAssetBundle({
    required this.basePath,
    required AssetResolver resolver,
  }) : _resolver = resolver;

  /// 이미지 로드
  Future<ui.Image> loadImage(String relativePath) async {
    final fullPath = _resolver.resolve(basePath, relativePath);

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
    final fullPath = _resolver.resolve(basePath, relativePath);
    return Sprite.load(fullPath);
  }

  /// 오디오 로드
  Future<AudioSource> loadAudio(String relativePath) async {
    final fullPath = _resolver.resolve(basePath, relativePath);

    if (_audioCache.containsKey(fullPath)) {
      return _audioCache[fullPath]!;
    }

    final source = AudioSource.file(fullPath);
    _audioCache[fullPath] = source;
    return source;
  }

  /// 리소스 해제
  void dispose() {
    _imageCache.clear();
    _audioCache.clear();
  }
}
```

### 5.3 게임 엔진 시스템

#### BaseMiniGame (추상 클래스)
```dart
/// 모든 미니게임의 기본 클래스
abstract class BaseMiniGame extends FlameGame
    with HasTappables, HasDraggables {

  // 메타데이터
  String get gameId;
  String get gameType;
  List<String> get supportedModes;

  // 상태
  GameState _state = GameState.initial;
  GameState get state => _state;

  // 설정
  late LevelConfig _levelConfig;
  late PackAssetBundle _assets;
  late List<Character> _characters;
  late GameAudioManager _audioManager;

  // 결과
  int _score = 0;
  int _stars = 0;
  int _mistakes = 0;
  DateTime? _startTime;
  Duration? _playDuration;

  /// 게임 초기화
  Future<void> initialize({
    required LevelConfig levelConfig,
    required PackAssetBundle assets,
    required List<Character> characters,
  }) async {
    _levelConfig = levelConfig;
    _assets = assets;
    _characters = characters;
    _audioManager = GameAudioManager(assets);

    await onInitialize();
  }

  /// 서브클래스에서 구현: 초기화 로직
  Future<void> onInitialize();

  /// 서브클래스에서 구현: 게임 설정 파싱
  void parseGameConfig(Map<String, dynamic> settings);

  /// 게임 시작
  void startGame() {
    if (_state != GameState.initial && _state != GameState.ready) {
      return;
    }

    _state = GameState.playing;
    _startTime = DateTime.now();
    _score = 0;
    _mistakes = 0;

    onGameStart();
  }

  /// 서브클래스에서 구현: 게임 시작 로직
  void onGameStart();

  /// 일시정지
  void pauseGame() {
    if (_state != GameState.playing) return;

    _state = GameState.paused;
    pauseEngine();
    _audioManager.pauseAll();

    onGamePause();
  }

  void onGamePause() {}

  /// 재개
  void resumeGame() {
    if (_state != GameState.paused) return;

    _state = GameState.playing;
    resumeEngine();
    _audioManager.resumeAll();

    onGameResume();
  }

  void onGameResume() {}

  /// 게임 종료
  void endGame({required bool completed}) {
    _state = completed ? GameState.completed : GameState.failed;
    _playDuration = DateTime.now().difference(_startTime!);

    _calculateStars();

    onGameEnd(completed);
  }

  void onGameEnd(bool completed) {}

  /// 점수 추가
  void addScore(int points) {
    _score += points;
  }

  /// 실수 기록
  void addMistake() {
    _mistakes++;
  }

  /// 별점 계산 (서브클래스에서 오버라이드 가능)
  void _calculateStars() {
    final maxStars = _levelConfig.rewards.starsPossible;

    if (_mistakes == 0) {
      _stars = maxStars;
    } else if (_mistakes <= 2) {
      _stars = maxStars - 1;
    } else if (_mistakes <= 5) {
      _stars = 1;
    } else {
      _stars = 0;
    }
  }

  /// 게임 결과
  GameResult getResult() {
    return GameResult(
      levelId: _levelConfig.levelId,
      packId: '', // 외부에서 설정
      score: _score,
      stars: _stars,
      mistakes: _mistakes,
      playDuration: _playDuration ?? Duration.zero,
      completedAt: DateTime.now(),
      completed: _state == GameState.completed,
    );
  }

  // 헬퍼 메서드
  Character? get primaryCharacter =>
      _characters.isNotEmpty ? _characters.first : null;

  List<Character> get allCharacters => _characters;

  String getLocalizedString(String key) {
    // PackAssetBundle을 통해 로컬라이즈된 문자열 반환
    return key; // 실제 구현 필요
  }

  @override
  void onRemove() {
    _audioManager.dispose();
    _assets.dispose();
    super.onRemove();
  }
}

enum GameState {
  initial,
  ready,
  playing,
  paused,
  completed,
  failed,
}
```

#### GameRegistry
```dart
/// 게임 엔진 등록소
class GameRegistry {
  static final GameRegistry _instance = GameRegistry._internal();
  factory GameRegistry() => _instance;
  GameRegistry._internal();

  final Map<String, MiniGameFactory> _factories = {};

  /// 초기화 - 앱 시작 시 호출
  void initialize() {
    register('ShapeColorGame', () => ShapeColorEngine());
    register('PuzzleGame', () => PuzzleEngine());
    register('MemoryCardGame', () => MemoryCardEngine());
    register('NumberLetterGame', () => NumberLetterEngine());
    register('TapCoordinationGame', () => TapCoordinationEngine());
    register('StoryCodingGame', () => StoryCodingEngine());
  }

  /// 게임 엔진 등록
  void register(String gameType, MiniGameFactory factory) {
    _factories[gameType] = factory;
  }

  /// 게임 엔진 생성
  BaseMiniGame createGame(String gameType) {
    final factory = _factories[gameType];
    if (factory == null) {
      throw UnsupportedGameException(
        'Game type not registered: $gameType',
      );
    }
    return factory();
  }

  /// 지원되는 게임 타입 목록
  List<String> get supportedGameTypes => _factories.keys.toList();

  /// 특정 게임 타입 지원 여부
  bool isSupported(String gameType) => _factories.containsKey(gameType);
}

typedef MiniGameFactory = BaseMiniGame Function();
```

#### GameLauncher
```dart
/// 게임 실행 관리
class GameLauncher {
  final PackLoader _packLoader;
  final GameRegistry _gameRegistry;
  final CharacterRepository _characterRepository;
  final GameRepository _gameRepository;

  BaseMiniGame? _currentGame;

  GameLauncher({
    required PackLoader packLoader,
    required GameRegistry gameRegistry,
    required CharacterRepository characterRepository,
    required GameRepository gameRepository,
  })  : _packLoader = packLoader,
        _gameRegistry = gameRegistry,
        _characterRepository = characterRepository,
        _gameRepository = gameRepository;

  /// 게임 실행
  Future<BaseMiniGame> launchGame({
    required String packId,
    required String levelId,
    required String childId,
  }) async {
    // 1. 팩 로드
    final loadedPack = await _packLoader.loadPack(packId);

    // 2. 레벨 설정 가져오기
    final levelConfig = loadedPack.getLevel(levelId);
    if (levelConfig == null) {
      throw LevelNotFoundException(packId, levelId);
    }

    // 3. 게임 타입 확인 및 엔진 생성
    final gameType = levelConfig.gameConfig.type;
    if (!_gameRegistry.isSupported(gameType)) {
      throw UnsupportedGameException(
        'This pack requires game engine: $gameType',
      );
    }

    final game = _gameRegistry.createGame(gameType);

    // 4. 캐릭터 로드
    final characters = await _characterRepository.getCharacters(childId);

    // 5. 게임 초기화
    await game.initialize(
      levelConfig: levelConfig,
      assets: loadedPack.assets,
      characters: characters,
    );

    // 6. 게임 설정 파싱
    game.parseGameConfig(levelConfig.gameConfig.settings);

    _currentGame = game;
    return game;
  }

  /// 현재 게임 종료 및 결과 저장
  Future<GameResult> finishCurrentGame() async {
    if (_currentGame == null) {
      throw GameException('No game is currently running');
    }

    final result = _currentGame!.getResult();

    // 결과 저장
    await _gameRepository.saveResult(result);

    _currentGame = null;
    return result;
  }

  /// 현재 게임 참조
  BaseMiniGame? get currentGame => _currentGame;
}
```

### 5.4 개별 게임 엔진 예시

#### NumberLetterEngine
```dart
/// 숫자/문자 학습 게임 엔진
class NumberLetterEngine extends BaseMiniGame {
  @override
  String get gameId => 'number_letter_engine';

  @override
  String get gameType => 'NumberLetterGame';

  @override
  List<String> get supportedModes => [
    'learning',      // 학습 모드
    'counting',      // 세기 모드
    'matching',      // 매칭 모드
    'tracing',       // 따라쓰기 모드
  ];

  // 게임 설정
  late String _mode;
  late int _targetNumber;
  late String _objectType;
  late String _objectImagePath;
  late List<int> _choices;
  late bool _showHint;
  late String? _voicePromptPath;
  late int? _timeLimitSeconds;

  // 게임 컴포넌트
  late List<CountableObject> _objects;
  late List<ChoiceButton> _choiceButtons;
  late PromptText? _promptText;

  @override
  void parseGameConfig(Map<String, dynamic> settings) {
    _mode = settings['mode'] as String? ?? 'counting';
    _targetNumber = settings['target_number'] as int? ?? 1;
    _objectType = settings['count_objects'] as String? ?? 'star';
    _objectImagePath = settings['object_image'] as String? ?? '';
    _choices = List<int>.from(settings['choices'] ?? []);
    _showHint = settings['show_hint'] as bool? ?? false;
    _voicePromptPath = settings['voice_prompt'] as String?;
    _timeLimitSeconds = settings['time_limit_seconds'] as int?;
  }

  @override
  Future<void> onInitialize() async {
    // 배경 설정
    if (_levelConfig.assets.background != null) {
      final bg = GameBackground(
        imagePath: _levelConfig.assets.background!,
        assets: _assets,
      );
      add(bg);
    }

    // 모드별 초기화
    switch (_mode) {
      case 'counting':
        await _initCountingMode();
        break;
      case 'matching':
        await _initMatchingMode();
        break;
      case 'tracing':
        await _initTracingMode();
        break;
      default:
        await _initLearningMode();
    }
  }

  Future<void> _initCountingMode() async {
    // 세기 대상 오브젝트 생성
    _objects = [];
    final objectSprite = await _assets.loadSprite(_objectImagePath);

    for (int i = 0; i < _targetNumber; i++) {
      final obj = CountableObject(
        sprite: objectSprite,
        position: _calculateObjectPosition(i, _targetNumber),
      );
      _objects.add(obj);
      add(obj);
    }

    // 선택지 버튼 생성
    _choiceButtons = [];
    for (int i = 0; i < _choices.length; i++) {
      final button = ChoiceButton(
        value: _choices[i],
        position: _calculateChoicePosition(i, _choices.length),
        onTap: () => _onChoiceSelected(_choices[i]),
      );
      _choiceButtons.add(button);
      add(button);
    }
  }

  void _onChoiceSelected(int selectedValue) {
    if (selectedValue == _targetNumber) {
      // 정답
      addScore(100);
      _audioManager.playCorrect();
      _showSuccessAnimation();

      // 다음 라운드 또는 게임 종료
      Future.delayed(Duration(seconds: 1), () {
        endGame(completed: true);
      });
    } else {
      // 오답
      addMistake();
      _audioManager.playWrong();
      _showWrongAnimation(selectedValue);
    }
  }

  Vector2 _calculateObjectPosition(int index, int total) {
    // 오브젝트 배치 로직
    final screenWidth = size.x;
    final screenHeight = size.y;
    final spacing = screenWidth / (total + 1);

    return Vector2(
      spacing * (index + 1),
      screenHeight * 0.3,
    );
  }

  Vector2 _calculateChoicePosition(int index, int total) {
    final screenWidth = size.x;
    final screenHeight = size.y;
    final spacing = screenWidth / (total + 1);

    return Vector2(
      spacing * (index + 1),
      screenHeight * 0.7,
    );
  }

  void _showSuccessAnimation() {
    // 성공 애니메이션 표시
  }

  void _showWrongAnimation(int wrongValue) {
    // 오답 애니메이션 표시
  }

  Future<void> _initLearningMode() async {
    // 학습 모드 초기화
  }

  Future<void> _initMatchingMode() async {
    // 매칭 모드 초기화
  }

  Future<void> _initTracingMode() async {
    // 따라쓰기 모드 초기화
  }

  @override
  void onGameStart() {
    // 음성 프롬프트 재생
    if (_voicePromptPath != null) {
      _audioManager.playVoice(_voicePromptPath!);
    }
  }
}
```

---

## 6. 데이터베이스 스키마

### 6.1 SQLite 스키마

```sql
-- 설치된 게임팩
CREATE TABLE installed_packs (
    pack_id TEXT PRIMARY KEY,
    version TEXT NOT NULL,
    name_ko TEXT,
    name_en TEXT,
    description_ko TEXT,
    description_en TEXT,
    game_type TEXT NOT NULL,
    total_levels INTEGER NOT NULL,
    storage_size_mb INTEGER NOT NULL,
    min_age INTEGER,
    max_age INTEGER,
    skill_tags TEXT,  -- JSON array
    installed_at TEXT NOT NULL,  -- ISO 8601
    last_played_at TEXT,
    last_updated_at TEXT,
    manifest_json TEXT NOT NULL  -- 전체 manifest 백업
);

-- 팩별 레벨 진행도
CREATE TABLE level_progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pack_id TEXT NOT NULL,
    level_id TEXT NOT NULL,
    child_id TEXT NOT NULL,
    best_score INTEGER DEFAULT 0,
    best_stars INTEGER DEFAULT 0,
    attempts INTEGER DEFAULT 0,
    total_play_time_seconds INTEGER DEFAULT 0,
    first_completed_at TEXT,
    last_played_at TEXT,
    unlocked INTEGER DEFAULT 0,  -- boolean
    FOREIGN KEY (pack_id) REFERENCES installed_packs(pack_id) ON DELETE CASCADE,
    UNIQUE(pack_id, level_id, child_id)
);

-- 게임 세션 기록
CREATE TABLE game_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    pack_id TEXT NOT NULL,
    level_id TEXT NOT NULL,
    child_id TEXT NOT NULL,
    score INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    mistakes INTEGER NOT NULL,
    play_duration_seconds INTEGER NOT NULL,
    completed INTEGER NOT NULL,  -- boolean
    started_at TEXT NOT NULL,
    completed_at TEXT NOT NULL,
    FOREIGN KEY (pack_id) REFERENCES installed_packs(pack_id) ON DELETE CASCADE
);

-- 다운로드 큐
CREATE TABLE download_queue (
    pack_id TEXT PRIMARY KEY,
    download_url TEXT NOT NULL,
    expected_size_bytes INTEGER NOT NULL,
    downloaded_bytes INTEGER DEFAULT 0,
    status TEXT NOT NULL,  -- pending, downloading, paused, completed, failed
    error_message TEXT,
    created_at TEXT NOT NULL,
    started_at TEXT,
    completed_at TEXT
);

-- 팩 캐시 메타데이터
CREATE TABLE pack_cache (
    pack_id TEXT PRIMARY KEY,
    last_server_check TEXT,
    server_version TEXT,
    update_available INTEGER DEFAULT 0
);

-- 인덱스
CREATE INDEX idx_level_progress_child ON level_progress(child_id);
CREATE INDEX idx_level_progress_pack ON level_progress(pack_id);
CREATE INDEX idx_game_sessions_child ON game_sessions(child_id);
CREATE INDEX idx_game_sessions_pack ON game_sessions(pack_id);
CREATE INDEX idx_game_sessions_date ON game_sessions(completed_at);
```

### 6.2 서버 데이터베이스 (PostgreSQL)

```sql
-- 게임팩 레지스트리
CREATE TABLE game_packs (
    pack_id VARCHAR(100) PRIMARY KEY,
    latest_version VARCHAR(20) NOT NULL,
    name_ko VARCHAR(200),
    name_en VARCHAR(200),
    description_ko TEXT,
    description_en TEXT,
    author VARCHAR(100),
    game_type VARCHAR(50) NOT NULL,
    min_app_version VARCHAR(20) NOT NULL,
    total_levels INTEGER NOT NULL,
    storage_size_mb INTEGER NOT NULL,
    min_age INTEGER,
    max_age INTEGER,
    skill_tags TEXT[],
    difficulty VARCHAR(20),
    estimated_play_time_minutes INTEGER,
    thumbnail_url TEXT,
    preview_images TEXT[],
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 팩 버전 관리
CREATE TABLE pack_versions (
    id SERIAL PRIMARY KEY,
    pack_id VARCHAR(100) REFERENCES game_packs(pack_id),
    version VARCHAR(20) NOT NULL,
    download_url TEXT NOT NULL,
    file_hash VARCHAR(64) NOT NULL,  -- SHA-256
    file_size_bytes BIGINT NOT NULL,
    changelog_ko TEXT,
    changelog_en TEXT,
    min_app_version VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pack_id, version)
);

-- 다운로드 통계
CREATE TABLE pack_downloads (
    id SERIAL PRIMARY KEY,
    pack_id VARCHAR(100) REFERENCES game_packs(pack_id),
    version VARCHAR(20),
    user_id UUID,
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    country_code VARCHAR(2),
    downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_packs_game_type ON game_packs(game_type);
CREATE INDEX idx_packs_age ON game_packs(min_age, max_age);
CREATE INDEX idx_packs_featured ON game_packs(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_versions_pack ON pack_versions(pack_id);
CREATE INDEX idx_downloads_pack ON pack_downloads(pack_id);
CREATE INDEX idx_downloads_date ON pack_downloads(downloaded_at);
```

---

## 7. 서버 API 명세

### 7.1 팩 스토어 API

#### 팩 목록 조회
```
GET /api/v1/packs

Query Parameters:
  - page: int (default: 1)
  - limit: int (default: 20, max: 50)
  - game_type: string (optional)
  - skill_tags: string[] (optional, comma-separated)
  - min_age: int (optional)
  - max_age: int (optional)
  - difficulty: string (optional)
  - sort_by: string (optional) - "newest", "popular", "name"
  - locale: string (optional) - "ko", "en"

Response: 200 OK
{
  "success": true,
  "data": {
    "packs": [
      {
        "pack_id": "korean_numbers_basic",
        "version": "1.2.0",
        "name": "숫자 나라 대모험",
        "description": "1부터 20까지 숫자를 재미있게 배워요!",
        "author": "JaneWorld Team",
        "game_type": "NumberLetterGame",
        "thumbnail_url": "https://cdn.janeworld.app/packs/korean_numbers/thumb.png",
        "storage_size_mb": 45,
        "total_levels": 20,
        "min_age": 3,
        "max_age": 6,
        "skill_tags": ["number", "counting", "korean"],
        "difficulty": "beginner",
        "estimated_play_time_minutes": 30,
        "download_count": 15420,
        "rating": 4.8,
        "is_featured": true
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 98,
      "has_next": true
    }
  }
}
```

#### 팩 상세 조회
```
GET /api/v1/packs/{pack_id}

Response: 200 OK
{
  "success": true,
  "data": {
    "pack_id": "korean_numbers_basic",
    "version": "1.2.0",
    "name": { "ko": "숫자 나라 대모험", "en": "Number Adventure" },
    "description": { "ko": "...", "en": "..." },
    "author": "JaneWorld Team",
    "game_type": "NumberLetterGame",
    "min_app_version": "1.0.0",
    "required_engines": ["NumberLetterGame"],
    "thumbnail_url": "...",
    "preview_images": ["...", "..."],
    "storage_size_mb": 45,
    "total_levels": 20,
    "min_age": 3,
    "max_age": 6,
    "skill_tags": ["number", "counting", "korean"],
    "difficulty": "beginner",
    "estimated_play_time_minutes": 30,
    "supported_locales": ["ko", "en"],
    "created_at": "2024-01-15T00:00:00Z",
    "updated_at": "2024-03-20T00:00:00Z",
    "changelog": "- 새로운 레벨 5개 추가\n- 버그 수정",
    "stats": {
      "download_count": 15420,
      "rating": 4.8,
      "rating_count": 342
    }
  }
}
```

#### 다운로드 URL 요청
```
POST /api/v1/packs/{pack_id}/download

Request Body:
{
  "version": "1.2.0",  // optional, 생략시 최신 버전
  "device_type": "android",
  "app_version": "1.5.0"
}

Response: 200 OK
{
  "success": true,
  "data": {
    "download_url": "https://cdn.janeworld.app/packs/korean_numbers_basic_1.2.0.janepack?token=...",
    "expires_at": "2024-03-21T12:00:00Z",
    "file_size_bytes": 47185920,
    "file_hash": "sha256:a1b2c3d4...",
    "version": "1.2.0"
  }
}
```

#### 추천/피처드 팩 조회
```
GET /api/v1/packs/featured

Query Parameters:
  - limit: int (default: 5)
  - child_age: int (optional)
  - locale: string (optional)

Response: 200 OK
{
  "success": true,
  "data": {
    "featured_packs": [...],
    "new_releases": [...],
    "popular_this_week": [...]
  }
}
```

#### 업데이트 확인
```
POST /api/v1/packs/check-updates

Request Body:
{
  "installed_packs": [
    { "pack_id": "korean_numbers_basic", "version": "1.1.0" },
    { "pack_id": "animal_puzzle", "version": "2.0.0" }
  ],
  "app_version": "1.5.0"
}

Response: 200 OK
{
  "success": true,
  "data": {
    "updates_available": [
      {
        "pack_id": "korean_numbers_basic",
        "current_version": "1.1.0",
        "latest_version": "1.2.0",
        "changelog": "- 새로운 레벨 5개 추가",
        "size_mb": 12,
        "is_compatible": true
      }
    ]
  }
}
```

### 7.2 인증 헤더

```
Authorization: Bearer {jwt_token}
X-Device-ID: {unique_device_id}
X-App-Version: 1.5.0
X-Platform: android
Accept-Language: ko
```

### 7.3 에러 응답

```json
{
  "success": false,
  "error": {
    "code": "PACK_NOT_FOUND",
    "message": "요청한 게임팩을 찾을 수 없습니다.",
    "details": {
      "pack_id": "invalid_pack_id"
    }
  }
}
```

에러 코드:
- `PACK_NOT_FOUND`: 팩을 찾을 수 없음
- `VERSION_NOT_FOUND`: 해당 버전 없음
- `INCOMPATIBLE_APP_VERSION`: 앱 버전 호환 불가
- `DOWNLOAD_LIMIT_EXCEEDED`: 다운로드 한도 초과
- `INVALID_REQUEST`: 잘못된 요청

---

## 8. 다운로드 및 설치 플로우

### 8.1 다운로드 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                       다운로드 플로우                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1] 사용자가 팩 선택                                           │
│       │                                                         │
│       ▼                                                         │
│  [2] 호환성 검사                                                │
│       ├── 앱 버전 확인                                         │
│       ├── 필요 엔진 확인                                       │
│       └── 저장 공간 확인                                       │
│       │                                                         │
│       ▼                                                         │
│  [3] 다운로드 URL 요청 (API)                                    │
│       │                                                         │
│       ▼                                                         │
│  [4] 백그라운드 다운로드 시작                                   │
│       ├── 청크 단위 다운로드                                   │
│       ├── 진행률 UI 업데이트                                   │
│       └── 일시정지/재개 지원                                   │
│       │                                                         │
│       ▼                                                         │
│  [5] 다운로드 완료                                              │
│       │                                                         │
│       ▼                                                         │
│  [6] 파일 무결성 검증 (SHA-256)                                 │
│       │                                                         │
│       ▼                                                         │
│  [7] 설치 프로세스 시작                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 설치 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                         설치 플로우                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1] ZIP 압축 해제                                              │
│       └── packs/{pack_id}/ 디렉토리에 추출                     │
│       │                                                         │
│       ▼                                                         │
│  [2] Manifest 검증                                              │
│       ├── JSON 스키마 검증                                     │
│       ├── 필수 필드 확인                                       │
│       └── 에셋 파일 존재 확인                                  │
│       │                                                         │
│       ▼                                                         │
│  [3] 데이터베이스 등록                                          │
│       ├── installed_packs 테이블에 추가                        │
│       └── 레벨 진행도 초기화                                   │
│       │                                                         │
│       ▼                                                         │
│  [4] 임시 파일 정리                                             │
│       └── downloads/ 폴더에서 .janepack 삭제                   │
│       │                                                         │
│       ▼                                                         │
│  [5] 설치 완료 알림                                             │
│       └── 사용자에게 완료 메시지                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 DownloadManager 구현

```dart
class DownloadManager {
  final Dio _dio;
  final PackFileManager _fileManager;

  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, StreamController<DownloadProgress>> _progressStreams = {};

  DownloadManager({
    required Dio dio,
    required PackFileManager fileManager,
  })  : _dio = dio,
        _fileManager = fileManager;

  /// 다운로드 시작
  Stream<DownloadProgress> download({
    required String url,
    required String packId,
    required int expectedSize,
  }) async* {
    final controller = StreamController<DownloadProgress>.broadcast();
    _progressStreams[packId] = controller;

    final cancelToken = CancelToken();
    _activeDownloads[packId] = cancelToken;

    final tempPath = _fileManager.getDownloadTempPath(packId);

    try {
      yield DownloadProgress(
        packId: packId,
        status: DownloadStatus.starting,
        downloadedBytes: 0,
        totalBytes: expectedSize,
      );

      int downloadedBytes = 0;

      await _dio.download(
        url,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          downloadedBytes = received;
          final progress = DownloadProgress(
            packId: packId,
            status: DownloadStatus.downloading,
            downloadedBytes: received,
            totalBytes: total > 0 ? total : expectedSize,
          );
          controller.add(progress);
        },
        options: Options(
          headers: {
            'Accept-Encoding': 'identity', // 압축 비활성화로 정확한 진행률
          },
        ),
      );

      // 다운로드 완료
      final finalProgress = DownloadProgress(
        packId: packId,
        status: DownloadStatus.completed,
        downloadedBytes: downloadedBytes,
        totalBytes: downloadedBytes,
      );
      controller.add(finalProgress);
      yield finalProgress;

    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        yield DownloadProgress(
          packId: packId,
          status: DownloadStatus.cancelled,
          downloadedBytes: 0,
          totalBytes: expectedSize,
        );
      } else {
        yield DownloadProgress(
          packId: packId,
          status: DownloadStatus.failed,
          downloadedBytes: 0,
          totalBytes: expectedSize,
          error: e.message,
        );
      }
    } finally {
      _activeDownloads.remove(packId);
      _progressStreams.remove(packId);
      await controller.close();
    }
  }

  /// 다운로드 취소
  void cancel(String packId) {
    _activeDownloads[packId]?.cancel();
  }

  /// 임시 파일 정리
  Future<void> cleanup(String packId) async {
    final tempPath = _fileManager.getDownloadTempPath(packId);
    final file = File(tempPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String getDownloadPath(String packId) {
    return _fileManager.getDownloadTempPath(packId);
  }
}

class DownloadProgress {
  final String packId;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final String? error;

  const DownloadProgress({
    required this.packId,
    required this.status,
    required this.downloadedBytes,
    required this.totalBytes,
    this.error,
  });

  double get percentage =>
      totalBytes > 0 ? (downloadedBytes / totalBytes) * 100 : 0;

  String get formattedProgress =>
      '${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} / '
      '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

enum DownloadStatus {
  starting,
  downloading,
  paused,
  completed,
  cancelled,
  failed,
}
```

---

## 9. 게임 실행 플로우

### 9.1 실행 플로우 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                       게임 실행 플로우                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1] 사용자가 레벨 선택                                         │
│       │                                                         │
│       ▼                                                         │
│  [2] GameLauncher.launchGame() 호출                            │
│       │                                                         │
│       ▼                                                         │
│  [3] PackLoader가 팩 로드 (캐시 확인)                           │
│       ├── manifest.json 파싱                                   │
│       ├── 레벨 설정 로드                                       │
│       └── 에셋 번들 준비                                       │
│       │                                                         │
│       ▼                                                         │
│  [4] GameRegistry에서 엔진 생성                                 │
│       └── game_type에 맞는 엔진 인스턴스화                     │
│       │                                                         │
│       ▼                                                         │
│  [5] 캐릭터 데이터 로드                                         │
│       └── 아이의 캐릭터 목록 조회                              │
│       │                                                         │
│       ▼                                                         │
│  [6] 게임 초기화                                                │
│       ├── game.initialize() 호출                               │
│       ├── game.parseGameConfig() 호출                          │
│       └── 게임 컴포넌트 생성                                   │
│       │                                                         │
│       ▼                                                         │
│  [7] GameWidget으로 화면 전환                                   │
│       │                                                         │
│       ▼                                                         │
│  [8] game.startGame() 호출                                     │
│       │                                                         │
│       ▼                                                         │
│  [9] 게임 플레이                                                │
│       │                                                         │
│       ▼                                                         │
│  [10] 게임 종료                                                 │
│       ├── game.endGame() 호출                                  │
│       ├── 결과 계산                                            │
│       └── 결과 저장                                            │
│       │                                                         │
│       ▼                                                         │
│  [11] 결과 화면 표시                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 게임 화면 구성

```dart
/// 게임 플레이 화면
class GameScreen extends StatefulWidget {
  final String packId;
  final String levelId;
  final String childId;

  const GameScreen({
    required this.packId,
    required this.levelId,
    required this.childId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameLauncher _launcher;
  BaseMiniGame? _game;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _launcher = context.read<GameLauncher>();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      final game = await _launcher.launchGame(
        packId: widget.packId,
        levelId: widget.levelId,
        childId: widget.childId,
      );

      setState(() {
        _game = game;
        _isLoading = false;
      });

      // 게임 시작
      game.startGame();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    if (_error != null) {
      return ErrorScreen(message: _error!);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _showPauseDialog(),
      child: GameWidget(
        game: _game!,
        overlayBuilderMap: {
          'pause': (context, game) => PauseOverlay(
            onResume: () {
              _game!.resumeGame();
              _game!.overlays.remove('pause');
            },
            onQuit: () => _quitGame(),
          ),
          'result': (context, game) => ResultOverlay(
            result: _game!.getResult(),
            onNext: () => _goToNextLevel(),
            onRetry: () => _retryLevel(),
            onQuit: () => _quitGame(),
          ),
        },
      ),
    );
  }

  void _showPauseDialog() {
    _game?.pauseGame();
    _game?.overlays.add('pause');
  }

  Future<void> _quitGame() async {
    await _launcher.finishCurrentGame();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _retryLevel() async {
    _game?.overlays.remove('result');
    setState(() {
      _isLoading = true;
    });
    await _loadGame();
  }

  Future<void> _goToNextLevel() async {
    // 다음 레벨로 이동 로직
  }

  @override
  void dispose() {
    _game?.pauseGame();
    super.dispose();
  }
}
```

---

## 10. 오프라인 지원

### 10.1 오프라인 전략

```
┌─────────────────────────────────────────────────────────────────┐
│                       오프라인 전략                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    온라인 상태                           │   │
│  │  • 팩 스토어 탐색 가능                                  │   │
│  │  • 새 팩 다운로드 가능                                  │   │
│  │  • 업데이트 확인 및 적용                                │   │
│  │  • 진행도 서버 동기화                                   │   │
│  │  • 캐릭터 생성 (AI 서버)                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   오프라인 상태                          │   │
│  │  • 설치된 팩 플레이 가능 ✓                              │   │
│  │  • 진행도 로컬 저장 ✓                                   │   │
│  │  • 기존 캐릭터 사용 ✓                                   │   │
│  │  • 팩 스토어 탐색 불가 ✗                                │   │
│  │  • 새 팩 다운로드 불가 ✗                                │   │
│  │  • 캐릭터 생성 불가 ✗                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 오프라인 지원 구현

```dart
/// 네트워크 상태 관리
class ConnectivityManager {
  final Connectivity _connectivity;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;

  ConnectivityManager() : _connectivity = Connectivity() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      _connectionController.add(_isOnline);
    });
  }

  bool get isOnline => _isOnline;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }
}

/// 오프라인 우선 데이터 접근
class PackRepository implements IPackRepository {
  final PackLocalDataSource _localDataSource;
  final PackRemoteDataSource _remoteDataSource;
  final ConnectivityManager _connectivity;

  @override
  Future<List<GamePack>> getAvailablePacks() async {
    if (_connectivity.isOnline) {
      try {
        // 온라인: 서버에서 가져오고 캐시
        final remotePacks = await _remoteDataSource.fetchPacks();
        await _localDataSource.cachePacks(remotePacks);
        return remotePacks;
      } catch (e) {
        // 네트워크 오류시 캐시된 데이터 반환
        return _localDataSource.getCachedPacks();
      }
    } else {
      // 오프라인: 캐시된 데이터만
      return _localDataSource.getCachedPacks();
    }
  }

  @override
  Future<List<GamePack>> getInstalledPacks() async {
    // 항상 로컬에서 조회
    return _localDataSource.getInstalledPacks();
  }

  @override
  Future<void> saveGameResult(GameResult result) async {
    // 로컬에 먼저 저장
    await _localDataSource.saveGameResult(result);

    // 온라인이면 서버 동기화 시도
    if (_connectivity.isOnline) {
      try {
        await _remoteDataSource.syncGameResult(result);
        await _localDataSource.markAsSynced(result.sessionId);
      } catch (e) {
        // 동기화 실패 - 나중에 재시도
        await _localDataSource.markForSync(result.sessionId);
      }
    } else {
      // 오프라인 - 나중에 동기화
      await _localDataSource.markForSync(result.sessionId);
    }
  }
}

/// 오프라인 동기화 큐
class SyncManager {
  final PackLocalDataSource _localDataSource;
  final PackRemoteDataSource _remoteDataSource;
  final ConnectivityManager _connectivity;

  /// 앱 시작시 또는 온라인 복귀시 호출
  Future<void> syncPendingData() async {
    if (!_connectivity.isOnline) return;

    // 동기화 대기 중인 게임 결과
    final pendingResults = await _localDataSource.getPendingSync();

    for (final result in pendingResults) {
      try {
        await _remoteDataSource.syncGameResult(result);
        await _localDataSource.markAsSynced(result.sessionId);
      } catch (e) {
        // 개별 실패는 무시하고 계속 진행
        continue;
      }
    }
  }
}
```

---

## 11. 보안 고려사항

### 11.1 팩 무결성 검증

```dart
/// 팩 파일 검증
class PackValidator {
  /// 다운로드된 팩 파일 검증
  Future<bool> validatePackFile(String filePath, String expectedHash) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    // SHA-256 해시 검증
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = 'sha256:${digest.toString()}';

    return actualHash == expectedHash;
  }

  /// 설치된 팩 구조 검증
  Future<PackValidationResult> validateInstalledPack(String packPath) async {
    final errors = <String>[];

    // 1. manifest.json 존재 확인
    final manifestFile = File('$packPath/manifest.json');
    if (!await manifestFile.exists()) {
      errors.add('manifest.json not found');
      return PackValidationResult(isValid: false, errors: errors);
    }

    // 2. manifest 파싱 및 스키마 검증
    try {
      final manifestJson = jsonDecode(await manifestFile.readAsString());
      final manifest = PackManifest.fromJson(manifestJson);

      // 3. 필수 에셋 파일 존재 확인
      final requiredFiles = [
        manifest.assets.icon,
        manifest.assets.thumbnail,
        manifest.content.levelsIndexPath,
      ];

      for (final filePath in requiredFiles) {
        final file = File('$packPath/$filePath');
        if (!await file.exists()) {
          errors.add('Required file not found: $filePath');
        }
      }

      // 4. 레벨 파일 검증
      final levelsIndex = File('$packPath/${manifest.content.levelsIndexPath}');
      final levelsJson = jsonDecode(await levelsIndex.readAsString());

      for (final level in levelsJson['levels']) {
        final levelFile = File('$packPath/${level['config_path']}');
        if (!await levelFile.exists()) {
          errors.add('Level file not found: ${level['config_path']}');
        }
      }

    } catch (e) {
      errors.add('Failed to parse manifest: $e');
    }

    return PackValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

### 11.2 보안 체크리스트

| 항목 | 설명 | 구현 방법 |
|-----|------|---------|
| **다운로드 검증** | 팩 파일 무결성 확인 | SHA-256 해시 비교 |
| **HTTPS 통신** | 모든 API 통신 암호화 | TLS 1.2+ 강제 |
| **서명된 URL** | 다운로드 URL 탈취 방지 | 시간제한 토큰 포함 |
| **콘텐츠 검증** | 악성 콘텐츠 차단 | 서버측 스캔 + 클라이언트 검증 |
| **샌드박싱** | 팩 실행 격리 | 선언적 설정만 허용, 코드 실행 불가 |
| **경로 검증** | 디렉토리 탐색 공격 방지 | 상대 경로만 허용, ../ 차단 |

### 11.3 콘텐츠 안전성

```dart
/// 콘텐츠 안전성 검사
class ContentSafetyChecker {
  // 허용된 파일 확장자
  static const _allowedImageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
  static const _allowedAudioExtensions = ['.mp3', '.ogg', '.wav', '.m4a'];
  static const _allowedAnimationExtensions = ['.json', '.riv'];

  /// 팩 내 파일 확장자 검증
  Future<bool> validateFileTypes(String packPath) async {
    final directory = Directory(packPath);

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();

        // JSON, 텍스트, 이미지, 오디오, 애니메이션만 허용
        final isAllowed = extension == '.json' ||
            extension == '.txt' ||
            _allowedImageExtensions.contains(extension) ||
            _allowedAudioExtensions.contains(extension) ||
            _allowedAnimationExtensions.contains(extension);

        if (!isAllowed) {
          return false;
        }
      }
    }

    return true;
  }

  /// 경로 탐색 공격 검사
  bool isPathSafe(String relativePath) {
    // ../ 또는 절대 경로 차단
    if (relativePath.contains('..') || path.isAbsolute(relativePath)) {
      return false;
    }
    return true;
  }
}
```

---

## 12. 버전 관리 및 업데이트

### 12.1 버전 체계

```
앱 버전: major.minor.patch (예: 1.5.2)
팩 버전: major.minor.patch (예: 1.2.0)
팩 포맷 버전: 정수 (예: 1, 2, 3...)

호환성 규칙:
- 앱은 min_app_version 이상이어야 팩 설치 가능
- pack_format_version이 앱 지원 범위 내여야 함
```

### 12.2 업데이트 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                       업데이트 플로우                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1] 앱 시작 또는 주기적 체크                                   │
│       │                                                         │
│       ▼                                                         │
│  [2] 서버에 설치된 팩 목록 전송                                 │
│       │                                                         │
│       ▼                                                         │
│  [3] 서버가 업데이트 가능 팩 반환                               │
│       │                                                         │
│       ▼                                                         │
│  [4] 사용자에게 업데이트 알림                                   │
│       │                                                         │
│       ▼                                                         │
│  [5] 사용자가 업데이트 선택                                     │
│       │                                                         │
│       ▼                                                         │
│  [6] 델타 업데이트 또는 전체 다운로드                           │
│       │                                                         │
│       ▼                                                         │
│  [7] 기존 팩 백업 (롤백 대비)                                   │
│       │                                                         │
│       ▼                                                         │
│  [8] 새 버전 설치                                               │
│       │                                                         │
│       ▼                                                         │
│  [9] 진행도 마이그레이션 (필요시)                               │
│       │                                                         │
│       ▼                                                         │
│  [10] 백업 삭제, 완료                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 12.3 마이그레이션 처리

```dart
/// 팩 업데이트 마이그레이션
class PackMigrationManager {
  /// 업데이트 후 진행도 마이그레이션
  Future<void> migrateProgress({
    required String packId,
    required String oldVersion,
    required String newVersion,
  }) async {
    final oldProgress = await _loadProgress(packId);

    // 레벨 ID 매핑 (새 버전에서 레벨 ID가 변경된 경우)
    final newManifest = await _loadManifest(packId);
    final levelMapping = newManifest.migrations
        ?.firstWhere((m) => m.fromVersion == oldVersion)
        ?.levelIdMapping;

    if (levelMapping != null) {
      final migratedProgress = <String, LevelProgress>{};

      for (final entry in oldProgress.entries) {
        final newLevelId = levelMapping[entry.key] ?? entry.key;
        migratedProgress[newLevelId] = entry.value;
      }

      await _saveProgress(packId, migratedProgress);
    }
  }
}
```

---

## 13. 에러 처리

### 13.1 에러 타입 정의

```dart
/// 팩 시스템 예외 기본 클래스
abstract class PackException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const PackException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'PackException: $message (code: $code)';
}

/// 팩을 찾을 수 없음
class PackNotFoundException extends PackException {
  final String packId;

  PackNotFoundException(this.packId)
      : super('Pack not found: $packId', code: 'PACK_NOT_FOUND');
}

/// 레벨을 찾을 수 없음
class LevelNotFoundException extends PackException {
  final String packId;
  final String levelId;

  LevelNotFoundException(this.packId, this.levelId)
      : super('Level not found: $levelId in pack $packId',
              code: 'LEVEL_NOT_FOUND');
}

/// 지원하지 않는 게임 타입
class UnsupportedGameException extends PackException {
  final String gameType;

  UnsupportedGameException(this.gameType)
      : super('Unsupported game type: $gameType',
              code: 'UNSUPPORTED_GAME');
}

/// 앱 버전 호환 불가
class IncompatibleVersionException extends PackException {
  final String requiredVersion;
  final String currentVersion;

  IncompatibleVersionException(this.requiredVersion, this.currentVersion)
      : super('App version $currentVersion is not compatible. '
              'Required: $requiredVersion',
              code: 'INCOMPATIBLE_VERSION');
}

/// 팩 검증 실패
class PackValidationException extends PackException {
  final List<String> errors;

  PackValidationException(String message, {this.errors = const []})
      : super(message, code: 'VALIDATION_FAILED');
}

/// 다운로드 실패
class DownloadException extends PackException {
  DownloadException(String message, {dynamic originalError})
      : super(message, code: 'DOWNLOAD_FAILED', originalError: originalError);
}

/// 설치 실패
class InstallationException extends PackException {
  InstallationException(String message, {dynamic originalError})
      : super(message, code: 'INSTALLATION_FAILED',
              originalError: originalError);
}

/// 저장 공간 부족
class InsufficientStorageException extends PackException {
  final int requiredBytes;
  final int availableBytes;

  InsufficientStorageException(this.requiredBytes, this.availableBytes)
      : super('Insufficient storage. Required: ${requiredBytes ~/ 1024 ~/ 1024}MB, '
              'Available: ${availableBytes ~/ 1024 ~/ 1024}MB',
              code: 'INSUFFICIENT_STORAGE');
}
```

### 13.2 에러 처리 전략

```dart
/// 글로벌 에러 핸들러
class PackErrorHandler {
  /// 에러를 사용자 친화적 메시지로 변환
  String getLocalizedMessage(PackException exception, String locale) {
    final messages = {
      'PACK_NOT_FOUND': {
        'ko': '게임팩을 찾을 수 없습니다.',
        'en': 'Game pack not found.',
      },
      'DOWNLOAD_FAILED': {
        'ko': '다운로드에 실패했습니다. 인터넷 연결을 확인해주세요.',
        'en': 'Download failed. Please check your internet connection.',
      },
      'INSUFFICIENT_STORAGE': {
        'ko': '저장 공간이 부족합니다.',
        'en': 'Insufficient storage space.',
      },
      'INCOMPATIBLE_VERSION': {
        'ko': '앱을 최신 버전으로 업데이트해주세요.',
        'en': 'Please update the app to the latest version.',
      },
    };

    return messages[exception.code]?[locale] ??
           messages[exception.code]?['en'] ??
           exception.message;
  }

  /// 에러 복구 액션 제안
  RecoveryAction? suggestRecovery(PackException exception) {
    switch (exception.code) {
      case 'DOWNLOAD_FAILED':
        return RecoveryAction(
          label: '다시 시도',
          action: RecoveryActionType.retry,
        );
      case 'INSUFFICIENT_STORAGE':
        return RecoveryAction(
          label: '저장 공간 관리',
          action: RecoveryActionType.manageStorage,
        );
      case 'INCOMPATIBLE_VERSION':
        return RecoveryAction(
          label: '앱 업데이트',
          action: RecoveryActionType.updateApp,
        );
      default:
        return null;
    }
  }
}
```

---

## 14. 성능 최적화

### 14.1 메모리 관리

```dart
/// 에셋 메모리 관리
class AssetMemoryManager {
  static const int _maxCachedImages = 50;
  static const int _maxCachedAudio = 20;

  final LruCache<String, ui.Image> _imageCache =
      LruCache(maxSize: _maxCachedImages);
  final LruCache<String, AudioSource> _audioCache =
      LruCache(maxSize: _maxCachedAudio);

  /// 메모리 압박시 캐시 정리
  void onMemoryPressure(MemoryPressureLevel level) {
    switch (level) {
      case MemoryPressureLevel.moderate:
        _imageCache.evict(count: _maxCachedImages ~/ 2);
        break;
      case MemoryPressureLevel.critical:
        _imageCache.clear();
        _audioCache.clear();
        break;
    }
  }

  /// 팩 언로드시 관련 캐시 정리
  void unloadPackAssets(String packId) {
    _imageCache.removeWhere((key, _) => key.startsWith(packId));
    _audioCache.removeWhere((key, _) => key.startsWith(packId));
  }
}
```

### 14.2 로딩 최적화

```dart
/// 프리로딩 매니저
class PreloadManager {
  final PackLoader _packLoader;
  final AssetMemoryManager _memoryManager;

  /// 다음 레벨 프리로드
  Future<void> preloadNextLevel(String packId, String currentLevelId) async {
    final pack = await _packLoader.loadPack(packId);
    final levels = pack.getLevelsSorted();

    final currentIndex = levels.indexWhere((l) => l.levelId == currentLevelId);
    if (currentIndex >= 0 && currentIndex < levels.length - 1) {
      final nextLevel = levels[currentIndex + 1];
      await _preloadLevelAssets(pack, nextLevel);
    }
  }

  Future<void> _preloadLevelAssets(LoadedPack pack, LevelConfig level) async {
    // 백그라운드 로드
    if (level.assets.background != null) {
      pack.assets.loadImage(level.assets.background!);
    }

    // 게임 설정에서 필요한 이미지 추출하여 프리로드
    final settings = level.gameConfig.settings;
    if (settings.containsKey('object_image')) {
      pack.assets.loadImage(settings['object_image'] as String);
    }
  }
}
```

### 14.3 성능 지표

| 지표 | 목표 | 측정 방법 |
|-----|------|---------|
| 팩 로드 시간 | < 1초 | manifest + 레벨 인덱스 로드 |
| 레벨 시작 시간 | < 2초 | 에셋 로드 + 게임 초기화 |
| 메모리 사용량 | < 200MB | 게임 실행 중 피크 메모리 |
| 다운로드 속도 | > 1MB/s | 평균 다운로드 속도 |
| 앱 시작 시간 | < 3초 | 콜드 스타트 기준 |

---

## 부록 A: 내장 팩 목록

앱에 기본 포함되는 팩:

| 팩 ID | 이름 | 게임 타입 | 레벨 수 |
|------|------|---------|--------|
| `builtin_shapes_basic` | 기본 도형 | ShapeColorGame | 10 |
| `builtin_colors_basic` | 기본 색깔 | ShapeColorGame | 10 |
| `builtin_numbers_1_10` | 숫자 1-10 | NumberLetterGame | 10 |
| `builtin_memory_intro` | 메모리 게임 입문 | MemoryCardGame | 5 |

## 부록 B: 게임 타입별 지원 모드

| 게임 타입 | 지원 모드 |
|---------|---------|
| `ShapeColorGame` | match, sort, find |
| `PuzzleGame` | jigsaw, sliding, sequence |
| `MemoryCardGame` | match_pairs, match_triplets, speed |
| `NumberLetterGame` | learning, counting, matching, tracing |
| `TapCoordinationGame` | whack_a_mole, catch, avoid |
| `StoryCodingGame` | record, playback, edit |

---

*문서 버전: 1.0.0*
*최종 수정: 2024-03*
