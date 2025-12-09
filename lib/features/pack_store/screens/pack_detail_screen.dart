import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_pack.dart';

class PackDetailScreen extends ConsumerWidget {
  final String packId;

  const PackDetailScreen({
    super.key,
    required this.packId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 실제 팩 데이터 로드
    final pack = _getDemoPack();

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 왼쪽: 썸네일/프리뷰
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _getGradient(pack.gameType),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIcon(pack.gameType),
                      size: 120,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      pack.getLocalizedName('ko'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 오른쪽: 상세 정보
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 바
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close),
                          iconSize: 28,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    Text(
                      pack.getLocalizedName('ko'),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${pack.author}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 설명
                    Text(
                      pack.getLocalizedDescription('ko'),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 정보 태그
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildInfoChip(
                          Icons.layers,
                          '${pack.totalLevels}개 레벨',
                        ),
                        _buildInfoChip(
                          Icons.schedule,
                          '약 ${pack.estimatedPlayTimeMinutes}분',
                        ),
                        _buildInfoChip(
                          Icons.storage,
                          '${pack.storageSizeMb} MB',
                        ),
                        _buildInfoChip(
                          Icons.child_care,
                          '${pack.minAge}-${pack.maxAge}세',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 스킬 태그
                    Wrap(
                      spacing: 8,
                      children: pack.skillTags.map((tag) {
                        return Chip(
                          label: Text(_translateTag(tag)),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // 다운로드 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: 다운로드
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${pack.getLocalizedName('ko')} 다운로드를 시작합니다...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('무료 다운로드'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 18,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _translateTag(String tag) {
    const translations = {
      'number': '숫자',
      'counting': '세기',
      'math': '수학',
      'memory': '기억력',
      'matching': '매칭',
      'animals': '동물',
      'color': '색깔',
      'shape': '모양',
      'korean': '한글',
      'letter': '문자',
      'language': '언어',
    };
    return translations[tag] ?? tag;
  }

  LinearGradient _getGradient(String gameType) {
    switch (gameType) {
      case 'NumberLetterGame':
        return AppColors.gradientPrimary;
      case 'MemoryCardGame':
        return AppColors.gradientSecondary;
      case 'ShapeColorGame':
        return AppColors.gradientSuccess;
      default:
        return AppColors.gradientPrimary;
    }
  }

  IconData _getIcon(String gameType) {
    switch (gameType) {
      case 'NumberLetterGame':
        return Icons.calculate;
      case 'MemoryCardGame':
        return Icons.grid_view;
      case 'ShapeColorGame':
        return Icons.category;
      default:
        return Icons.games;
    }
  }

  GamePack _getDemoPack() {
    return GamePack(
      packId: packId,
      version: '1.0.0',
      name: {'ko': '숫자 마스터', 'en': 'Number Master'},
      description: {'ko': '10부터 100까지 숫자를 재미있게 배워보아요! 다양한 게임과 활동을 통해 수의 개념을 익힐 수 있어요.'},
      author: 'JaneWorld',
      gameType: 'NumberLetterGame',
      totalLevels: 15,
      storageSizeMb: 12,
      minAge: 5,
      maxAge: 8,
      skillTags: ['number', 'counting', 'math'],
      difficulty: 'intermediate',
      estimatedPlayTimeMinutes: 45,
      supportedLocales: ['ko', 'en'],
      minAppVersion: '1.0.0',
      status: PackStatus.available,
    );
  }
}
