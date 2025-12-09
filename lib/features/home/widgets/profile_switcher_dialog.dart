import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileSwitcherDialog extends ConsumerWidget {
  const ProfileSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(allProfilesProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Text(
                  '프로필 선택',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF455A64),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 프로필 목록
            ...profiles.map((profile) => _buildProfileItem(
                  context,
                  ref,
                  profile,
                  profile.id == activeProfile?.id,
                )),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 프로필 추가 버튼
            _buildAddProfileButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isActive ? const Color(0xFFE8EAF6) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            ref.read(activeProfileProvider.notifier).setProfile(profile);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Colors.purpleAccent : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // 아바타
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? Colors.purpleAccent : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE1BEE7),
                    child: profile.avatarPath != null
                        ? ClipOval(child: Image.asset(profile.avatarPath!))
                        : Text(
                            profile.name.isNotEmpty ? profile.name[0] : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // 이름
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      Text(
                        '${profile.age}살',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 활성 표시
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '사용 중',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddProfileButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddProfileDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Text(
                '새 프로필 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int selectedAge = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('새 프로필 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '이름',
                  hintText: '아이 이름을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('나이: '),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedAge,
                    items: List.generate(10, (i) => i + 3)
                        .map((age) => DropdownMenuItem(
                              value: age,
                              child: Text('$age살'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedAge = value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newProfile = UserProfile(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    age: selectedAge,
                    createdAt: DateTime.now(),
                  );
                  ref.read(allProfilesProvider.notifier).addProfile(newProfile);
                  ref.read(activeProfileProvider.notifier).setProfile(newProfile);
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text('만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
