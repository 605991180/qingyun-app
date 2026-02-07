import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/contact_resource.dart';
import '../models/ai_config.dart';
import 'ai_parser_service.dart';

/// 通义千问云端API服务
class QianwenService {
  static const String _apiKeyKey = 'qianwen_api_key';
  static const String _apiUrl = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  
  /// 保存API Key
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }
  
  /// 获取API Key
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }
  
  /// 检查是否已配置API Key
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
  
  /// 删除API Key
  static Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
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
    
    try {
      final contactNames = contacts.map((c) => c.name).toList();
      final prompt = _buildAnalysisPrompt(content, contactNames);
      final modelName = await _getModelName();
      
      final response = await http.post(
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
        // 正确的响应路径：output.choices[0].message.content 或 output.text
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
      } else {
        return AIParserService.analyzeDiary(content, contacts);
      }
    } catch (e) {
      return AIParserService.analyzeDiary(content, contacts);
    }
  }
  
  /// 构建分析提示词
  static String _buildAnalysisPrompt(String diaryContent, List<String> contactNames) {
    return '''
分析以下日记内容，提取人际关系信息。

已有联系人列表：${contactNames.isEmpty ? '无' : contactNames.join('、')}

日记内容：
$diaryContent

请返回JSON格式的分析结果：
{
  "interactions": [
    {
      "contactName": "联系人姓名",
      "type": "互动类型(gift/meetup/help/deepTalk/theyInitiated/paidTransaction/normal)",
      "heatGain": 热度增益数值(3-15),
      "description": "互动描述"
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

互动类型说明：
- gift: 送礼、请客
- meetup: 线下见面、聚餐
- help: 帮忙、协助
- deepTalk: 深度交流、谈心
- theyInitiated: 对方主动联系
- paidTransaction: 付费交易
- normal: 日常互动

热度增益参考：
- normal: 3
- theyInitiated/paidTransaction: 5
- help: 8
- gift/deepTalk: 10
- meetup: 15

请只返回JSON，不要添加任何其他文字。
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
    
    try {
      final modelName = await _getModelName();
      final response = await http.post(
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
    }
  }

  /// 测试API连接（带详细错误信息）
  static Future<String> testConnectionWithDetails() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '未配置API Key';
    }
    
    try {
      final modelName = await _getModelName();
      final response = await http.post(
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
    }
  }
}
