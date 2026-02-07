/// 联系人模型
class Contact {
  final String id;
  String name;
  String? avatar;
  double heat; // 热度值，范围0-200%，初识0-1%，挚友>150%
  DateTime lastInteraction;
  DateTime createdAt;
  List<Interaction> interactions;
  List<Resource> resources; // 资源消耗记录
  RelationType? relationType; // 关系类型标签

  Contact({
    required this.id,
    required this.name,
    this.avatar,
    this.heat = 1.0, // 初识陌生人默认1%
    DateTime? lastInteraction,
    DateTime? createdAt,
    List<Interaction>? interactions,
    List<Resource>? resources,
    this.relationType,
  })  : lastInteraction = lastInteraction ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        interactions = interactions ?? [],
        resources = resources ?? [];

  /// 获取总资源消耗
  double get totalResourceCost {
    return resources.fold(0.0, (sum, r) => sum + r.cost);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'heat': heat,
        'lastInteraction': lastInteraction.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'resources': resources.map((r) => r.toJson()).toList(),
        'relationType': relationType?.index,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'],
        name: json['name'],
        avatar: json['avatar'],
        heat: (json['heat'] as num).toDouble(),
        lastInteraction: DateTime.parse(json['lastInteraction']),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        interactions: (json['interactions'] as List?)
                ?.map((i) => Interaction.fromJson(i))
                .toList() ??
            [],
        resources: (json['resources'] as List?)
                ?.map((r) => Resource.fromJson(r))
                .toList() ??
            [],
        relationType: json['relationType'] != null 
            ? RelationType.values[json['relationType']] 
            : null,
      );
}

/// 关系类型枚举
enum RelationType {
  family,      // 家人
  friend,      // 朋友
  colleague,   // 同事
  classmate,   // 同学
  business,    // 生意伙伴
  neighbor,    // 邻居
  mentor,      // 导师/前辈
  lover,       // 恋人
  acquaintance,// 熟人
  other,       // 其他
}

/// 关系类型扩展
extension RelationTypeExtension on RelationType {
  String get label {
    switch (this) {
      case RelationType.family: return '家人';
      case RelationType.friend: return '朋友';
      case RelationType.colleague: return '同事';
      case RelationType.classmate: return '同学';
      case RelationType.business: return '生意伙伴';
      case RelationType.neighbor: return '邻居';
      case RelationType.mentor: return '导师';
      case RelationType.lover: return '恋人';
      case RelationType.acquaintance: return '熟人';
      case RelationType.other: return '其他';
    }
  }

  String get emoji {
    switch (this) {
      case RelationType.family: return '👨‍👩‍👧';
      case RelationType.friend: return '🤝';
      case RelationType.colleague: return '💼';
      case RelationType.classmate: return '🎓';
      case RelationType.business: return '🤵';
      case RelationType.neighbor: return '🏠';
      case RelationType.mentor: return '👨‍🏫';
      case RelationType.lover: return '❤️';
      case RelationType.acquaintance: return '👋';
      case RelationType.other: return '📌';
    }
  }

  int get color {
    switch (this) {
      case RelationType.family: return 0xFFE91E63;
      case RelationType.friend: return 0xFF4CAF50;
      case RelationType.colleague: return 0xFF2196F3;
      case RelationType.classmate: return 0xFF9C27B0;
      case RelationType.business: return 0xFFFF9800;
      case RelationType.neighbor: return 0xFF795548;
      case RelationType.mentor: return 0xFF607D8B;
      case RelationType.lover: return 0xFFF44336;
      case RelationType.acquaintance: return 0xFF9E9E9E;
      case RelationType.other: return 0xFF455A64;
    }
  }
}

/// 互动类型枚举
enum InteractionType {
  // 正面互动
  normal, // 普通互动
  paidTransaction, // 付费交易（限+5%）
  theyInitiated, // 对方主动联系（+5%）
  deepTalk, // 深度交流（+10%）
  meetup, // 线下见面（+15%）
  help, // 帮助对方（+8%）
  gift, // 送礼物（+10%）
  // 负面互动
  conflict, // 争吵/冲突（-5%）
  coldWar, // 冷战（-3%）
  betrayal, // 背叛（-15%）
  neglect, // 忽视/疏远（-2%）
}

