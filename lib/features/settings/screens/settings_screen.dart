import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// 설정 상태 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsState {
  final bool soundEnabled;
  final bool musicEnabled;
  final double soundVolume;
  final double musicVolume;
  final String locale;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.soundVolume = 0.8,
    this.musicVolume = 0.5,
    this.locale = 'ko',
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    double? soundVolume,
    double? musicVolume,
    String? locale,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
  }

  void setMusicEnabled(bool value) {
    state = state.copyWith(musicEnabled: value);
  }

  void setSoundVolume(double value) {
    state = state.copyWith(soundVolume: value);
  }

  void setMusicVolume(double value) {
    state = state.copyWith(musicVolume: value);
  }

  void setLocale(String value) {
    state = state.copyWith(locale: value);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context),

            // 설정 목록
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 사운드 설정 섹션
                  _buildSectionTitle('사운드'),
                  const SizedBox(height: 12),
                  _buildSoundSettings(context, ref, settings),

                  const SizedBox(height: 32),

                  // 언어 설정 섹션
                  _buildSectionTitle('언어'),
                  const SizedBox(height: 12),
                  _buildLanguageSettings(context, ref, settings),

                  const SizedBox(height: 32),

                  // 데이터 관리 섹션
                  _buildSectionTitle('데이터 관리'),
                  const SizedBox(height: 12),
                  _buildDataSettings(context),

                  const SizedBox(height: 32),

                  // 앱 정보 섹션
                  _buildSectionTitle('앱 정보'),
                  const SizedBox(height: 12),
                  _buildAppInfo(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            '설정',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSoundSettings(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 효과음 토글
            SwitchListTile(
              title: const Text('효과음'),
              subtitle: const Text('게임 효과음 활성화'),
              value: settings.soundEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setSoundEnabled(value);
              },
            ),

            // 효과음 볼륨
            if (settings.soundEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down, size: 20),
                    Expanded(
                      child: Slider(
                        value: settings.soundVolume,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).setSoundVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 20),
                  ],
                ),
              ),

            const Divider(),

            // 배경음악 토글
            SwitchListTile(
              title: const Text('배경음악'),
              subtitle: const Text('배경음악 활성화'),
              value: settings.musicEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setMusicEnabled(value);
              },
            ),

            // 배경음악 볼륨
            if (settings.musicEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down, size: 20),
                    Expanded(
                      child: Slider(
                        value: settings.musicVolume,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).setMusicVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('한국어'),
              value: 'ko',
              groupValue: settings.locale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(value);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: settings.locale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('진행 상황 초기화'),
              subtitle: const Text('모든 게임 진행 상황을 초기화합니다'),
              onTap: () => _showResetConfirmDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('다운로드 캐시 삭제'),
              subtitle: const Text('다운로드된 게임팩 캐시를 삭제합니다'),
              onTap: () => _showCacheClearDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('앱 버전'),
              trailing: Text('1.0.0'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('개인정보 처리방침'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 개인정보 처리방침 페이지로 이동
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('이용약관'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 이용약관 페이지로 이동
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진행 상황 초기화'),
        content: const Text(
          '정말로 모든 게임 진행 상황을 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 진행 상황 초기화 로직
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('진행 상황이 초기화되었습니다')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  void _showCacheClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('다운로드된 게임팩 캐시를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 캐시 삭제 로직
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('캐시가 삭제되었습니다')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
