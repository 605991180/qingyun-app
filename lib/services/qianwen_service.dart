import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/contact.dart';
import '../models/contact_resource.dart';
import '../models/ai_config.dart';
import 'ai_parser_service.dart';

/// 通义千问云端API服务
class QianwenService {
  static const String _apiKeyKey = 'qianwen_api_key';
  static const String _privacyConsentKey = 'ai_privacy_consent';
  static const String _apiUrl = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static const int _maxRetries = 3;
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  /// 保存API Key（加密存储）
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }
  
  /// 获取API Key
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }
  
  /// 检查是否已配置API Key
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
  
  /// 删除API Key
  static Future<void> removeApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }
  
  /// 检查用户是否已同意隐私条款
  static Future<bool> hasPrivacyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyConsentKey) ?? false;
  }
  
  /// 设置用户隐私同意状态
  static Future<void> setPrivacyConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyConsentKey, consent);
  }

  /// 获取当前使用的模型名称
  static Future<String> _getModelName() async {
    final activeConfig = await AIConfigService.getActiveConfig();
    if (activeConfig != null && activeConfig.provider == AIProvider.qianwen) {
      return activeConfig.model ?? 'qwen-plus';
    }
    return 'qwen-plus'; // 默认使用qwen-plus
  }
  
  /// 使用通义千问分析日记内容
  static Future<DiaryAnalysisResult> analyzeDiary(String content, List<Contact> contacts) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return AIParserService.analyzeDiary(content, contacts);
    }
    
    // 检查隐私同意
    final hasConsent = await hasPrivacyConsent();
    if (!hasConsent) {
      return AIParserService.analyzeDiary(content, contacts);
    }
    
    // 带重试的API调用
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final contactNames = contacts.map((c) => c.name).toList();
        final prompt = _buildAnalysisPrompt(content, contactNames);
        final modelName = await _getModelName();
        
        final client = http.Client();
        try {
          final response = await client.post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': modelName,
              'input': {
                'messages': [
                  {
                    'role': 'system',
                    'content': '你是一个日记分析助手，帮助用户从日记中提取人际关系和互动信息。请严格按照JSON格式返回结果，不要添加任何额外说明。'
                  },
                  {
                    'role': 'user',
                    'content': prompt
                  }
                ]
              },
              'parameters': {
                'result_format': 'message',
                'temperature': 0.3,
              }
            }),
          ).timeout(const Duration(seconds: 30));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            String text = '';
            if (data['output'] != null) {
              if (data['output']['choices'] != null && 
                  (data['output']['choices'] as List).isNotEmpty) {
                text = data['output']['choices'][0]['message']?['content'] ?? '';
              } else if (data['output']['text'] != null) {
                text = data['output']['text'];
              }
            }
            return _parseResponse(text, contacts);
          } else if (response.statusCode >= 500 && attempt < _maxRetries) {
            // 服务器错误，等待后重试
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          } else {
            // 其他错误或最后一次尝试失败，降级到本地
            return AIParserService.analyzeDiary(content, contacts);
          }
        } finally {
          client.close();
        }
      } on http.ClientException catch (_) {
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return AIParserService.analyzeDiary(content, contacts);
      } catch (e) {
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return AIParserService.analyzeDiary(content, contacts);
      }
    }
    
    return AIParserService.analyzeDiary(content, contacts);
  }
  
  /// 构建分析提示词
  static String _buildAnalysisPrompt(String diaryContent, List<String> contactNames) {
    return '''
分析以下日记内容，提取人际关系信息。注意：书名号《》中的内容是书名/作品名，不是人名。

重要：如果同一个联系人在日记中被多次提及，请合并为一条互动记录，描述中包含所有互动内容，热度增益累加。

已有联系人列表：${contactNames.isEmpty ? '无' : contactNames.join('、')}

日记内容：
$diaryContent

请返回JSON格式的分析结果：
{
  "interactions": [
    {
      "contactName": "联系人姓名",
      "type": "最主要的互动类型",
      "heatGain": 累计热度增益数值,
      "description": "合并后的互动描述"
    }
  ],
  "newContacts": ["新认识的人名"],
  "resources": [
    {
      "contactName": "联系人姓名",
      "category": "资源类别(political/business/social/convenience/knowledge/emotional)",
      "description": "资源描述"
    }
  ],
  "mood": "情绪(happy/sad/angry/tired/excited/anxious/grateful/calm)"
}

互动类型说明（正面）：
- gift: 送礼、请客 (+10)
- meetup: 线下见面、聚餐 (+15)
- help: 帮忙、协助 (+8)
- deepTalk: 深度交流、谈心 (+10)
- theyInitiated: 对方主动联系 (+5)
- paidTransaction: 付费交易 (+5)
- normal: 日常互动 (+3)

互动类型说明（负面）：
- conflict: 争吵、冲突、吵架 (-5)
- coldWar: 冷战、互不理睬 (-3)
- betrayal: 背叛、欺骗 (-15)
- neglect: 疏远、失联、很久不联系 (-2)

请只返回JSON，不要添加任何其他文字。每个联系人只返回一条合并后的互动记录。
''';
  }
  
  /// 解析API响应
  static DiaryAnalysisResult _parseResponse(String responseText, List<Contact> contacts) {
    final result = DiaryAnalysisResult();
    
    try {
      // 提取JSON部分
      String jsonStr = responseText;
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      
      final data = jsonDecode(jsonStr);
      
      // 解析互动
      if (data['interactions'] != null) {
        for (var item in data['interactions']) {
          final analysis = InteractionAnalysis(
            contactName: item['contactName'] ?? '',
          );
          analysis.type = _parseInteractionType(item['type']);
          analysis.heatGain = (item['heatGain'] ?? 3.0).toDouble();
          analysis.description = item['description'] ?? '';
          
          if (analysis.contactName.isNotEmpty) {
            result.interactions.add(analysis);
          }
        }
      }
      
      // 解析新联系人
      if (data['newContacts'] != null) {
        for (var name in data['newContacts']) {
          if (name != null && name.toString().isNotEmpty) {
            result.newContacts.add(name.toString());
          }
        }
      }
      
      // 解析资源
      if (data['resources'] != null) {
        for (var item in data['resources']) {
          final contactName = item['contactName'] ?? '';
          final contact = contacts.firstWhere(
            (c) => c.name == contactName,
            orElse: () => Contact(id: '', name: ''),
          );
          
          if (contact.id.isNotEmpty) {
            final resource = ContactResource(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              contactId: contact.id,
              contactName: contactName,
              category: _parseResourceCategory(item['category']),
              description: item['description'] ?? '',
            );
            result.resources.add(resource);
          }
        }
      }
      
      // 解析情绪
      result.mood = data['mood'];
      
    } catch (e) {
      // JSON解析失败，返回空结果
    }
    
    return result;
  }
  
  static InteractionType _parseInteractionType(String? type) {
    switch (type) {
      case 'gift': return InteractionType.gift;
      case 'meetup': return InteractionType.meetup;
      case 'help': return InteractionType.help;
      case 'deepTalk': return InteractionType.deepTalk;
      case 'theyInitiated': return InteractionType.theyInitiated;
      case 'paidTransaction': return InteractionType.paidTransaction;
      // 负面互动
      case 'conflict': return InteractionType.conflict;
      case 'coldWar': return InteractionType.coldWar;
      case 'betrayal': return InteractionType.betrayal;
      case 'neglect': return InteractionType.neglect;
      default: return InteractionType.normal;
    }
  }
  
  static ResourceCategory _parseResourceCategory(String? category) {
    switch (category) {
      case 'political': return ResourceCategory.political;
      case 'business': return ResourceCategory.business;
      case 'social': return ResourceCategory.social;
      case 'convenience': return ResourceCategory.convenience;
      case 'knowledge': return ResourceCategory.knowledge;
      case 'emotional': return ResourceCategory.emotional;
      default: return ResourceCategory.social;
    }
  }
  
  /// 测试API连接
  static Future<bool> testConnection() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return false;
    
    final client = http.Client();
    try {
      final modelName = await _getModelName();
      final response = await client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelName,
          'input': {
            'messages': [
              {'role': 'user', 'content': '你好'}
            ]
          },
        }),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  /// 测试API连接（带详细错误信息）
  static Future<String> testConnectionWithDetails() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '未配置API Key';
    }
    
    final client = http.Client();
    try {
      final modelName = await _getModelName();
      final response = await client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelName,
          'input': {
            'messages': [
              {'role': 'user', 'content': '你好'}
            ]
          },
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return '连接成功！模型: $modelName';
      } else {
        final data = jsonDecode(response.body);
        final errorMsg = data['message'] ?? data['error']?['message'] ?? '未知错误';
        return '错误 ${response.statusCode}: $errorMsg';
      }
    } catch (e) {
      return '网络错误: $e';
    } finally {
      client.close();
    }
  }
}
