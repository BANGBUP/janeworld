import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';

/// 현재 활성 프로필 Provider
final activeProfileProvider = StateNotifierProvider<ActiveProfileNotifier, UserProfile?>(
  (ref) => ActiveProfileNotifier(),
);

class ActiveProfileNotifier extends StateNotifier<UserProfile?> {
  ActiveProfileNotifier() : super(null) {
    _loadDefaultProfile();
  }

  void _loadDefaultProfile() {
    // 기본 프로필 로드 (실제로는 DB에서)
    state = UserProfile(
      id: 'default',
      name: '꼬마친구',
      age: 5,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
  }

  void setProfile(UserProfile profile) {
    state = profile;
  }

  void updateName(String name) {
    if (state != null) {
      state = state!.copyWith(name: name);
    }
  }

  void setCharacter(String characterId) {
    if (state != null) {
      state = state!.copyWith(characterId: characterId);
    }
  }
}

/// 모든 프로필 목록 Provider
final allProfilesProvider = StateNotifierProvider<AllProfilesNotifier, List<UserProfile>>(
  (ref) => AllProfilesNotifier(),
);

class AllProfilesNotifier extends StateNotifier<List<UserProfile>> {
  AllProfilesNotifier() : super([]) {
    _loadProfiles();
  }

  void _loadProfiles() {
    // 기본 프로필들 (실제로는 DB에서)
    state = [
      UserProfile(
        id: 'default',
        name: '꼬마친구',
        age: 5,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void addProfile(UserProfile profile) {
    state = [...state, profile];
  }

  void removeProfile(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

/// 현재 사용자의 캐릭터 Provider
final userCharacterProvider = StateNotifierProvider<UserCharacterNotifier, UserCharacter?>(
  (ref) => UserCharacterNotifier(),
);

class UserCharacterNotifier extends StateNotifier<UserCharacter?> {
  UserCharacterNotifier() : super(null) {
    _loadDefaultCharacter();
  }

  /// 기본 캐릭터 6종
  static final List<UserCharacter> _defaultCharacters = [
    UserCharacter(
      id: 'default_star',
      name: '별이',
      imagePath: 'assets/characters/star_character.png',
      greetings: [
        '안녕 {name}! 오늘도 반짝반짝!',
        '{name}! 같이 놀자!',
        '와! {name}이다! 기다렸어!',
        '{name}, 오늘 기분이 어때?',
      ],
      createdAt: DateTime.now(),
    ),
    UserCharacter(
      id: 'default_bunny',
      name: '토토',
      imagePath: 'assets/characters/bunny_character.png',
      greetings: [
        '깡충깡충! {name} 왔구나!',
        '{name}! 당근 먹을래?',
        '토토랑 {name} 같이 놀자!',
        '{name}! 오늘도 신나게!',
      ],
      createdAt: DateTime.now(),
    ),
    UserCharacter(
      id: 'default_whale',
      name: '파랑이',
      imagePath: 'assets/characters/whale_character.png',
      greetings: [
        '첨벙첨벙! {name} 안녕!',
        '{name}! 바다로 가자!',
        '파랑이가 {name}를 기다렸어!',
        '{name}~ 같이 수영할까?',
      ],
      createdAt: DateTime.now(),
    ),
    UserCharacter(
      id: 'default_flower',
      name: '핑키',
      imagePath: 'assets/characters/flower_character.png',
      greetings: [
        '살랑살랑~ {name}!',
        '{name}! 꽃놀이 갈까?',
        '핑키랑 {name}, 오늘도 행복하게!',
        '{name}! 예쁜 꽃처럼 활짝!',
      ],
      createdAt: DateTime.now(),
    ),
    UserCharacter(
      id: 'default_leaf',
      name: '초록이',
      imagePath: 'assets/characters/leaf_character.png',
      greetings: [
        '솨솨솨~ {name} 왔다!',
        '{name}! 숲에서 놀자!',
        '초록이가 {name}를 반겨요!',
        '{name}! 자연이 좋아!',
      ],
      createdAt: DateTime.now(),
    ),
    UserCharacter(
      id: 'default_rainbow',
      name: '해피',
      imagePath: 'assets/characters/rainbow_character.png',
      greetings: [
        '무지개처럼! {name}!',
        '{name}! 행복한 하루!',
        '해피랑 {name}, 오늘도 웃자!',
        '{name}! 알록달록 신나는 날!',
      ],
      createdAt: DateTime.now(),
    ),
  ];

  void _loadDefaultCharacter() {
    // 랜덤으로 기본 캐릭터 선택
    final random = Random();
    state = _defaultCharacters[random.nextInt(_defaultCharacters.length)];
  }

  void setCharacter(UserCharacter character) {
    state = character;
  }

  void clearCharacter() {
    state = null;
  }
}

/// 오늘의 추천 게임 Provider
final todayRecommendationProvider = Provider<TodayRecommendation>((ref) {
  // 실제로는 사용자 활동 기반 추천
  final recommendations = [
    TodayRecommendation(
      packId: 'demo_numbers',
      title: '신나는 숫자 세기!',
      subtitle: '숫자 별을 모아볼까?',
      levelId: 'level_001',
    ),
    TodayRecommendation(
      packId: 'demo_memory',
      title: '기억력 대장 되기!',
      subtitle: '카드를 뒤집어 짝을 찾아봐!',
      levelId: 'level_001',
    ),
    TodayRecommendation(
      packId: 'demo_shapes',
      title: '알록달록 모양 찾기!',
      subtitle: '같은 모양을 찾아볼까?',
      levelId: 'level_001',
    ),
  ];

  final index = DateTime.now().day % recommendations.length;
  return recommendations[index];
});

class TodayRecommendation {
  final String packId;
  final String title;
  final String subtitle;
  final String levelId;

  TodayRecommendation({
    required this.packId,
    required this.title,
    required this.subtitle,
    required this.levelId,
  });
}
