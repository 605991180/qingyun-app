import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 职业大类枚举
enum OccupationCategory {
  shi,    // 仕 - 政治领域
  nong,   // 农 - 人民百姓
  gong,   // 工 - 手艺人
  shang,  // 商 - 商业行业
}

/// 政治级别枚举
enum PoliticalLevel {
  province,  // 省级
  city,      // 市级
  county,    // 县级
}

/// 职业分类信息助手
class OccupationHelper {
  static String getName(OccupationCategory category) {
    switch (category) {
      case OccupationCategory.shi:
        return '仕';
      case OccupationCategory.nong:
        return '农';
      case OccupationCategory.gong:
        return '工';
      case OccupationCategory.shang:
        return '商';
    }
  }

  static String getFullName(OccupationCategory category) {
    switch (category) {
      case OccupationCategory.shi:
        return '仕（政治领域）';
      case OccupationCategory.nong:
        return '农（人民百姓）';
      case OccupationCategory.gong:
        return '工（手艺人）';
      case OccupationCategory.shang:
        return '商（商业行业）';
    }
  }

  static String getDescription(OccupationCategory category) {
    switch (category) {
      case OccupationCategory.shi:
        return '政府机关、公务员、事业单位';
      case OccupationCategory.nong:
        return '普通群众、自由职业';
      case OccupationCategory.gong:
        return '技术工人、手艺匠人';
      case OccupationCategory.shang:
        return '各行各业商业从业者';
    }
  }

  static String getIcon(OccupationCategory category) {
    switch (category) {
      case OccupationCategory.shi:
        return '🏛️';
      case OccupationCategory.nong:
        return '🌾';
      case OccupationCategory.gong:
        return '🔧';
      case OccupationCategory.shang:
        return '💼';
    }
  }

  static int getColor(OccupationCategory category) {
    switch (category) {
      case OccupationCategory.shi:
        return 0xFFE53935; // 红色
      case OccupationCategory.nong:
        return 0xFF43A047; // 绿色
      case OccupationCategory.gong:
        return 0xFFFB8C00; // 橙色
      case OccupationCategory.shang:
        return 0xFF1E88E5; // 蓝色
    }
  }

  static String getLevelName(PoliticalLevel level) {
    switch (level) {
      case PoliticalLevel.province:
        return '省级';
      case PoliticalLevel.city:
        return '市级';
      case PoliticalLevel.county:
        return '县级';
    }
  }
}

/// 自定义部门/行业分类
class CustomCategory {
  final String id;
  final String name;
  final OccupationCategory occupation;
  final PoliticalLevel? politicalLevel; // 仅用于"仕"类
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.name,
    required this.occupation,
    this.politicalLevel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'occupation': occupation.index,
    'politicalLevel': politicalLevel?.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomCategory.fromJson(Map<String, dynamic> json) => CustomCategory(
    id: json['id'],
    name: json['name'],
    occupation: OccupationCategory.values[json['occupation']],
    politicalLevel: json['politicalLevel'] != null 
        ? PoliticalLevel.values[json['politicalLevel']] 
        : null,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// 联系人职业信息
class ContactOccupation {
  final String contactId;
  final OccupationCategory category;
  final String? customCategoryId; // 关联的自定义分类ID
  final String? detail; // 详细描述

  ContactOccupation({
    required this.contactId,
    required this.category,
    this.customCategoryId,
    this.detail,
  });

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'category': category.index,
    'customCategoryId': customCategoryId,
    'detail': detail,
  };

  factory ContactOccupation.fromJson(Map<String, dynamic> json) => ContactOccupation(
    contactId: json['contactId'],
    category: OccupationCategory.values[json['category']],
    customCategoryId: json['customCategoryId'],
    detail: json['detail'],
  );
}

/// 职业分类服务
class OccupationService {
  static const String _categoriesKey = 'custom_categories_v1';
  static const String _occupationsKey = 'contact_occupations_v1';

  // 默认的部门分类（仕）
  static List<CustomCategory> getDefaultShiCategories() {
    return [
      // 省级
      CustomCategory(id: 'shi_p_1', name: '省委办公厅', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.province),
      CustomCategory(id: 'shi_p_2', name: '省政府办公厅', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.province),
      CustomCategory(id: 'shi_p_3', name: '省发改委', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.province),
      CustomCategory(id: 'shi_p_4', name: '省财政厅', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.province),
      CustomCategory(id: 'shi_p_5', name: '省教育厅', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.province),
      // 市级
      CustomCategory(id: 'shi_c_1', name: '市委办公室', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.city),
      CustomCategory(id: 'shi_c_2', name: '市政府办公室', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.city),
      CustomCategory(id: 'shi_c_3', name: '市发改委', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.city),
      CustomCategory(id: 'shi_c_4', name: '市财政局', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.city),
      CustomCategory(id: 'shi_c_5', name: '市教育局', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.city),
      // 县级
      CustomCategory(id: 'shi_x_1', name: '县委办公室', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.county),
      CustomCategory(id: 'shi_x_2', name: '县政府办公室', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.county),
      CustomCategory(id: 'shi_x_3', name: '县发改局', occupation: OccupationCategory.shi, politicalLevel: PoliticalLevel.county),
    ];
  }

