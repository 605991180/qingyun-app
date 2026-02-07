import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// AI模型提供商枚举
enum AIProvider {
  qianwen,    // 通义千问
  wenxin,     // 文心一言
  deepseek,   // DeepSeek
  openai,     // OpenAI
}

/// AI模型配置
class AIModelConfig {
  final String id;
  final AIProvider provider;
  final String name;
  final String apiKey;
  final String? baseUrl;
  final String? model;
  final bool isActive;
  final DateTime createdAt;

  AIModelConfig({
    required this.id,
    required this.provider,
    required this.name,
    required this.apiKey,
    this.baseUrl,
    this.model,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.index,
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AIModelConfig.fromJson(Map<String, dynamic> json) => AIModelConfig(
    id: json['id'],
    provider: AIProvider.values[json['provider']],
    name: json['name'],
    apiKey: json['apiKey'],
    baseUrl: json['baseUrl'],
    model: json['model'],
    isActive: json['isActive'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );

  AIModelConfig copyWith({
    String? id,
    AIProvider? provider,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? isActive,
  }) => AIModelConfig(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    name: name ?? this.name,
    apiKey: apiKey ?? this.apiKey,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}

/// AI模型提供商信息
class AIProviderInfo {
  static String getName(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return '通义千问';
      case AIProvider.wenxin:
        return '文心一言';
      case AIProvider.deepseek:
        return 'DeepSeek';
      case AIProvider.openai:
        return 'OpenAI';
    }
  }

  static String getDescription(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return '阿里云大模型，中文理解强';
      case AIProvider.wenxin:
        return '百度大模型，企业级服务';
      case AIProvider.deepseek:
        return '高性价比，推理能力强';
      case AIProvider.openai:
        return 'GPT系列，全球领先';
    }
  }

  static String getDefaultUrl(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
      case AIProvider.wenxin:
        return 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions';
      case AIProvider.deepseek:
        return 'https://api.deepseek.com/v1/chat/completions';
      case AIProvider.openai:
        return 'https://api.openai.com/v1/chat/completions';
    }
  }

  static String getDefaultModel(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return 'qwen-turbo';
      case AIProvider.wenxin:
        return 'ernie-speed-128k';
      case AIProvider.deepseek:
        return 'deepseek-chat';
      case AIProvider.openai:
        return 'gpt-3.5-turbo';
    }
  }

  static List<String> getAvailableModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return ['qwen-turbo', 'qwen-plus', 'qwen-max'];
      case AIProvider.wenxin:
        return ['ernie-speed-128k', 'ernie-lite-8k', 'ernie-4.0-8k'];
      case AIProvider.deepseek:
        return ['deepseek-chat', 'deepseek-coder'];
      case AIProvider.openai:
        return ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'];
    }
  }

  static int getColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return 0xFF6366F1; // 紫色
      case AIProvider.wenxin:
        return 0xFF3B82F6; // 蓝色
      case AIProvider.deepseek:
        return 0xFF10B981; // 绿色
      case AIProvider.openai:
        return 0xFF8B5CF6; // 紫罗兰
    }
  }

  static String getIcon(AIProvider provider) {
    switch (provider) {
      case AIProvider.qianwen:
        return '🌐';
      case AIProvider.wenxin:
        return '🔵';
      case AIProvider.deepseek:
        return '🌊';
      case AIProvider.openai:
        return '🤖';
    }
  }
}

/// AI配置管理服务
class AIConfigService {
  static const String _configsKey = 'ai_model_configs_v1';
  static const String _activeIdKey = 'ai_active_model_id';

  /// 加载所有配置
  static Future<List<AIModelConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AIModelConfig.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有配置
  static Future<void> saveConfigs(List<AIModelConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_configsKey, jsonString);
  }

  /// 添加配置
  static Future<void> addConfig(AIModelConfig config) async {
    final configs = await loadConfigs();
    configs.add(config);
    await saveConfigs(configs);
  }

  /// 更新配置
  static Future<void> updateConfig(AIModelConfig config) async {
    final configs = await loadConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      configs[index] = config;
    }
    await saveConfigs(configs);
  }

  /// 删除配置
  static Future<void> deleteConfig(String id) async {
    final configs = await loadConfigs();
    configs.removeWhere((c) => c.id == id);
    await saveConfigs(configs);
  }

  /// 设置活跃模型
  static Future<void> setActiveModel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, id);
    
    // 更新配置列表中的isActive状态
    final configs = await loadConfigs();
    final updatedConfigs = configs.map((c) => c.copyWith(isActive: c.id == id)).toList();
    await saveConfigs(updatedConfigs);
  }

  /// 获取活跃模型ID
  static Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeIdKey);
  }

  /// 获取活跃模型配置
  static Future<AIModelConfig?> getActiveConfig() async {
    final activeId = await getActiveModelId();
    if (activeId == null) return null;
    
    final configs = await loadConfigs();
    try {
      return configs.firstWhere((c) => c.id == activeId);
    } catch (e) {
      return null;
    }
  }

  /// 检查是否有配置
  static Future<bool> hasConfig() async {
    final configs = await loadConfigs();
    return configs.isNotEmpty;
  }
}
