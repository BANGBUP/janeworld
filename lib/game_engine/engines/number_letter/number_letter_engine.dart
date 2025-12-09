import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/base_mini_game.dart';
import 'components/countable_object.dart';
import 'components/choice_button.dart';
import 'components/instruction_text.dart';

/// 숫자/문자 학습 게임 엔진
class NumberLetterEngine extends BaseMiniGame {
  @override
  String get gameId => 'number_letter_engine';

  @override
  String get gameType => 'NumberLetterGame';

  @override
  List<String> get supportedModes => [
        'learning', // 학습 모드
        'counting', // 세기 모드
        'matching', // 매칭 모드
        'tracing', // 따라쓰기 모드
      ];

  // 게임 설정
  late String _mode;
  late int _targetNumber;
  late String _objectType;
  late String? _objectImagePath;
  late List<int> _choices;
  late bool _showHint;
  late String? _voicePromptPath;
  late int? _timeLimitSeconds;
  late String? _instructionText;

  // 게임 컴포넌트
  final List<CountableObject> _objects = [];
  final List<ChoiceButton> _choiceButtons = [];
  InstructionText? _instruction;

  // 상태
  bool _answered = false;
  int? _selectedAnswer;

  @override
  void parseGameConfig(Map<String, dynamic> settings) {
    _mode = settings['mode'] as String? ?? 'counting';
    _targetNumber = settings['target_number'] as int? ?? 1;
    _objectType = settings['count_objects'] as String? ?? 'star';
    _objectImagePath = settings['object_image'] as String?;
    _choices = List<int>.from(settings['choices'] ?? [1, 2, 3, 4]);
    _showHint = settings['show_hint'] as bool? ?? true;
    _voicePromptPath = settings['voice_prompt'] as String?;
    _timeLimitSeconds = settings['time_limit_seconds'] as int?;
    _instructionText = settings['instruction'] as String?;
  }

  @override
  Future<void> onInitialize() async {
    // 배경 색상 설정
    final bgColor = levelConfig.assets.background != null
        ? const Color(0xFFF0F8FF)
        : backgroundColor();

    // 인스트럭션 텍스트
    _instruction = InstructionText(
      text: _instructionText ?? '몇 개일까요?',
      position: Vector2(size.x / 2, 60),
    );
    add(_instruction!);

    // 모드별 초기화
    switch (_mode) {
      case 'counting':
        await _initCountingMode();
        break;
      case 'matching':
        await _initMatchingMode();
        break;
      default:
        await _initCountingMode();
    }
  }

  Future<void> _initCountingMode() async {
    _objects.clear();
    _choiceButtons.clear();

    // 세기 대상 오브젝트 생성
    final objectSize = Vector2(80, 80);
    final spacing = 100.0;
    final startX = (size.x - (_targetNumber * spacing)) / 2 + spacing / 2;
    final objectY = size.y * 0.35;

    for (int i = 0; i < _targetNumber; i++) {
      final obj = CountableObject(
        number: i + 1,
        objectType: _objectType,
        imagePath: _objectImagePath,
        position: Vector2(startX + i * spacing, objectY),
        size: objectSize,
        showNumber: _showHint,
        assets: packAssets,
      );
      _objects.add(obj);
      add(obj);
    }

    // 선택지 버튼 생성
    final buttonSize = Vector2(100, 100);
    final buttonSpacing = 130.0;
    final buttonStartX =
        (size.x - (_choices.length * buttonSpacing)) / 2 + buttonSpacing / 2;
    final buttonY = size.y * 0.7;

    for (int i = 0; i < _choices.length; i++) {
      final button = ChoiceButton(
        value: _choices[i],
        position: Vector2(buttonStartX + i * buttonSpacing, buttonY),
        size: buttonSize,
        onTap: () => _onChoiceSelected(_choices[i]),
      );
      _choiceButtons.add(button);
      add(button);
    }
  }

  Future<void> _initMatchingMode() async {
    // 매칭 모드 초기화 (추후 구현)
    await _initCountingMode();
  }

  void _onChoiceSelected(int selectedValue) {
    if (_answered) return;

    _answered = true;
    _selectedAnswer = selectedValue;

    // 선택된 버튼 표시
    for (final button in _choiceButtons) {
      if (button.value == selectedValue) {
        button.setSelected(true);
      }
    }

    if (selectedValue == _targetNumber) {
      // 정답
      _handleCorrectAnswer();
    } else {
      // 오답
      _handleWrongAnswer(selectedValue);
    }
  }

  void _handleCorrectAnswer() {
    addScore(100);

    // 정답 버튼 강조
    for (final button in _choiceButtons) {
      if (button.value == _targetNumber) {
        button.showCorrect();
      }
    }

    // 인스트럭션 변경
    _instruction?.setText('정답이에요! 잘했어요!');
    _instruction?.setColor(Colors.green);

    // 오브젝트 애니메이션
    for (final obj in _objects) {
      obj.celebrate();
    }

    // 게임 종료
    Future.delayed(const Duration(seconds: 2), () {
      endGame(completed: true);
    });
  }

  void _handleWrongAnswer(int selectedValue) {
    addMistake();

    // 오답 버튼 표시
    for (final button in _choiceButtons) {
      if (button.value == selectedValue) {
        button.showWrong();
      }
    }

    // 인스트럭션 변경
    _instruction?.setText('다시 세어볼까요?');
    _instruction?.setColor(Colors.orange);

    // 다시 시도 가능하게
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state == GameState.playing) {
        _resetForRetry();
      }
    });
  }

  void _resetForRetry() {
    _answered = false;
    _selectedAnswer = null;

    // 버튼 리셋
    for (final button in _choiceButtons) {
      button.reset();
    }

    // 인스트럭션 리셋
    _instruction?.setText(_instructionText ?? '몇 개일까요?');
    _instruction?.setColor(Colors.black87);

    // 힌트 표시
    if (_showHint) {
      for (int i = 0; i < _objects.length; i++) {
        Future.delayed(Duration(milliseconds: i * 300), () {
          if (i < _objects.length) {
            _objects[i].highlight();
          }
        });
      }
    }
  }

  @override
  void onGameStart() {
    // 음성 프롬프트 재생
    if (_voicePromptPath != null) {
      audioManager.playVoice(_voicePromptPath!);
    }
  }

  @override
  void onGameEnd(bool completed) {
    // 게임 종료 처리
  }

  @override
  Color backgroundColor() => const Color(0xFFF5F9FF);
}
