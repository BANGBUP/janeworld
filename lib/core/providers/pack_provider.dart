import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_pack.dart';
import '../di/service_locator.dart';
import '../di/service_locator_native.dart'
    if (dart.library.html) '../di/service_locator_web.dart';

/// 설치된 팩 목록 Provider
final installedPacksProvider = FutureProvider<List<GamePack>>((ref) async {
  // 웹에서는 데모 팩만 반환
  if (ServiceLocator.isWeb) {
    return _getDemoPacks();
  }

  final packs = await NativeServices.packDatabase.getInstalledPacks();

  // 설치된 팩이 없으면 데모 팩 반환
  if (packs.isEmpty) {
    return _getDemoPacks();
  }

  return packs;
});

/// 설치된 팩 목록 (Notifier 버전 - 변경 가능)
class InstalledPacksNotifier extends AsyncNotifier<List<GamePack>> {
  @override
  Future<List<GamePack>> build() async {
    if (ServiceLocator.isWeb) {
      return _getDemoPacks();
    }

    final packs = await NativeServices.packDatabase.getInstalledPacks();

    if (packs.isEmpty) {
      return _getDemoPacks();
    }

    return packs;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (ServiceLocator.isWeb) {
        return _getDemoPacks();
      }
      final packs = await NativeServices.packDatabase.getInstalledPacks();
      if (packs.isEmpty) {
        return _getDemoPacks();
      }
      return packs;
    });
  }
}

final installedPacksNotifierProvider =
    AsyncNotifierProvider<InstalledPacksNotifier, List<GamePack>>(
  () => InstalledPacksNotifier(),
);

/// 특정 팩 조회 Provider
final packByIdProvider = FutureProvider.family<GamePack?, String>(
  (ref, packId) async {
    // 웹에서는 데모 팩에서만 조회
    if (ServiceLocator.isWeb) {
      final demoPacks = _getDemoPacks();
      return demoPacks.where((p) => p.packId == packId).firstOrNull;
    }

    final pack = await NativeServices.packDatabase.getInstalledPack(packId);

    // DB에 없으면 데모 팩에서 찾기
    if (pack == null) {
      final demoPacks = _getDemoPacks();
      return demoPacks.where((p) => p.packId == packId).firstOrNull;
    }

    return pack;
  },
);

/// 데모 팩 목록
List<GamePack> _getDemoPacks() {
  return [
    GamePack(
      packId: 'demo_numbers',
      version: '1.0.0',
      name: {'ko': '숫자 세기', 'en': 'Counting Numbers'},
      description: {'ko': '1부터 10까지 세어보아요!', 'en': 'Count from 1 to 10!'},
      author: 'JaneWorld',
      gameType: 'NumberLetterGame',
      totalLevels: 5,
      storageSizeMb: 5,
      minAge: 3,
      maxAge: 6,
      skillTags: ['number', 'counting'],
      difficulty: 'beginner',
      estimatedPlayTimeMinutes: 15,
      supportedLocales: ['ko', 'en'],
      minAppVersion: '1.0.0',
      status: PackStatus.installed,
    ),
    GamePack(
      packId: 'demo_memory',
      version: '1.0.0',
      name: {'ko': '기억력 게임', 'en': 'Memory Game'},
      description: {'ko': '같은 카드를 찾아보아요!', 'en': 'Find matching cards!'},
      author: 'JaneWorld',
      gameType: 'MemoryCardGame',
      totalLevels: 5,
      storageSizeMb: 8,
      minAge: 4,
      maxAge: 8,
      skillTags: ['memory', 'matching'],
      difficulty: 'beginner',
      estimatedPlayTimeMinutes: 20,
      supportedLocales: ['ko', 'en'],
      minAppVersion: '1.0.0',
      status: PackStatus.installed,
    ),
    GamePack(
      packId: 'demo_shapes',
      version: '1.0.0',
      name: {'ko': '모양 맞추기', 'en': 'Shape Match'},
      description: {'ko': '같은 모양을 찾아보아요!', 'en': 'Find the same shape!'},
      author: 'JaneWorld',
      gameType: 'ShapeColorGame',
      totalLevels: 5,
      storageSizeMb: 5,
      minAge: 3,
      maxAge: 6,
      skillTags: ['shape', 'color'],
      difficulty: 'beginner',
      estimatedPlayTimeMinutes: 15,
      supportedLocales: ['ko', 'en'],
      minAppVersion: '1.0.0',
      status: PackStatus.installed,
    ),
  ];
}
