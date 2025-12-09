import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../memory_card_engine.dart';

/// 메모리 카드 컴포넌트
class MemoryCard extends PositionComponent with TapCallbacks {
  final int cardIndex;
  final String pairId;
  final CardData cardData;
  final Function(MemoryCard) onFlip;

  late RectangleComponent _cardBack;
  late RectangleComponent _cardFront;
  late PositionComponent _contentDisplay;

  bool _isFlipped = false;
  bool _isMatched = false;
  bool _isAnimating = false;

  bool get isFlipped => _isFlipped;
  bool get isMatched => _isMatched;

  static const _backColor = Color(0xFF6C63FF);
  static const _frontColor = Color(0xFFFFFFFF);
  static const _matchedColor = Color(0xFF00B894);

  MemoryCard({
    required this.cardIndex,
    required this.pairId,
    required this.cardData,
    required Vector2 position,
    required Vector2 size,
    required this.onFlip,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 카드 뒷면
    _cardBack = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = _backColor
        ..style = PaintingStyle.fill,
    );
    add(_cardBack);

    // 카드 뒷면 물음표
    final questionMark = TextComponent(
      text: '?',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.x * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    _cardBack.add(questionMark);

    // 카드 앞면 (처음에는 숨김)
    _cardFront = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = _frontColor
        ..style = PaintingStyle.fill,
    );
    _cardFront.scale = Vector2(0, 1); // X축으로 숨김
    add(_cardFront);

    // 카드 테두리
    final border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(border);

    // 내용 표시 (도형 또는 텍스트)
    if (cardData.type == 'shape') {
      _contentDisplay = _CardShape(
        shapeType: cardData.content,
        size: size * 0.6,
      );
      _contentDisplay.position = size * 0.2;
    } else {
      _contentDisplay = TextComponent(
        text: cardData.content,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: size.x * 0.25,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2,
      );
    }
    _contentDisplay.scale = Vector2(0, 1); // 처음에는 숨김
    add(_contentDisplay);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isAnimating || _isFlipped || _isMatched) return;

    // 탭 피드백
    add(
      ScaleEffect.by(
        Vector2.all(0.95),
        EffectController(duration: 0.05),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_isAnimating || _isFlipped || _isMatched) return;

    add(
      ScaleEffect.by(
        Vector2.all(1 / 0.95),
        EffectController(duration: 0.05),
      ),
    );

    onFlip(this);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (_isAnimating) return;

    scale = Vector2.all(1);
  }

  /// 카드 뒤집기
  void flip() {
    if (_isAnimating || _isFlipped) return;
    _isAnimating = true;
    _isFlipped = true;

    // 뒷면 숨기기 애니메이션
    _cardBack.add(
      ScaleEffect.to(
        Vector2(0, 1),
        EffectController(duration: 0.15),
        onComplete: () {
          // 앞면 보이기 애니메이션
          _cardFront.scale = Vector2(0, 1);
          _cardFront.add(
            ScaleEffect.to(
              Vector2(1, 1),
              EffectController(duration: 0.15),
            ),
          );
          _contentDisplay.add(
            ScaleEffect.to(
              Vector2(1, 1),
              EffectController(duration: 0.15),
              onComplete: () {
                _isAnimating = false;
              },
            ),
          );
        },
      ),
    );
  }

  /// 카드 다시 뒤집기
  void flipBack() {
    if (_isAnimating || !_isFlipped || _isMatched) return;
    _isAnimating = true;
    _isFlipped = false;

    // 앞면 숨기기 애니메이션
    _cardFront.add(
      ScaleEffect.to(
        Vector2(0, 1),
        EffectController(duration: 0.15),
      ),
    );
    _contentDisplay.add(
      ScaleEffect.to(
        Vector2(0, 1),
        EffectController(duration: 0.15),
        onComplete: () {
          // 뒷면 보이기 애니메이션
          _cardBack.scale = Vector2(0, 1);
          _cardBack.add(
            ScaleEffect.to(
              Vector2(1, 1),
              EffectController(duration: 0.15),
              onComplete: () {
                _isAnimating = false;
              },
            ),
          );
        },
      ),
    );
  }