/// 互动记录
class Interaction {
  final String id;
  final DateTime time;
  final String content;
  final InteractionType type;
  final double heatGain; // 此次互动增加的热度

  Interaction({
    required this.id,
    required this.time,
    required this.content,
    this.type = InteractionType.normal,
    double? heatGain,
  }) : heatGain = heatGain ?? _getDefaultHeatGain(type);

  static double _getDefaultHeatGain(InteractionType type) {
    switch (type) {
      case InteractionType.paidTransaction:
        return 5.0; // 付费交易限+5%
      case InteractionType.theyInitiated:
        return 5.0; // 对方主动+5%
      case InteractionType.deepTalk:
        return 10.0;
      case InteractionType.meetup:
        return 15.0;
      case InteractionType.help:
        return 8.0;
      case InteractionType.gift:
        return 10.0;
      case InteractionType.normal:
        return 3.0;
      // 负面互动
      case InteractionType.conflict:
        return -5.0; // 争吵冲突-5%
      case InteractionType.coldWar:
        return -3.0; // 冷战-3%
      case InteractionType.betrayal:
        return -15.0; // 背叛-15%
      case InteractionType.neglect:
        return -2.0; // 忽视疏远-2%
    }
  }

  String get typeLabel {
    switch (type) {
      case InteractionType.paidTransaction:
        return '付费交易';
      case InteractionType.theyInitiated:
        return '对方主动';
      case InteractionType.deepTalk:
        return '深度交流';
      case InteractionType.meetup:
        return '线下见面';
      case InteractionType.help:
        return '帮助TA';
      case InteractionType.gift:
        return '送礼物';
      case InteractionType.normal:
        return '日常互动';
      // 负面互动
      case InteractionType.conflict:
        return '争吵冲突';
      case InteractionType.coldWar:
        return '冷战';
      case InteractionType.betrayal:
        return '背叛';
      case InteractionType.neglect:
        return '疏远';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'content': content,
        'type': type.index,
        'heatGain': heatGain,
      };

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'],
        time: DateTime.parse(json['time']),
        content: json['content'],
        type: InteractionType.values[json['type'] ?? 0],
        heatGain: (json['heatGain'] as num?)?.toDouble(),
      );
}

/// 资源消耗类型
enum ResourceType {
  money, // 金钱
  time, // 时间
  energy, // 精力
  favor, // 人情
}

/// 资源消耗记录
class Resource {
  final String id;
  final DateTime time;
  final ResourceType type;
  final String description;
  final double amount; // 数量
  final double cost; // 折算成热度消耗（负值）

  Resource({
    required this.id,
    required this.time,
    required this.type,
    required this.description,
    required this.amount,
    double? cost,
  }) : cost = cost ?? _calculateCost(type, amount);

  static double _calculateCost(ResourceType type, double amount) {
    // 资源消耗折算热度：消耗越大，热度收益越少
    switch (type) {
      case ResourceType.money:
        return amount * 0.01; // 每100元消耗1%热度
      case ResourceType.time:
        return amount * 0.5; // 每小时消耗0.5%热度
      case ResourceType.energy:
        return amount * 1.0; // 高精力消耗
      case ResourceType.favor:
        return amount * 2.0; // 人情消耗最大
    }
  }

  String get typeLabel {
    switch (type) {
      case ResourceType.money:
        return '金钱';
      case ResourceType.time:
        return '时间';
      case ResourceType.energy:
        return '精力';
      case ResourceType.favor:
        return '人情';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'type': type.index,
        'description': description,
        'amount': amount,
        'cost': cost,
      };

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
        id: json['id'],
        time: DateTime.parse(json['time']),
        type: ResourceType.values[json['type'] ?? 0],
        description: json['description'] ?? '',
        amount: (json['amount'] as num).toDouble(),
        cost: (json['cost'] as num?)?.toDouble(),
      );
}
