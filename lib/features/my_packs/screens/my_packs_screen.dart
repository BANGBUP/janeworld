import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_pack.dart';

class MyPacksScreen extends ConsumerStatefulWidget {
  const MyPacksScreen({super.key});

  @override
  ConsumerState<MyPacksScreen> createState() => _MyPacksScreenState();
}

class _MyPacksScreenState extends ConsumerState<MyPacksScreen> {
  List<GamePack> _installedPacks = [];
  bool _isLoading = true;
  int _totalStorageMb = 0;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = false;
      _installedPacks = [
        GamePack(
          packId: 'demo_numbers',
          version: '1.0.0',
          name: {'ko': '숫자 세기', 'en': 'Counting Numbers'},
          description: {'ko': '1부터 10까지 세어보아요!'},
          author: 'JaneWorld',
          gameType: 'NumberLetterGame',
          totalLevels: 5,
          storageSizeMb: 5,
          minAge: 3,
          maxAge: 6,
          skillTags: ['number', 'counting'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 15,
          supportedLocales: ['ko', 'en'],
          minAppVersion: '1.0.0',
          status: PackStatus.installed,
          installedAt: DateTime.now().subtract(const Duration(days: 7)),
          lastPlayedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        GamePack(
          packId: 'demo_memory',
          version: '1.0.0',
          name: {'ko': '기억력 게임', 'en': 'Memory Game'},
          description: {'ko': '같은 카드를 찾아보아요!'},
          author: 'JaneWorld',
          gameType: 'MemoryCardGame',
          totalLevels: 5,
          storageSizeMb: 8,
          minAge: 4,
          maxAge: 8,
          skillTags: ['memory', 'matching'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 20,
          supportedLocales: ['ko', 'en'],
          minAppVersion: '1.0.0',
          status: PackStatus.installed,
          installedAt: DateTime.now().subtract(const Duration(days: 5)),
          lastPlayedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        GamePack(
          packId: 'demo_shapes',
          version: '1.0.0',
          name: {'ko': '모양 맞추기', 'en': 'Shape Match'},
          description: {'ko': '같은 모양을 찾아보아요!'},
          author: 'JaneWorld',
          gameType: 'ShapeColorGame',
          totalLevels: 5,
          storageSizeMb: 5,
          minAge: 3,
          maxAge: 6,
          skillTags: ['shape', 'color'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 15,
          supportedLocales: ['ko', 'en'],
          minAppVersion: '1.0.0',
          status: PackStatus.installed,
          installedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      _totalStorageMb = _installedPacks.fold(0, (sum, pack) => sum + pack.storageSizeMb);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 저장 공간 정보
            _buildStorageInfo(),

            // 팩 목록
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPackList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            iconSize: 28,
          ),
          const SizedBox(width: 16),
          const Text(
            '📦 내 게임팩',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.push('/store'),
            icon: const Icon(Icons.add),
            label: const Text('게임팩 추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            '사용 중인 저장 공간: $_totalStorageMb MB',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            '${_installedPacks.length}개 팩',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _installedPacks.length,
      itemBuilder: (context, index) {
        final pack = _installedPacks[index];
        return _buildPackItem(pack);
      },
    );
  }

  Widget _buildPackItem(GamePack pack) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/play/${pack.packId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _getGradient(pack.gameType),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(pack.gameType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.getLocalizedName('ko'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pack.totalLevels}개 레벨 · ${pack.storageSizeMb}MB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (pack.lastPlayedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '마지막 플레이: ${_formatDate(pack.lastPlayedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 플레이 버튼
              ElevatedButton(
                onPressed: () => context.push('/play/${pack.packId}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('플레이'),
              ),

              // 더보기 메뉴
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelected(value, pack),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('상세 정보'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _onMenuSelected(String value, GamePack pack) {
    switch (value) {
      case 'info':
        context.push('/store/${pack.packId}');
        break;
      case 'delete':
        _showDeleteDialog(pack);
        break;
    }
  }

  void _showDeleteDialog(GamePack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임팩 삭제'),
        content: Text('${pack.getLocalizedName('ko')}을(를) 삭제하시겠습니까?\n진행 상황은 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 실제 삭제 로직
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pack.getLocalizedName('ko')} 삭제됨')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
