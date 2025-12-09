import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRetry,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause_circle_filled,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // 타이틀
                const Text(
                  '일시정지',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '잠시 쉬어갈까요?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // 버튼들
                Column(
                  children: [
                    // 계속하기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onResume,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('계속하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 다시하기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시하기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 나가기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: onQuit,
                        icon: Icon(Icons.exit_to_app, color: Colors.grey.shade600),
                        label: Text(
                          '나가기',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
}
