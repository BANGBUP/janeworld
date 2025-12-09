import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

import '../../data/datasources/local/pack_database.dart';
import '../../data/datasources/local/pack_file_manager.dart';
import '../../pack_system/pack_manager.dart';
import '../../pack_system/pack_loader.dart';
import '../../pack_system/pack_validator.dart';
import '../../pack_system/download_manager.dart';

/// 네이티브 플랫폼 전용 서비스
class NativeServices {
  static late final Database database;
  static late final PackDatabase packDatabase;
  static late final PackFileManager packFileManager;
  static late final PackManager packManager;
  static late final PackLoader packLoader;
}

Future<void> initPlatform(Dio dio) async {
  // Windows/Linux/macOS에서는 FFI 사용
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 앱 디렉토리 경로
  final appDir = await getApplicationDocumentsDirectory();
  final packsDir = path.join(appDir.path, 'packs');
  final downloadsDir = path.join(appDir.path, 'downloads');

  // SQLite 데이터베이스 초기화
  final dbPath = path.join(appDir.path, 'janeworld.db');
  NativeServices.database = await openDatabase(
    dbPath,
    version: 1,
    onCreate: _createDatabase,
  );

  // PackDatabase 초기화
  NativeServices.packDatabase = PackDatabase(NativeServices.database);

  // PackFileManager 초기화
  NativeServices.packFileManager = PackFileManager(
    packsDirectory: packsDir,
    downloadsDirectory: downloadsDir,
  );
  await NativeServices.packFileManager.init();

  // PackValidator
  final packValidator = PackValidator();

  // DownloadManager
  final downloadManager = DownloadManager(
    dio: dio,
    fileManager: NativeServices.packFileManager,
  );

  // PackLoader
  NativeServices.packLoader = PackLoader(fileManager: NativeServices.packFileManager);

  // PackManager
  NativeServices.packManager = PackManager(
    packDatabase: NativeServices.packDatabase,
    fileManager: NativeServices.packFileManager,
    downloadManager: downloadManager,
    validator: packValidator,
    dio: dio,
  );
}

Future<void> _createDatabase(Database db, int version) async {
  // 설치된 게임팩
  await db.execute('''
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
      skill_tags TEXT,
      installed_at TEXT NOT NULL,
      last_played_at TEXT,
      manifest_json TEXT NOT NULL
    )
  ''');

  // 레벨 진행도
  await db.execute('''
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
      unlocked INTEGER DEFAULT 0,
      FOREIGN KEY (pack_id) REFERENCES installed_packs(pack_id) ON DELETE CASCADE,
      UNIQUE(pack_id, level_id, child_id)
    )
  ''');

  // 게임 세션 기록
  await db.execute('''
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
      completed INTEGER NOT NULL,
      started_at TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      FOREIGN KEY (pack_id) REFERENCES installed_packs(pack_id) ON DELETE CASCADE
    )
  ''');

  // 다운로드 큐
  await db.execute('''
    CREATE TABLE download_queue (
      pack_id TEXT PRIMARY KEY,
      download_url TEXT NOT NULL,
      expected_size_bytes INTEGER NOT NULL,
      downloaded_bytes INTEGER DEFAULT 0,
      status TEXT NOT NULL,
      error_message TEXT,
      created_at TEXT NOT NULL,
      started_at TEXT,
      completed_at TEXT
    )
  ''');

  // 인덱스 생성
  await db.execute(
      'CREATE INDEX idx_level_progress_child ON level_progress(child_id)');
  await db.execute(
      'CREATE INDEX idx_level_progress_pack ON level_progress(pack_id)');
  await db.execute(
      'CREATE INDEX idx_game_sessions_child ON game_sessions(child_id)');
}
