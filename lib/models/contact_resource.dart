/// 人脉资源模型 - 用于记录联系人可提供的各类资源
class ContactResource {
  final String id;
  final String contactId;
  final String contactName;
  final ResourceCategory category;
  final String description;
  final String? source; // 来源（日记ID或手动添加）
  final DateTime createdAt;

  ContactResource({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.category,
    required this.description,
    this.source,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'contactName': contactName,
        'category': category.index,
        'description': description,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ContactResource.fromJson(Map<String, dynamic> json) => ContactResource(
        id: json['id'],
        contactId: json['contactId'],
        contactName: json['contactName'],
        category: ResourceCategory.values[json['category'] ?? 0],
        description: json['description'],
        source: json['source'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

/// 资源类别枚举
enum ResourceCategory {
  political,   // 政治关系
  business,    // 商业资源
  social,      // 社会资源
  convenience, // 便利条件
  knowledge,   // 知识/技能
  emotional,   // 情感支持
}

/// 资源类别工具类
class ResourceCategoryHelper {
  static String getLabel(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.political:
        return '政治关系';
      case ResourceCategory.business:
        return '商业资源';
      case ResourceCategory.social:
        return '社会资源';
      case ResourceCategory.convenience:
        return '便利条件';
      case ResourceCategory.knowledge:
        return '知识技能';
      case ResourceCategory.emotional:
        return '情感支持';
    }
  }

  static String getIcon(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.political:
        return '🏛️';
      case ResourceCategory.business:
        return '💼';
      case ResourceCategory.social:
        return '🤝';
      case ResourceCategory.convenience:
        return '🔑';
      case ResourceCategory.knowledge:
        return '📚';
      case ResourceCategory.emotional:
        return '❤️';
    }
  }

  static int getColor(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.political:
        return 0xFFE53935; // 红色
      case ResourceCategory.business:
        return 0xFFFF9800; // 橙色
      case ResourceCategory.social:
        return 0xFF4CAF50; // 绿色
      case ResourceCategory.convenience:
        return 0xFF2196F3; // 蓝色
      case ResourceCategory.knowledge:
        return 0xFF9C27B0; // 紫色
      case ResourceCategory.emotional:
        return 0xFFE91E63; // 粉色
    }
  }

  /// 根据关键词推断资源类别
  static ResourceCategory? inferCategory(String text) {
    final lowerText = text.toLowerCase();
    
    // 政治关系关键词
    if (_containsAny(lowerText, ['政府', '官员', '领导', '书记', '市长', '局长', '处长', '科长', '主任', '部长', '政协', '人大', '党委', '纪委', '组织部', '宣传部'])) {
      return ResourceCategory.political;
    }
    
    // 商业资源关键词
    if (_containsAny(lowerText, ['老板', '董事', '总经理', '经理', '公司', '企业', '生意', '投资', '融资', '合作', '项目', '商业', '客户', '供应商', '代理'])) {
      return ResourceCategory.business;
    }
    
    // 社会资源关键词
    if (_containsAny(lowerText, ['朋友', '同学', '校友', '老乡', '战友', '邻居', '亲戚', '介绍', '认识', '人脉', '圈子', '协会', '商会'])) {
      return ResourceCategory.social;
    }
    
    // 便利条件关键词
    if (_containsAny(lowerText, ['医院', '学校', '银行', '房产', '车', '票', '号', '优惠', '折扣', '内部', '渠道', '办事', '手续', '审批'])) {
      return ResourceCategory.convenience;
    }
    
    // 知识技能关键词
    if (_containsAny(lowerText, ['专家', '教授', '博士', '技术', '专业', '顾问', '律师', '医生', '会计', '设计', '开发', '咨询'])) {
      return ResourceCategory.knowledge;
    }
    
    // 情感支持关键词
    if (_containsAny(lowerText, ['倾诉', '安慰', '支持', '鼓励', '陪伴', '理解', '信任', '知己', '闺蜜', '兄弟'])) {
      return ResourceCategory.emotional;
    }
    
    return null;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}
