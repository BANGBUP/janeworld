import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'web_utils_stub.dart' if (dart.library.html) 'web_utils.dart' as web_utils;

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/pack_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../domain/entities/game_pack.dart';
import '../widgets/profile_switcher_dialog.dart';
import '../widgets/character_creation_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // 위아래로 살짝 움직이는 애니메이션
    _bounceAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 살짝 기울어지는 애니메이션
    _rotateAnim = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(installedPacksProvider);
    final profile = ref.watch(activeProfileProvider);
    final character = ref.watch(userCharacterProvider);
    final recommendation = ref.watch(todayRecommendationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: packsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (packs) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 헤더
                _buildHeader(context, ref, profile),
                const SizedBox(height: 24),

                // 2. 캐릭터 호스트 섹션 (캐릭터 + 오른쪽 카드들)
                _buildCharacterHostSection(
                  context,
                  ref,
                  profile?.name ?? '친구',
                  character,
                  recommendation,
                ),
                const SizedBox(height: 24),

                // 4. 내 게임팩 섹션
                _buildMyGamePacksSection(context, packs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. 헤더: 로고 + 스토어 + 프로필
  // ============================================================
  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic profile) {
    return Row(
      children: [
        // 로고
        const Text(
          'JaneWorld',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF455A64),
          ),
        ),
        const Spacer(),

        // 스토어 버튼
        _buildStoreButton(context),
        const SizedBox(width: 12),

        // 다운로드 버튼 (웹에서만 표시)
        if (kIsWeb) ...[
          _buildDownloadButton(context),
          const SizedBox(width: 12),
        ],

        // 프로필 아바타
        _buildProfileAvatar(context, ref, profile),
        const SizedBox(width: 12),

        // 설정 버튼
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings, color: Color(0xFF455A64), size: 28),
        ),
      ],
    );
  }

  Widget _buildStoreButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/store'),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '게임팩 스토어',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return InkWell(
      onTap: () => _showDownloadDialog(context),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text('앱 다운로드'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '설치형 앱을 다운로드하면\n더 빠르고 안정적으로 즐길 수 있어요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildDownloadOption(
              icon: Icons.window,
              label: 'Windows',
              subtitle: 'Windows 10/11',
              color: const Color(0xFF0078D4),
              onTap: () {
                Navigator.pop(context);
                _downloadFile('https://github.com/BANGBUP/janeworld/releases/download/v1.0.0/JaneWorld-windows.zip');
              },
            ),
            const SizedBox(height: 12),
            _buildDownloadOption(
              icon: Icons.android,
              label: 'Android',
              subtitle: 'Android 5.0+',
              color: const Color(0xFF3DDC84),
              onTap: () {
                Navigator.pop(context);
                _downloadFile('https://github.com/BANGBUP/janeworld/releases/download/v1.0.0/JaneWorld.apk');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: color),
          ],
        ),
      ),
    );
  }

  void _downloadFile(String url) {
    web_utils.openUrl(url);
  }

  Widget _buildProfileAvatar(BuildContext context, WidgetRef ref, dynamic profile) {
    return InkWell(
      onTap: () => _showProfileSwitcher(context, ref),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.purpleAccent, width: 2),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE1BEE7),
          child: profile?.avatarPath != null
              ? ClipOval(
                  child: Image.asset(
                    profile!.avatarPath!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.face, color: Colors.purple, size: 28),
        ),
      ),
    );
  }

  void _showProfileSwitcher(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ProfileSwitcherDialog(),
    );
  }

  // ============================================================
  // 2. 캐릭터 호스트 섹션 (캐릭터 + 오른쪽 카드 Column)
  // ============================================================
  Widget _buildCharacterHostSection(
    BuildContext context,
    WidgetRef ref,
    String userName,
    dynamic character,
    TodayRecommendation recommendation,
  ) {
    final greeting = character?.getRandomGreeting(userName) ?? '안녕 $userName! 오늘도 같이 놀자!';
    final hasCharacter = character != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 왼쪽: 캐릭터 + 말풍선
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 말풍선
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  greeting,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF455A64),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 캐릭터 이미지 (애니메이션 적용)
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: Transform.rotate(
                      angle: _rotateAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  height: 280,
                  width: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: character?.imagePath != null && character!.imagePath.isNotEmpty
                      ? Image.asset(
                          character.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultCharacter(),
                        )
                      : _buildDefaultCharacter(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // 오른쪽: 카드들 세로로 배치
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // 오늘의 추천 놀이 카드
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7E57C2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '오늘의 추천 놀이',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$userName랑 같이 ${recommendation.subtitle}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 플레이 버튼
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          context.push('/play/${recommendation.packId}/${recommendation.levelId}');
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 내 캐릭터 꾸미기 + 이어하기 (가로 배치)
              Row(
                children: [
                  // 캐릭터 만들기 카드
                  Expanded(
                    flex: 3,
                    child: _buildCreationCard(context, ref, hasCharacter),
                  ),
                  const SizedBox(width: 16),
                  // 이어하기 카드
                  Expanded(
                    flex: 2,
                    child: _buildContinueCard(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultCharacter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 몸체
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC80),
            borderRadius: BorderRadius.circular(60),
          ),
        ),
        // 얼굴
        Positioned(
          top: 15,
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 14, color: Color(0xFF5D4037)),
                    SizedBox(width: 18),
                    Icon(Icons.circle, size: 14, color: Color(0xFF5D4037)),
                  ],
                ),
                SizedBox(height: 10),
                Icon(Icons.sentiment_very_satisfied, size: 28, color: Color(0xFFFF8A65)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreationCard(BuildContext context, WidgetRef ref, bool hasCharacter) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showCharacterCreation(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 아이콘
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFFFF9800),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                // 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            hasCharacter ? '내 캐릭터 꾸미기' : '마법의 스케치북',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                          if (!hasCharacter) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasCharacter
                            ? '새로운 모습으로 변신해볼까?'
                            : '그림을 그리면 살아 움직여요!',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // 카메라/그리기 아이콘
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.brush_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
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

  void _showCharacterCreation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const CharacterCreationSheet(),
    );
  }

  Widget _buildContinueCard(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A65).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/play/demo_memory'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '이어하기',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '기억력 게임',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 4. 내 게임팩 섹션
  // ============================================================
  Widget _buildMyGamePacksSection(BuildContext context, List<GamePack> packs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '내 게임팩',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF455A64),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-packs'),
              child: const Text('모두 보기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: packs.length + 1,
          itemBuilder: (context, index) {
            if (index < packs.length) {
              return _buildGamePackCard(context, packs[index]);
            } else {
              return _buildAddPackCard(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGamePackCard(BuildContext context, GamePack pack) {
    final isInstalled = pack.status == PackStatus.installed;
    final color = _getPackColor(pack.gameType);
    final thumbnailPath = 'assets/packs/${pack.packId}/thumbnail.png';

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isInstalled ? () => context.push('/play/${pack.packId}') : null,
          child: Stack(
            children: [
              // 썸네일 이미지
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    thumbnailPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: color,
                      child: Icon(
                        _getPackIcon(pack.gameType),
                        color: Colors.white.withOpacity(0.3),
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
              // 하단 그라데이션 오버레이
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        color.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pack.name['ko'] ?? pack.name['en'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isInstalled ? '${pack.totalLevels}개 레벨' : '설치 필요',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // 미설치 표시
              if (!isInstalled)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_download_outlined, color: color, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPackCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/store'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '게임팩 추가',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPackColor(String gameType) {
    switch (gameType) {
      case 'NumberLetterGame':
        return const Color(0xFF9575CD);
      case 'MemoryCardGame':
        return const Color(0xFFFF8A65);
      case 'ShapeColorGame':
        return const Color(0xFF4DB6AC);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  IconData _getPackIcon(String gameType) {
    switch (gameType) {
      case 'NumberLetterGame':
        return Icons.looks_one_rounded;
      case 'MemoryCardGame':
        return Icons.grid_view_rounded;
      case 'ShapeColorGame':
        return Icons.category_rounded;
      default:
        return Icons.games_rounded;
    }
  }
}
