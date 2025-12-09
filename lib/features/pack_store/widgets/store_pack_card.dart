import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_pack.dart';

class StorePackCard extends StatelessWidget {
  final GamePack pack;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const StorePackCard({
    super.key,
    required this.pack,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 이미지/아이콘 영역
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _getGradient(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),

            // 하단 정보 영역
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      pack.getLocalizedName('ko'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 레벨 수
                    Text(
                      '${pack.totalLevels}개 레벨 · ${pack.storageSizeMb}MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),

                    // 다운로드 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '무료',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (pack.gameType) {
      case 'NumberLetterGame':
        return AppColors.gradientPrimary;
      case 'MemoryCardGame':
        return AppColors.gradientSecondary;
      case 'ShapeColorGame':
        return AppColors.gradientSuccess;
      default:
        return const LinearGradient(
          colors: [Color(0xFF636E72), Color(0xFFB2BEC3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getIcon() {
    switch (pack.gameType) {
      case 'NumberLetterGame':
        return Icons.calculate;
      case 'MemoryCardGame':
        return Icons.grid_view;
      case 'ShapeColorGame':
        return Icons.category;
      case 'PuzzleGame':
        return Icons.extension;
      default:
        return Icons.games;
    }
  }
}
