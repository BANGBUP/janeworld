import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/pack_store/screens/pack_store_screen.dart';
import '../../features/pack_store/screens/pack_detail_screen.dart';
import '../../features/my_packs/screens/my_packs_screen.dart';
import '../../features/game/screens/level_select_screen.dart';
import '../../features/game/screens/game_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/store',
        name: 'packStore',
        builder: (context, state) => const PackStoreScreen(),
      ),
      GoRoute(
        path: '/store/:packId',
        name: 'packDetail',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          return PackDetailScreen(packId: packId);
        },
      ),
      GoRoute(
        path: '/my-packs',
        name: 'myPacks',
        builder: (context, state) => const MyPacksScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/play/:packId',
        name: 'levelSelect',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          return LevelSelectScreen(packId: packId);
        },
      ),
      GoRoute(
        path: '/play/:packId/:levelId',
        name: 'game',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          final levelId = state.pathParameters['levelId']!;
          return GameScreen(packId: packId, levelId: levelId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
