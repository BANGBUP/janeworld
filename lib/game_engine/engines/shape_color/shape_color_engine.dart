import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/base_mini_game.dart';

/// 모양/색깔 맞추기 게임 엔진
class ShapeColorEngine extends BaseMiniGame {
  @override
  String get gameId => 'shape_color_engine';

  @override
  String get gameType => 'ShapeColorGame';

  @override
  List<String> get supportedModes => [
        'match', // 같은 것 찾기
        'sort', // 분류하기
        'find', // 특정 것 찾기
      ];

  // 게임 설정
  late String _mode;
  late String _targetShape;
  late Color _targetColor;
  late List<ShapeChoice> _choices;
  late List<String> _matchCriteria;
  late bool _dragAndDrop;
  late int? _timeLimitSeconds;

  // 게임 상태
  ShapeChoice? _selectedChoice;
  bool _answered = false;

  // UI 컴포넌트
  late TextComponent _instructionText;
  late _TargetDisplay _targetDisplay;
  final List<_ChoiceItem> _choiceItems = [];

  @override
  void parseGameConfig(Map<String, dynamic> settings) {
    _mode = settings['mode'] as String? ?? 'match';

    final target = settings['target'] as Map<String, dynamic>? ?? {};
    _targetShape = target['shape'] as String? ?? 'circle';
    _targetColor = _parseColor(target['color'] as String? ?? '#FF0000');

    _matchCriteria =
        List<String>.from(settings['match_criteria'] ?? ['shape', 'color']);
    _dragAndDrop = settings['drag_and_drop'] as bool? ?? false;
    _timeLimitSeconds = settings['time_limit_seconds'] as int?;

    // 선택지 파싱
    final choicesData = settings['choices'] as List<dynamic>? ?? [];
    _choices = choicesData.map((c) {
      final map = c as Map<String, dynamic>;
      return ShapeChoice(
        shape: map['shape'] as String? ?? 'circle',
        color: _parseColor(map['color'] as String? ?? '#0000FF'),
        imagePath: map['image'] as String?,
      );
    }).toList();

    // 기본 선택지
    if (_choices.isEmpty) {
      _choices = _generateDefaultChoices();
    }
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.blue;
  }

  List<ShapeChoice> _generateDefaultChoices() {
    return [
      ShapeChoice(shape: _targetShape, color: _targetColor), // 정답
      ShapeChoice(shape: 'square', color: _targetColor),
      ShapeChoice(shape: _targetShape, color: Colors.blue),
      ShapeChoice(shape: 'triangle', color: Colors.green),
    ]..shuffle(Random());
  }

  @override
  Future<void> onInitialize() async {
    _choiceItems.clear();
    _answered = false;
    _selectedChoice = null;

    // 인스트럭션
    _instructionText = TextComponent(
      text: '같은 모양과 색깔을 찾아보세요!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 50),
    );
    add(_instructionText);

    // 타겟 표시
    _targetDisplay = _TargetDisplay(
      shape: _targetShape,
      color: _targetColor,
      position: Vector2(size.x / 2, size.y * 0.3),
      displaySize: Vector2(120, 120),
    );
    add(_targetDisplay);

    // 선택지 표시
    final choiceSize = Vector2(100, 100);
    final spacing = 130.0;
    final startX = (size.x - (_choices.length * spacing)) / 2 + spacing / 2;
    final choiceY = size.y * 0.65;

    for (int i = 0; i < _choices.length; i++) {
      final choice = _choices[i];
      final item = _ChoiceItem(
        choice: choice,
        position: Vector2(startX + i * spacing, choiceY),
        displaySize: choiceSize,
        onTap: () => _onChoiceSelected(choice),
      );
      _choiceItems.add(item);
      add(item);
    }
  }

