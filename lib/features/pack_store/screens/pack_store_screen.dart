import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_pack.dart';
import '../widgets/store_pack_card.dart';

class PackStoreScreen extends ConsumerStatefulWidget {
  const PackStoreScreen({super.key});

  @override
  ConsumerState<PackStoreScreen> createState() => _PackStoreScreenState();
}

class _PackStoreScreenState extends ConsumerState<PackStoreScreen> {
  List<GamePack> _availablePacks = [];
  bool _isLoading = true;
  String _selectedCategory = '전체';

  final List<String> _categories = ['전체', '숫자', '기억력', '모양', '언어'];

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _availablePacks = [
        GamePack(
          packId: 'numbers_advanced',
          version: '1.0.0',
          name: {'ko': '숫자 마스터', 'en': 'Number Master'},
          description: {'ko': '10부터 100까지 숫자를 배워요!'},
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
        ),
        GamePack(
          packId: 'memory_animals',
          version: '1.0.0',
          name: {'ko': '동물 카드 게임', 'en': 'Animal Cards'},
          description: {'ko': '귀여운 동물 카드를 맞춰보세요!'},
          author: 'JaneWorld',
          gameType: 'MemoryCardGame',
          totalLevels: 10,
          storageSizeMb: 15,
          minAge: 4,
          maxAge: 7,
          skillTags: ['memory', 'animals'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 30,
          supportedLocales: ['ko', 'en'],
          minAppVersion: '1.0.0',
          status: PackStatus.available,
        ),
        GamePack(
          packId: 'shapes_colors',
          version: '1.0.0',
          name: {'ko': '색깔 나라', 'en': 'Color World'},
          description: {'ko': '다양한 색깔과 모양을 배워요!'},
          author: 'JaneWorld',
          gameType: 'ShapeColorGame',
          totalLevels: 12,
          storageSizeMb: 10,
          minAge: 3,
          maxAge: 6,
          skillTags: ['color', 'shape'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 25,
          supportedLocales: ['ko', 'en'],
          minAppVersion: '1.0.0',
          status: PackStatus.available,
        ),
        GamePack(
          packId: 'korean_basic',
          version: '1.0.0',
          name: {'ko': '한글 첫걸음', 'en': 'Korean Basics'},
          description: {'ko': 'ㄱㄴㄷ부터 시작해요!'},
          author: 'JaneWorld',
          gameType: 'NumberLetterGame',
          totalLevels: 20,
          storageSizeMb: 18,
          minAge: 4,
          maxAge: 7,
          skillTags: ['korean', 'letter', 'language'],
          difficulty: 'beginner',
          estimatedPlayTimeMinutes: 60,
          supportedLocales: ['ko'],
          minAppVersion: '1.0.0',
          status: PackStatus.available,
        ),
      ];
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

            // 카테고리 탭
            _buildCategoryTabs(),

            // 팩 그리드
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPackGrid(),
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
            '🏪 게임팩 스토어',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 검색 버튼
          IconButton(
            onPressed: () {
              // TODO: 검색
            },
            icon: const Icon(Icons.search),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _availablePacks.length,
        itemBuilder: (context, index) {
          return StorePackCard(
            pack: _availablePacks[index],
            onTap: () => _onPackTap(_availablePacks[index]),
            onDownload: () => _onDownload(_availablePacks[index]),
          );
        },
      ),
    );
  }

  void _onPackTap(GamePack pack) {
    context.push('/store/${pack.packId}');
  }

  void _onDownload(GamePack pack) {
    // TODO: 다운로드 시작
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pack.getLocalizedName('ko')} 다운로드 시작...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
