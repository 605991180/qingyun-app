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

  Contact({
    required this.id,
    required this.name,
    this.avatar,
    this.heat = 1.0, // 初识陌生人默认1%
    DateTime? lastInteraction,
    DateTime? createdAt,
    List<Interaction>? interactions,
    List<Resource>? resources,
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
      );
}

/// 互动类型枚举
enum InteractionType {
  normal, // 普通互动
  paidTransaction, // 付费交易（限+5%）
  theyInitiated, // 对方主动联系（+5%）
  deepTalk, // 深度交流（+10%）
  meetup, // 线下见面（+15%）
  help, // 帮助对方（+8%）
  gift, // 送礼物（+10%）
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
