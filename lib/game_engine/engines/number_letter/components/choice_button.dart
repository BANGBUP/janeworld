import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// 선택지 버튼
class ChoiceButton extends PositionComponent with TapCallbacks {
  final int value;
  final VoidCallback onTap;

  late RectangleComponent _background;
  late TextComponent _valueText;

  bool _isSelected = false;
  bool _isDisabled = false;

  Color _currentColor = const Color(0xFF6C63FF);
  Color _textColor = Colors.white;

  ChoiceButton({
    required this.value,
    required Vector2 position,
    required Vector2 size,
    required this.onTap,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 배경 (둥근 사각형처럼 보이게)
    _background = RectangleComponent(
      size: size,
      paint: Paint()..color = _currentColor,
    );
    add(_background);

    // 숫자 텍스트
    _valueText = TextComponent(
      text: value.toString(),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.x * 0.5,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_valueText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isDisabled) return;

    // 탭 효과
    add(
      ScaleEffect.by(
        Vector2.all(0.9),
        EffectController(duration: 0.1),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_isDisabled) return;

    add(
      ScaleEffect.by(
        Vector2.all(1 / 0.9),
        EffectController(duration: 0.1),
      ),
    );

    onTap();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (_isDisabled) return;

    add(
      ScaleEffect.by(
        Vector2.all(1 / 0.9),
        EffectController(duration: 0.1),
      ),
    );
  }

  /// 선택 상태 설정
  void setSelected(bool selected) {
    _isSelected = selected;
    _isDisabled = true;
  }

  /// 정답 표시
  void showCorrect() {
    _currentColor = const Color(0xFF00B894);
    _background.paint = Paint()..color = _currentColor;

    // 성공 애니메이션
    add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(1.2),
          EffectController(duration: 0.15),
        ),
        ScaleEffect.by(
          Vector2.all(1 / 1.2),
          EffectController(duration: 0.15),
        ),
      ]),
    );
  }

  /// 오답 표시
  void showWrong() {
    _currentColor = const Color(0xFFE17055);
    _background.paint = Paint()..color = _currentColor;

    // 흔들기 애니메이션
    add(
      SequenceEffect([
        MoveByEffect(
          Vector2(-8, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(16, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(-16, 0),
          EffectController(duration: 0.05),
        ),
        MoveByEffect(
          Vector2(8, 0),
          EffectController(duration: 0.05),
        ),
      ]),
    );
  }

  /// 리셋
  void reset() {
    _isSelected = false;
    _isDisabled = false;
    _currentColor = const Color(0xFF6C63FF);
    _background.paint = Paint()..color = _currentColor;
    scale = Vector2.all(1);
  }

  /// 비활성화
  void disable() {
    _isDisabled = true;
    _currentColor = Colors.grey;
    _background.paint = Paint()..color = _currentColor;
  }
}
