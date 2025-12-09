import 'package:equatable/equatable.dart';

/// 사용자 프로필
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String? characterId;
  final int age;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarPath,
    this.characterId,
    this.age = 5,
    required this.createdAt,
    this.lastActiveAt,
  });

  bool get hasCharacter => characterId != null;

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? characterId,
    int? age,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      characterId: characterId ?? this.characterId,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatar_path'] as String?,
      characterId: json['character_id'] as String?,
      age: json['age'] as int? ?? 5,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_path': avatarPath,
        'character_id': characterId,
        'age': age,
        'created_at': createdAt.toIso8601String(),
        'last_active_at': lastActiveAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, avatarPath, characterId, age, createdAt, lastActiveAt];
}

/// AI 캐릭터 (사용자가 만든 캐릭터)
class UserCharacter extends Equatable {
  final String id;
  final String name;
  final String imagePath;
  final String? voiceId;
  final List<String> greetings;
  final DateTime createdAt;

  const UserCharacter({
    required this.id,
    required this.name,
    required this.imagePath,
    this.voiceId,
    this.greetings = const [],
    required this.createdAt,
  });

  String getRandomGreeting(String userName) {
    if (greetings.isEmpty) {
      return '안녕 $userName! 오늘도 같이 놀자!';
    }
    final index = DateTime.now().millisecond % greetings.length;
    return greetings[index].replaceAll('{name}', userName);
  }

  factory UserCharacter.fromJson(Map<String, dynamic> json) {
    return UserCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['image_path'] as String,
      voiceId: json['voice_id'] as String?,
      greetings: List<String>.from(json['greetings'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_path': imagePath,
        'voice_id': voiceId,
        'greetings': greetings,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, imagePath, voiceId, greetings, createdAt];
}
