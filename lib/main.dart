import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 웹이 아닐 때만 시스템 UI 설정
  if (!kIsWeb) {
    // 화면 방향 고정 (가로)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 전체화면 모드
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Hive 초기화
  await Hive.initFlutter();

  // 서비스 로케이터 초기화
  await ServiceLocator.init();

  runApp(
    const ProviderScope(
      child: JaneWorldApp(),
    ),
  );
}
