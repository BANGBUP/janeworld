import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../domain/entities/user_profile.dart';

class CharacterCreationSheet extends ConsumerStatefulWidget {
  const CharacterCreationSheet({super.key});

  @override
  ConsumerState<CharacterCreationSheet> createState() => _CharacterCreationSheetState();
}

class _CharacterCreationSheetState extends ConsumerState<CharacterCreationSheet> {
  int _selectedOption = -1;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Color(0xFFFF9800),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '마법의 스케치북',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    Text(
                      '나만의 친구를 만들어보자!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 선택 옵션들
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 옵션 1: 그리기
                  _buildCreationOption(
                    index: 0,
                    icon: Icons.brush_rounded,
                    iconColor: const Color(0xFFE91E63),
                    bgColor: const Color(0xFFFCE4EC),
                    title: '직접 그리기',
                    description: '터치로 그림을 그려서 캐릭터를 만들어요',
                    tag: '추천',
                    tagColor: const Color(0xFFE91E63),
                  ),
                  const SizedBox(height: 16),

                  // 옵션 2: 카메라
                  _buildCreationOption(
                    index: 1,
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFF2196F3),
                    bgColor: const Color(0xFFE3F2FD),
                    title: '사진 찍기',
                    description: '종이에 그린 그림을 카메라로 찍어요',
                    tag: null,
                    tagColor: null,
                  ),
                  const SizedBox(height: 16),

                  // 옵션 3: 갤러리
                  _buildCreationOption(
                    index: 2,
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    bgColor: const Color(0xFFE8F5E9),
                    title: '앨범에서 선택',
                    description: '이미 저장된 그림을 불러와요',
                    tag: null,
                    tagColor: null,
                  ),
                  const SizedBox(height: 16),

                  // 옵션 4: 기본 캐릭터
                  _buildCreationOption(
                    index: 3,
                    icon: Icons.pets_rounded,
                    iconColor: const Color(0xFFFF9800),
                    bgColor: const Color(0xFFFFF3E0),
                    title: '기본 친구 선택',
                    description: '귀여운 기본 캐릭터 중에서 골라요',
                    tag: '간편',
                    tagColor: const Color(0xFFFF9800),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedOption >= 0
                        ? () => _handleCreation(_selectedOption)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreationOption({
    required int index,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    String? tag,
    Color? tagColor,
  }) {
    final isSelected = _selectedOption == index;

    return Material(
      color: isSelected ? bgColor.withOpacity(0.5) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _selectedOption = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? iconColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 20),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 선택 표시
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? iconColor : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? iconColor : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreation(int option) {
    Navigator.pop(context);

    switch (option) {
      case 0:
        // 직접 그리기 - 그리기 화면으로 이동
        _showDrawingScreen();
        break;
      case 1:
        // 카메라
        _openCamera();
        break;
      case 2:
        // 갤러리
        _openGallery();
        break;
      case 3:
        // 기본 캐릭터 선택
        _showDefaultCharacters();
        break;
    }
  }

  void _showDrawingScreen() {
    // TODO: 그리기 화면 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('그리기 기능 준비 중...')),
    );
  }

  void _openCamera() {
    // TODO: 카메라 열기
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카메라 기능 준비 중...')),
    );
  }

  void _openGallery() {
    // TODO: 갤러리 열기
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('갤러리 기능 준비 중...')),
    );
  }

  void _showDefaultCharacters() {
    // ref를 미리 캡처해서 widget unmount 후에도 사용 가능하게 함
    final notifier = ref.read(userCharacterProvider.notifier);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _DefaultCharacterSelector(
        onSelect: (character) {
          notifier.setCharacter(character);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

class _DefaultCharacterSelector extends StatelessWidget {
  final Function(UserCharacter) onSelect;

  const _DefaultCharacterSelector({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final characters = [
      _CharacterOption(
        id: 'default_star',
        name: '별이',
        imagePath: 'assets/characters/star_character.png',
        color: const Color(0xFFFFD54F),
        greetings: ['안녕 {name}! 오늘도 반짝반짝!', '{name}! 같이 놀자!'],
      ),
      _CharacterOption(
        id: 'default_bunny',
        name: '토토',
        imagePath: 'assets/characters/bunny_character.png',
        color: const Color(0xFFFFAB91),
        greetings: ['깡충깡충! {name} 왔구나!', '{name}! 당근 먹을래?'],
      ),
      _CharacterOption(
        id: 'default_whale',
        name: '파랑이',
        imagePath: 'assets/characters/whale_character.png',
        color: const Color(0xFF81D4FA),
        greetings: ['첨벙첨벙! {name} 안녕!', '{name}! 바다로 가자!'],
      ),
      _CharacterOption(
        id: 'default_flower',
        name: '핑키',
        imagePath: 'assets/characters/flower_character.png',
        color: const Color(0xFFF8BBD9),
        greetings: ['살랑살랑~ {name}!', '{name}! 꽃놀이 갈까?'],
      ),
      _CharacterOption(
        id: 'default_leaf',
        name: '초록이',
        imagePath: 'assets/characters/leaf_character.png',
        color: const Color(0xFFA5D6A7),
        greetings: ['솨솨솨~ {name} 왔다!', '{name}! 숲에서 놀자!'],
      ),
      _CharacterOption(
        id: 'default_rainbow',
        name: '해피',
        imagePath: 'assets/characters/rainbow_character.png',
        color: const Color(0xFFCE93D8),
        greetings: ['무지개처럼! {name}!', '{name}! 행복한 하루!'],
      ),
    ];

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(40),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '기본 친구 선택',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final char = characters[index];
                return InkWell(
                  onTap: () {
                    final userChar = UserCharacter(
                      id: char.id,
                      name: char.name,
                      imagePath: char.imagePath,
                      greetings: char.greetings,
                      createdAt: DateTime.now(),
                    );
                    onSelect(userChar);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: char.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: char.color, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              char.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            char.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }
}

class _CharacterOption {
  final String id;
  final String name;
  final String imagePath;
  final Color color;
  final List<String> greetings;

  _CharacterOption({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.color,
    required this.greetings,
  });
}
