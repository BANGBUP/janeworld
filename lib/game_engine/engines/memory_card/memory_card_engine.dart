import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/base_mini_game.dart';
import 'components/memory_card.dart';

/// 메모리 카드 게임 엔진
class MemoryCardEngine extends BaseMiniGame {
  @override
  String get gameId => 'memory_card_engine';

  @override
  String get gameType => 'MemoryCardGame';

  @override
  List<String> get supportedModes => [
        'match_pairs', // 같은 쌍 찾기
        'match_image_word', // 이미지-단어 매칭
        'sequence', // 순서 맞추기
      ];

  // 게임 설정
  late String _mode;
  late int _gridRows;
  late int _gridCols;
  late List<CardPairData> _cardPairs;
  late int _flipDurationMs;
  late int _mismatchDelayMs;
  late int? _maxAttempts;

  // 게임 상태
  final List<MemoryCard> _cards = [];
  MemoryCard? _firstFlipped;
  MemoryCard? _secondFlipped;
  int _matchedPairs = 0;
  int _totalPairs = 0;
  bool _isChecking = false;

  // 스코어 텍스트
  late TextComponent _scoreText;
  late TextComponent _pairsText;

  @override
  void parseGameConfig(Map<String, dynamic> settings) {
    _mode = settings['mode'] as String? ?? 'match_pairs';

    final grid = settings['grid'] as Map<String, dynamic>? ?? {};
    _gridRows = grid['rows'] as int? ?? 2;
    _gridCols = grid['cols'] as int? ?? 3;

    _flipDurationMs = settings['flip_duration_ms'] as int? ?? 300;
    _mismatchDelayMs = settings['mismatch_delay_ms'] as int? ?? 1000;
    _maxAttempts = settings['max_attempts'] as int?;

    // 카드 쌍 데이터 파싱
    final cardPairsData = settings['card_pairs'] as List<dynamic>? ?? [];
    _cardPairs = cardPairsData.map((data) {
      final map = data as Map<String, dynamic>;
      return CardPairData(
        id: map['id'] as String,
        cardA: CardData.fromJson(map['card_a'] as Map<String, dynamic>),
        cardB: CardData.fromJson(map['card_b'] as Map<String, dynamic>),
      );
    }).toList();

    // 기본 카드 쌍이 없으면 이모지로 생성
    if (_cardPairs.isEmpty) {
      _cardPairs = _generateDefaultPairs();
    }
  }

  List<CardPairData> _generateDefaultPairs() {
    // 이모지 대신 도형 이름 사용 (Canvas로 그림)
    final shapes = ['apple', 'orange', 'star', 'heart', 'flower', 'ball', 'diamond', 'moon'];
    final count = (_gridRows * _gridCols) ~/ 2;

    return List.generate(count.clamp(1, shapes.length), (i) {
      return CardPairData(
        id: 'pair_$i',
        cardA: CardData(type: 'shape', content: shapes[i]),
        cardB: CardData(type: 'shape', content: shapes[i]),
      );
    });
  }

  @override
  Future<void> onInitialize() async {
    _cards.clear();
    _matchedPairs = 0;
    _totalPairs = _cardPairs.length;
    _firstFlipped = null;
    _secondFlipped = null;
    _isChecking = false;

    // 스코어 UI
    _scoreText = TextComponent(
      text: '점수: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      position: Vector2(20, 20),
    );
    add(_scoreText);

    _pairsText = TextComponent(
      text: '찾은 쌍: 0 / $_totalPairs',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      position: Vector2(size.x - 200, 20),
    );
    add(_pairsText);

    // 카드 생성 및 배치
    await _createCards();
  }

