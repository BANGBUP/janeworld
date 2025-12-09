import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 인스트럭션 텍스트
class InstructionText extends PositionComponent {
  String _text;
  Color _color;

  late TextComponent _textComponent;

  InstructionText({
    required String text,
    required Vector2 position,
    Color color = Colors.black87,
  })  : _text = text,
        _color = color,
        super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _textComponent = TextComponent(
      text: _text,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
      anchor: Anchor.center,
    );
    add(_textComponent);
  }

  /// 텍스트 변경
  void setText(String newText) {
    _text = newText;
    _textComponent.text = newText;
  }

  /// 색상 변경
  void setColor(Color newColor) {
    _color = newColor;
    _textComponent.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _color,
      ),
    );
  }

  /// 텍스트와 색상 동시 변경
  void updateContent(String newText, Color newColor) {
    setText(newText);
    setColor(newColor);
  }
}
