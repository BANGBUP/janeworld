import 'base_mini_game.dart';
import '../engines/number_letter/number_letter_engine.dart';
import '../engines/memory_card/memory_card_engine.dart';
import '../engines/shape_color/shape_color_engine.dart';

/// 게임 엔진 팩토리 타입
typedef MiniGameFactory = BaseMiniGame Function();

/// 게임 엔진 등록소
class GameRegistry {
  static final GameRegistry _instance = GameRegistry._internal();
  factory GameRegistry() => _instance;
  GameRegistry._internal();

  final Map<String, MiniGameFactory> _factories = {};

  /// 초기화 - 앱 시작 시 호출
  void initialize() {
    register('NumberLetterGame', () => NumberLetterEngine());
    register('MemoryCardGame', () => MemoryCardEngine());
    register('ShapeColorGame', () => ShapeColorEngine());
    // 추가 게임 엔진 등록
    // register('PuzzleGame', () => PuzzleEngine());
    // register('TapCoordinationGame', () => TapCoordinationEngine());
  }

  /// 게임 엔진 등록
  void register(String gameType, MiniGameFactory factory) {
    _factories[gameType] = factory;
  }

  /// 게임 엔진 등록 해제
  void unregister(String gameType) {
    _factories.remove(gameType);
  }

  /// 게임 엔진 생성
  BaseMiniGame createGame(String gameType) {
    final factory = _factories[gameType];
    if (factory == null) {
      throw UnsupportedGameException(
        'Game type not registered: $gameType. '
        'Available types: ${supportedGameTypes.join(", ")}',
      );
    }
    return factory();
  }

  /// 지원되는 게임 타입 목록
  List<String> get supportedGameTypes => _factories.keys.toList();

  /// 특정 게임 타입 지원 여부
  bool isSupported(String gameType) => _factories.containsKey(gameType);

  /// 등록된 게임 수
  int get registeredCount => _factories.length;
}

/// 지원하지 않는 게임 예외
class UnsupportedGameException implements Exception {
  final String message;

  UnsupportedGameException(this.message);

  @override
  String toString() => 'UnsupportedGameException: $message';
}
