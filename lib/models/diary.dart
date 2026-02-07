/// 日记模型
class Diary {
  final String id;
  DateTime date;
  String content;
  String? mood; // 心情标签
  List<String> mentionedContactIds; // 提到的联系人ID
  DateTime createdAt;
  DateTime updatedAt;

  Diary({
    required this.id,
    required this.date,
    required this.content,
    this.mood,
    List<String>? mentionedContactIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : mentionedContactIds = mentionedContactIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'content': content,
        'mood': mood,
        'mentionedContactIds': mentionedContactIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Diary.fromJson(Map<String, dynamic> json) => Diary(
        id: json['id'],
        date: DateTime.parse(json['date']),
        content: json['content'],
        mood: json['mood'],
        mentionedContactIds: (json['mentionedContactIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
}

/// 心情类型
class MoodType {
  static const String happy = '开心';
  static const String calm = '平静';
  static const String tired = '疲惫';
  static const String sad = '难过';
  static const String angry = '生气';
  static const String excited = '兴奋';
  static const String anxious = '焦虑';
  static const String grateful = '感恩';

  static List<String> all = [happy, calm, tired, sad, angry, excited, anxious, grateful];

  static String getEmoji(String mood) {
    switch (mood) {
      case happy: return '😊';
      case calm: return '😌';
      case tired: return '😫';
      case sad: return '😢';
      case angry: return '😠';
      case excited: return '🤩';
      case anxious: return '😰';
      case grateful: return '🙏';
      default: return '📝';
    }
  }

  static int getColor(String mood) {
    switch (mood) {
      case happy: return 0xFFFFD700;
      case calm: return 0xFF4CAF50;
      case tired: return 0xFF9E9E9E;
      case sad: return 0xFF2196F3;
      case angry: return 0xFFF44336;
      case excited: return 0xFFFF9800;
      case anxious: return 0xFF9C27B0;
      case grateful: return 0xFFE91E63;
      default: return 0xFF607D8B;
    }
  }
}