  /// 매칭 성공
  void setMatched() {
    _isMatched = true;
    _cardFront.paint = Paint()..color = _matchedColor.withOpacity(0.3);

    // 축하 애니메이션
    add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(1.1),
          EffectController(duration: 0.1),
        ),
        ScaleEffect.by(
          Vector2.all(1 / 1.1),
          EffectController(duration: 0.1),
        ),
      ]),
    );
  }

  /// 리셋
  void reset() {
    _isFlipped = false;
    _isMatched = false;
    _isAnimating = false;

    _cardBack.scale = Vector2(1, 1);
    _cardFront.scale = Vector2(0, 1);
    _contentDisplay.scale = Vector2(0, 1);
    _cardFront.paint = Paint()..color = _frontColor;
    scale = Vector2.all(1);
  }
}

/// 카드 도형 컴포넌트
class _CardShape extends PositionComponent {
  final String shapeType;

  _CardShape({
    required this.shapeType,
    required Vector2 size,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    final color = _getShapeColor();
    final paint = Paint()..color = color;

    switch (shapeType.toLowerCase()) {
      case 'apple':
        _drawApple(canvas, paint);
        break;
      case 'orange':
        _drawOrange(canvas, paint);
        break;
      case 'star':
        _drawStar(canvas, paint);
        break;
      case 'heart':
        _drawHeart(canvas, paint);
        break;
      case 'flower':
        _drawFlower(canvas, paint);
        break;
      case 'ball':
        _drawBall(canvas, paint);
        break;
      case 'diamond':
        _drawDiamond(canvas, paint);
        break;
      case 'moon':
        _drawMoon(canvas, paint);
        break;
      default:
        _drawStar(canvas, paint);
    }
  }

  Color _getShapeColor() {
    switch (shapeType.toLowerCase()) {
      case 'apple': return Colors.red;
      case 'orange': return Colors.orange;
      case 'star': return Colors.amber;
      case 'heart': return Colors.pink;
      case 'flower': return Colors.purple;
      case 'ball': return Colors.blue;
      case 'diamond': return Colors.cyan;
      case 'moon': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  void _drawApple(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    canvas.drawCircle(Offset(centerX, centerY + 5), radius, paint);

    // 줄기
    canvas.drawLine(
      Offset(centerX, centerY - radius + 5),
      Offset(centerX, centerY - radius - 5),
      Paint()..color = Colors.brown..strokeWidth = 3,
    );
  }

  void _drawOrange(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // 잎
    final leafPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(centerX + 5, centerY - radius + 5), 6, leafPaint);
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

  void _drawHeart(Canvas canvas, Paint paint) {
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final w = size.x * 0.8;
    final h = size.y * 0.8;

    path.moveTo(centerX, centerY + h * 0.35);
    path.cubicTo(
      centerX - w * 0.5, centerY,
      centerX - w * 0.5, centerY - h * 0.35,
      centerX, centerY - h * 0.1,
    );
    path.cubicTo(
      centerX + w * 0.5, centerY - h * 0.35,
      centerX + w * 0.5, centerY,
      centerX, centerY + h * 0.35,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final petalRadius = size.x * 0.15;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final petalX = centerX + petalRadius * 1.5 * cos(angle);
      final petalY = centerY + petalRadius * 1.5 * sin(angle);
      canvas.drawCircle(Offset(petalX, petalY), petalRadius, paint);
    }

    final centerPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(centerX, centerY), petalRadius * 0.7, centerPaint);
  }

  void _drawBall(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(centerX - radius * 0.3, centerY - radius * 0.3), radius * 0.2, highlightPaint);
  }

  void _drawDiamond(Canvas canvas, Paint paint) {
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final w = size.x * 0.4;
    final h = size.y * 0.45;

    path.moveTo(centerX, centerY - h);
    path.lineTo(centerX + w, centerY);
    path.lineTo(centerX, centerY + h);
    path.lineTo(centerX - w, centerY);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMoon(Canvas canvas, Paint paint) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // 어두운 부분
    final shadowPaint = Paint()..color = const Color(0xFFFFF5E6);
    canvas.drawCircle(Offset(centerX + radius * 0.4, centerY - radius * 0.2), radius * 0.7, shadowPaint);
  }
}