  // 默认的行业分类（商）
  static List<CustomCategory> getDefaultShangCategories() {
    return [
      CustomCategory(id: 'shang_1', name: '金融银行', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_2', name: '房地产', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_3', name: '医疗健康', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_4', name: '教育培训', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_5', name: '餐饮服务', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_6', name: '零售批发', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_7', name: '互联网科技', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_8', name: '建筑工程', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_9', name: '物流运输', occupation: OccupationCategory.shang),
      CustomCategory(id: 'shang_10', name: '法律服务', occupation: OccupationCategory.shang),
    ];
  }

  // 默认的工种分类（工）
  static List<CustomCategory> getDefaultGongCategories() {
    return [
      CustomCategory(id: 'gong_1', name: '电工', occupation: OccupationCategory.gong),
      CustomCategory(id: 'gong_2', name: '水暖工', occupation: OccupationCategory.gong),
      CustomCategory(id: 'gong_3', name: '木工', occupation: OccupationCategory.gong),
      CustomCategory(id: 'gong_4', name: '瓦工', occupation: OccupationCategory.gong),
      CustomCategory(id: 'gong_5', name: '汽修工', occupation: OccupationCategory.gong),
      CustomCategory(id: 'gong_6', name: '厨师', occupation: OccupationCategory.gong),
    ];
  }

  /// 加载所有自定义分类
  static Future<List<CustomCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      // 首次使用，初始化默认分类
      final defaults = [
        ...getDefaultShiCategories(),
        ...getDefaultShangCategories(),
        ...getDefaultGongCategories(),
      ];
      await saveCategories(defaults);
      return defaults;
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CustomCategory.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存分类
  static Future<void> saveCategories(List<CustomCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesKey, jsonString);
  }

  /// 添加分类
  static Future<void> addCategory(CustomCategory category) async {
    final categories = await loadCategories();
    categories.add(category);
    await saveCategories(categories);
  }

  /// 删除分类
  static Future<void> deleteCategory(String id) async {
    final categories = await loadCategories();
    categories.removeWhere((c) => c.id == id);
    await saveCategories(categories);
  }

  /// 按职业大类获取分类
  static Future<List<CustomCategory>> getCategoriesByOccupation(OccupationCategory occupation) async {
    final categories = await loadCategories();
    return categories.where((c) => c.occupation == occupation).toList();
  }

  /// 加载联系人职业信息
  static Future<List<ContactOccupation>> loadOccupations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_occupationsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ContactOccupation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存联系人职业信息
  static Future<void> saveOccupations(List<ContactOccupation> occupations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(occupations.map((o) => o.toJson()).toList());
    await prefs.setString(_occupationsKey, jsonString);
  }

  /// 设置联系人职业
  static Future<void> setContactOccupation(ContactOccupation occupation) async {
    final occupations = await loadOccupations();
    final index = occupations.indexWhere((o) => o.contactId == occupation.contactId);
    if (index != -1) {
      occupations[index] = occupation;
    } else {
      occupations.add(occupation);
    }
    await saveOccupations(occupations);
  }

  /// 获取联系人职业
  static Future<ContactOccupation?> getContactOccupation(String contactId) async {
    final occupations = await loadOccupations();
    try {
      return occupations.firstWhere((o) => o.contactId == contactId);
    } catch (e) {
      return null;
    }
  }

  /// 按职业大类统计联系人数量
  static Future<Map<OccupationCategory, int>> getOccupationStats() async {
    final occupations = await loadOccupations();
    final stats = <OccupationCategory, int>{};
    for (var cat in OccupationCategory.values) {
      stats[cat] = occupations.where((o) => o.category == cat).length;
    }
    return stats;
  }

  /// 获取某职业大类下的所有联系人ID
  static Future<List<String>> getContactIdsByOccupation(OccupationCategory category) async {
    final occupations = await loadOccupations();
    return occupations.where((o) => o.category == category).map((o) => o.contactId).toList();
  }
}