  void _onChoiceSelected(ShapeChoice choice) {
    if (_answered) return;

    _answered = true;
    _selectedChoice = choice;

    final isCorrect = _checkMatch(choice);

    // 선택 표시
    for (final item in _choiceItems) {
      if (item.choice == choice) {
        item.setSelected(isCorrect);
      }
    }

    if (isCorrect) {
      addScore(100);
      _instructionText.text = '정답이에요! 잘했어요!';

      Future.delayed(const Duration(seconds: 2), () {
        endGame(completed: true);
      });
    } else {
      addMistake();
      _instructionText.text = '다시 한번 찾아볼까요?';

      Future.delayed(const Duration(seconds: 1), () {
        _resetForRetry();
      });
    }
  }

  bool _checkMatch(ShapeChoice choice) {
    bool shapeMatch = true;
    bool colorMatch = true;

    if (_matchCriteria.contains('shape')) {
      shapeMatch = choice.shape == _targetShape;
    }
    if (_matchCriteria.contains('color')) {
      colorMatch = choice.color.value == _targetColor.value;
    }

    return shapeMatch && colorMatch;
  }

  void _resetForRetry() {
    _answered = false;

    for (final item in _choiceItems) {
      item.reset();
    }

    _instructionText.text = '같은 모양과 색깔을 찾아보세요!';
  }

  @override
  void onGameStart() {}

  @override
  void onGameEnd(bool completed) {}

  @override
  Color backgroundColor() => const Color(0xFFE8F5E9);
}

/// 선택지 데이터
class ShapeChoice {
  final String shape;
  final Color color;
  final String? imagePath;

  ShapeChoice({
    required this.shape,
    required this.color,
    this.imagePath,
  });
}

/// 타겟 표시 컴포넌트
class _TargetDisplay extends PositionComponent {
  final String shape;
  final Color color;
  final Vector2 displaySize;

  _TargetDisplay({
    required this.shape,
    required this.color,
    required Vector2 position,
    required this.displaySize,
  }) : super(position: position, size: displaySize, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(_ShapeComponent(
      shape: shape,
      color: color,
      size: size,
    ));

    // 라벨
    add(TextComponent(
      text: '이것을 찾아요!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y + 20),
    ));
  }
}

/// 선택지 아이템 컴포넌트
class _ChoiceItem extends PositionComponent with TapCallbacks {
  final ShapeChoice choice;
  final VoidCallback onTap;
  final Vector2 displaySize;

  late _ShapeComponent _shapeComponent;
  bool _isSelected = false;

  _ChoiceItem({
    required this.choice,
    required Vector2 position,
    required this.displaySize,
    required this.onTap,
  }) : super(position: position, size: displaySize, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _shapeComponent = _ShapeComponent(
      shape: choice.shape,
      color: choice.color,
      size: size,
    );
    add(_shapeComponent);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_isSelected) {
      onTap();
    }
  }

  void setSelected(bool isCorrect) {
    _isSelected = true;
    // 테두리 추가로 선택 표시
    add(RectangleComponent(
      size: size + Vector2.all(10),
      position: Vector2(-5, -5),
      paint: Paint()
        ..color = isCorrect ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    ));
  }

  void reset() {
    _isSelected = false;
    removeWhere((c) => c is RectangleComponent);
  }
}

/// 도형 컴포넌트
class _ShapeComponent extends PositionComponent {
  final String shape;
  final Color color;

  _ShapeComponent({
    required this.shape,
    required this.color,
    required Vector2 size,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    final rect = size.toRect();

    switch (shape.toLowerCase()) {
      case 'circle':
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2,
          paint,
        );
        break;
      case 'square':
        canvas.drawRect(rect, paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(size.x / 2, 0)
          ..lineTo(size.x, size.y)
          ..lineTo(0, size.y)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'star':
        _drawStar(canvas, paint);
        break;
      default:
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2,
          paint,
        );
    }
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;
    final innerRadius = size.x / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      final outerX = centerX + outerRadius * cos(outerAngle);
      final outerY = centerY + outerRadius * sin(outerAngle);
      final innerX = centerX + innerRadius * cos(innerAngle);
      final innerY = centerY + innerRadius * sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
