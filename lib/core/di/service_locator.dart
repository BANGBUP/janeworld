import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../game_engine/core/game_registry.dart';

// 조건부 import
import 'service_locator_native.dart'
    if (dart.library.html) 'service_locator_web.dart' as platform;

export 'service_locator_native.dart'
    if (dart.library.html) 'service_locator_web.dart';

/// 서비스 로케이터 - 앱 전역 서비스 초기화
class ServiceLocator {
  static late final Dio dio;
  static late final GameRegistry gameRegistry;

  static bool get isWeb => kIsWeb;

  static Future<void> init() async {
    // Dio HTTP 클라이언트 (웹/네이티브 공통)
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));

    // 플랫폼별 초기화
    await platform.initPlatform(dio);

    // GameRegistry 초기화 (웹/네이티브 공통)
    gameRegistry = GameRegistry();
    gameRegistry.initialize();
  }
}