  Future<void> _createCards() async {
    // 카드 데이터 생성 (각 쌍당 2장)
    final allCardData = <_CardInstance>[];
    for (final pair in _cardPairs) {
      allCardData.add(_CardInstance(pairId: pair.id, data: pair.cardA, isA: true));
      allCardData.add(_CardInstance(pairId: pair.id, data: pair.cardB, isA: false));
    }

    // 셔플
    allCardData.shuffle(Random());

    // 그리드 계산
    final cardWidth = (size.x - 100) / _gridCols - 20;
    final cardHeight = (size.y - 150) / _gridRows - 20;
    final cardSize = Vector2(
      cardWidth.clamp(60, 120),
      cardHeight.clamp(80, 150),
    );

    final startX = (size.x - (_gridCols * (cardSize.x + 15))) / 2 + cardSize.x / 2;
    final startY = 100;

    int index = 0;
    for (int row = 0; row < _gridRows; row++) {
      for (int col = 0; col < _gridCols; col++) {
        if (index >= allCardData.length) break;

        final cardInstance = allCardData[index];
        final card = MemoryCard(
          cardIndex: index,
          pairId: cardInstance.pairId,
          cardData: cardInstance.data,
          position: Vector2(
            startX + col * (cardSize.x + 15),
            startY + row * (cardSize.y + 15),
          ),
          size: cardSize,
          onFlip: _onCardFlipped,
        );

        _cards.add(card);
        add(card);
        index++;
      }
    }
  }

  void _onCardFlipped(MemoryCard card) {
    if (_isChecking) return;
    if (card.isMatched || card.isFlipped) return;

    card.flip();

    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else if (_secondFlipped == null && card != _firstFlipped) {
      _secondFlipped = card;
      _isChecking = true;
      _checkMatch();
    }
  }

  void _checkMatch() {
    if (_firstFlipped == null || _secondFlipped == null) return;

    final isMatch = _firstFlipped!.pairId == _secondFlipped!.pairId;

    if (isMatch) {
      // 매칭 성공
      _firstFlipped!.setMatched();
      _secondFlipped!.setMatched();
      _matchedPairs++;
      addScore(100);

      _updateUI();

      // 모든 쌍을 찾았는지 확인
      if (_matchedPairs >= _totalPairs) {
        Future.delayed(const Duration(milliseconds: 500), () {
          endGame(completed: true);
        });
      }

      _resetSelection();
    } else {
      // 매칭 실패
      addMistake();

      Future.delayed(Duration(milliseconds: _mismatchDelayMs), () {
        _firstFlipped?.flipBack();
        _secondFlipped?.flipBack();
        _resetSelection();
      });
    }
  }

  void _resetSelection() {
    _firstFlipped = null;
    _secondFlipped = null;
    _isChecking = false;
  }

  void _updateUI() {
    _scoreText.text = '점수: $score';
    _pairsText.text = '찾은 쌍: $_matchedPairs / $_totalPairs';
  }

  @override
  void onGameStart() {
    // 게임 시작시 잠시 모든 카드 보여주기 (선택적)
  }

  @override
  void onGameEnd(bool completed) {
    // 별점 계산
    if (completed) {
      final efficiency = _totalPairs * 2 / (_totalPairs * 2 + mistakes);
      if (efficiency > 0.8) {
        setStars(3);
      } else if (efficiency > 0.6) {
        setStars(2);
      } else {
        setStars(1);
      }
    }
  }

  @override
  Color backgroundColor() => const Color(0xFFFFF5E6);
}

/// 카드 쌍 데이터
class CardPairData {
  final String id;
  final CardData cardA;
  final CardData cardB;

  CardPairData({
    required this.id,
    required this.cardA,
    required this.cardB,
  });
}

/// 개별 카드 데이터
class CardData {
  final String type; // 'emoji', 'image', 'text'
  final String content;
  final String? voice;

  CardData({
    required this.type,
    required this.content,
    this.voice,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      voice: json['voice'] as String?,
    );
  }
}

/// 내부 카드 인스턴스
class _CardInstance {
  final String pairId;
  final CardData data;
  final bool isA;

  _CardInstance({
    required this.pairId,
    required this.data,
    required this.isA,
  });
}
