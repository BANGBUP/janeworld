import 'package:flutter/material.dart';

import '../../../domain/entities/game_pack.dart';

class PackCardWidget extends StatelessWidget {
  final GamePack pack;
  final VoidCallback onTap;

  const PackCardWidget({
    super.key,
    required this.pack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getGradient(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Spacer(),
                // 제목
                Text(
                  pack.getLocalizedName('ko'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 레벨 수
                Text(
                  '${pack.totalLevels}개 레벨',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (pack.gameType) {
      case 'NumberLetterGame':
        return const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MemoryCardGame':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'ShapeColorGame':
        return const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
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
