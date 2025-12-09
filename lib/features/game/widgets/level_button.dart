import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LevelButton extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final int maxStars;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const LevelButton({
    super.key,
    required this.levelNumber,
    required this.stars,
    required this.maxStars,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 잠금 아이콘 또는 레벨 번호
            if (!isUnlocked)
              Icon(
                Icons.lock,
                color: Colors.grey.shade500,
                size: 32,
              )
            else
              Text(
                levelNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            // 별점
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxStars, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: isUnlocked
                      ? (index < stars ? AppColors.star : Colors.white54)
                      : Colors.grey.shade400,
                  size: 16,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
