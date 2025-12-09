import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../../pack_system/pack_loader.dart';

/// 세기 가능한 오브젝트 (사과, 별 등)
class CountableObject extends PositionComponent {
  final int number;
  final String objectType;
  final String? imagePath;
  final bool showNumber;
  final PackAssetBundle? assets;

  late RectangleComponent _background;
  late TextComponent _numberText;
  late _ObjectShape _objectShape;

  bool _isHighlighted = false;

  CountableObject({
    required this.number,
    required this.objectType,
    this.imagePath,
    required Vector2 position,
    required Vector2 size,
    this.showNumber = false,
    this.assets,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 배경 원
    _background = RectangleComponent(
      size: size,
      paint: Paint()..color = _getObjectColor().withOpacity(0.2),
    );
    _background.position = Vector2.zero();
    add(_background);

    // 오브젝트 도형 (이모지 대신 Canvas 사용)
    _objectShape = _ObjectShape(
      objectType: objectType,
      color: _getObjectColor(),
      size: size * 0.7,
    );
    _objectShape.position = size * 0.15;
    add(_objectShape);

    // 숫자 표시 (힌트)
    if (showNumber) {
      _numberText = TextComponent(
        text: number.toString(),
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y + 15),
      );
      add(_numberText);
    }
  }

  Color _getObjectColor() {
    switch (objectType.toLowerCase()) {
      case 'apple':
        return Colors.red;
      case 'star':
        return Colors.amber;
      case 'ball':
        return Colors.blue;
      case 'flower':
        return Colors.pink;
      case 'heart':
        return Colors.red;
      case 'fish':
        return Colors.cyan;
      case 'bird':
        return Colors.orange;
      case 'car':
        return Colors.purple;
      case 'tree':
        return Colors.green;
      case 'sun':
        return Colors.yellow;
      default:
        return Colors.amber;
    }
  }

  /// 하이라이트 효과
  void highlight() {
    if (_isHighlighted) return;
    _isHighlighted = true;

    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(
          duration: 0.3,
          reverseDuration: 0.3,
        ),
      ),
    );

    _background.paint = Paint()..color = _getObjectColor().withOpacity(0.5);

    Future.delayed(const Duration(milliseconds: 600), () {
      _isHighlighted = false;
      _background.paint = Paint()..color = _getObjectColor().withOpacity(0.2);
    });
  }

  /// 축하 애니메이션
  void celebrate() {
    add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(1.3),
          EffectController(duration: 0.15),
        ),
        ScaleEffect.by(
          Vector2.all(1 / 1.3),
          EffectController(duration: 0.15),
        ),
        MoveByEffect(
          Vector2(0, -20),
          EffectController(duration: 0.2),
        ),
        MoveByEffect(
          Vector2(0, 20),
          EffectController(duration: 0.2),
        ),
      ]),
    );
  }

  /// 흔들기 애니메이션
  void shake() {
    add(
      SequenceEffect([
        MoveByEffect(
          Vector2(-5, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(10, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(-10, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(5, 0),
          EffectController(duration: 0.05),
        ),
      ]),
    );
  }
}

/// Canvas로 그리는 오브젝트 도형
class _ObjectShape extends PositionComponent {
  final String objectType;
  final Color color;

  _ObjectShape({
    required this.objectType,
    required this.color,
    required Vector2 size,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (objectType.toLowerCase()) {
      case 'apple':
        _drawApple(canvas, paint);
        break;
      case 'star':
        _drawStar(canvas, paint);
        break;
      case 'ball':
        _drawBall(canvas, paint);
        break;
      case 'flower':
        _drawFlower(canvas, paint);
        break;
      case 'heart':
        _drawHeart(canvas, paint);
        break;
      default:
        _drawStar(canvas, paint);
    }
  }

  void _drawApple(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    // 사과 본체
    canvas.drawCircle(Offset(centerX, centerY + 5), radius, paint);

    // 잎
    final leafPaint = Paint()..color = Colors.green;
    final leafPath = Path()
      ..moveTo(centerX, centerY - radius + 5)
      ..quadraticBezierTo(centerX + 15, centerY - radius - 10, centerX + 5, centerY - radius - 5);
    canvas.drawPath(leafPath, leafPaint..style = PaintingStyle.stroke..strokeWidth = 3);

    // 줄기
    canvas.drawLine(
      Offset(centerX, centerY - radius + 5),
      Offset(centerX, centerY - radius - 5),
      Paint()..color = Colors.brown..strokeWidth = 2,
    );
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x * 0.45;
    final innerRadius = size.x * 0.2;

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

  void _drawBall(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // 하이라이트
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(centerX - radius * 0.3, centerY - radius * 0.3), radius * 0.2, highlightPaint);
  }

  void _drawFlower(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final petalRadius = size.x * 0.18;

    // 꽃잎 5개
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final petalX = centerX + petalRadius * 1.5 * cos(angle);
      final petalY = centerY + petalRadius * 1.5 * sin(angle);
      canvas.drawCircle(Offset(petalX, petalY), petalRadius, paint);
    }

    // 중앙
    final centerPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(centerX, centerY), petalRadius * 0.8, centerPaint);
  }

  void _drawHeart(Canvas canvas, Paint paint) {
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final width = size.x * 0.8;
    final height = size.y * 0.8;

    path.moveTo(centerX, centerY + height * 0.35);
    path.cubicTo(
      centerX - width * 0.5, centerY,
      centerX - width * 0.5, centerY - height * 0.35,
      centerX, centerY - height * 0.1,
    );
    path.cubicTo(
      centerX + width * 0.5, centerY - height * 0.35,
      centerX + width * 0.5, centerY,
      centerX, centerY + height * 0.35,
    );
    path.close();
    canvas.drawPath(path, paint);
  }
}
