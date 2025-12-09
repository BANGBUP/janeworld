import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_result.dart';

class GameResultOverlay extends StatelessWidget {
  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onQuit;

  const GameResultOverlay({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onNext,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = result.completed;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 결과 아이콘
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 64,
                    color: isCompleted ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),

                // 결과 텍스트
                Text(
                  isCompleted ? '잘했어요!' : '다시 도전해봐요!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),

                // 별점
                if (isCompleted) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < result.stars ? Icons.star : Icons.star_border,
                          size: 48,
                          color: AppColors.star,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // 점수
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '점수: ${result.score}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 플레이 시간
                Text(
                  '플레이 시간: ${_formatDuration(result.playDuration)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // 버튼들
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // 나가기 버튼
                    OutlinedButton.icon(
                      onPressed: onQuit,
                      icon: const Icon(Icons.home),
                      label: const Text('나가기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),

                    // 다시하기 버튼
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),

                    // 다음 레벨 버튼
                    if (isCompleted)
                      ElevatedButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('다음 레벨'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }
}
