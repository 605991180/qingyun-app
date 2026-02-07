import '../models/contact.dart';
import '../models/contact_resource.dart';
import '../models/diary.dart';
import '../services/storage_service.dart';
import '../services/heat_calculator.dart';

/// AI智能解析服务
/// 模拟AI功能，通过关键词匹配解析日记内容
class AIParserService {
  
  /// 解析日记并返回分析结果
  static Future<DiaryAnalysisResult> analyzeDiary(String content, List<Contact> contacts) async {
    final result = DiaryAnalysisResult();
    
    // 1. 识别提到的联系人
    for (var contact in contacts) {
      if (content.contains(contact.name)) {
        final interaction = _analyzeInteraction(content, contact.name);
        result.interactions.add(interaction);
      }
    }
    
    // 2. 识别新联系人（格式：认识了XXX、结识了XXX）
    final newContactPatterns = [
      RegExp(r'认识了[「」""'']*([^\s,，。！!?？、]{2,4})'),
      RegExp(r'结识了[「」""'']*([^\s,，。！!?？、]{2,4})'),
      RegExp(r'新认识[「」""'']*([^\s,，。！!?？、]{2,4})'),
      RegExp(r'遇到了[「」""'']*([^\s,，。！!?？、]{2,4})'),
    ];
    
    for (var pattern in newContactPatterns) {
      final matches = pattern.allMatches(content);
      for (var match in matches) {
        final name = match.group(1);
        if (name != null && !contacts.any((c) => c.name == name)) {
          result.newContacts.add(name);
        }
      }
    }
    
    // 3. 识别资源信息
    for (var contact in contacts) {
      if (content.contains(contact.name)) {
        final resources = _extractResources(content, contact);
        result.resources.addAll(resources);
      }
    }
    
    // 4. 分析情绪
    result.mood = _analyzeMood(content);
    
    return result;
  }
  
  /// 分析与特定联系人的互动
  static InteractionAnalysis _analyzeInteraction(String content, String contactName) {
    final analysis = InteractionAnalysis(contactName: contactName);
    
    // 识别互动类型和热度增益
    if (_containsAny(content, ['请客', '请吃', '送礼', '送了', '礼物'])) {
      analysis.type = InteractionType.gift;
      analysis.heatGain = 10.0;
      analysis.description = '送礼/请客';
    } else if (_containsAny(content, ['见面', '见了', '约了', '一起吃', '聚餐', '聚会', '线下'])) {
      analysis.type = InteractionType.meetup;
      analysis.heatGain = 15.0;
      analysis.description = '线下见面';
    } else if (_containsAny(content, ['帮忙', '帮了', '帮助', '协助', '支持'])) {
      analysis.type = InteractionType.help;
      analysis.heatGain = 8.0;
      analysis.description = '互相帮助';
    } else if (_containsAny(content, ['深聊', '长谈', '谈心', '倾诉', '交心'])) {
      analysis.type = InteractionType.deepTalk;
      analysis.heatGain = 10.0;
      analysis.description = '深度交流';
    } else if (_containsAny(content, ['主动联系', '主动找', '他打来', '她打来', '他发来', '她发来'])) {
      analysis.type = InteractionType.theyInitiated;
      analysis.heatGain = 5.0;
      analysis.description = '对方主动联系';
    } else if (_containsAny(content, ['付款', '转账', '付费', '花钱', '消费'])) {
      analysis.type = InteractionType.paidTransaction;
      analysis.heatGain = 5.0;
      analysis.description = '付费交易';
    } else {
      analysis.type = InteractionType.normal;
      analysis.heatGain = 3.0;
      analysis.description = '日常互动';
    }
    
    // 识别资源消耗
    final moneyMatch = RegExp(r'(\d+)[元块]').firstMatch(content);
    if (moneyMatch != null) {
      analysis.resourceCost = double.tryParse(moneyMatch.group(1) ?? '0') ?? 0;
      analysis.resourceType = ResourceType.money;
    }
    
    final timeMatch = RegExp(r'(\d+)[小时个钟]').firstMatch(content);
    if (timeMatch != null && analysis.resourceCost == 0) {
      analysis.resourceCost = double.tryParse(timeMatch.group(1) ?? '0') ?? 0;
      analysis.resourceType = ResourceType.time;
    }
    
    return analysis;
  }
  
  /// 从文本中提取联系人资源
  static List<ContactResource> _extractResources(String content, Contact contact) {
    final resources = <ContactResource>[];
    
    // 检查是否提到了资源相关信息
    final category = ResourceCategoryHelper.inferCategory(content);
    if (category != null) {
      // 提取相关描述
      String description = '';
      
      // 政治资源描述
      if (category == ResourceCategory.political) {
        final match = RegExp(r'(在[^，。！]*(?:政府|部门|单位)[^，。！]*)').firstMatch(content);
        description = match?.group(1) ?? '有政府资源';
      }
      // 商业资源描述
      else if (category == ResourceCategory.business) {
        final match = RegExp(r'((?:做|开|经营)[^，。！]*(?:公司|生意|企业)[^，。！]*)').firstMatch(content);
        description = match?.group(1) ?? '有商业资源';
      }
      // 社会资源描述
      else if (category == ResourceCategory.social) {
        final match = RegExp(r'(认识[^，。！]*人|人脉[^，。！]*)').firstMatch(content);
        description = match?.group(1) ?? '有社会资源';
      }
      // 便利条件描述
      else if (category == ResourceCategory.convenience) {
        final match = RegExp(r'(在[^，。！]*(?:医院|学校|银行)[^，。！]*|能[^，。！]*(?:帮|办)[^，。！]*)').firstMatch(content);
        description = match?.group(1) ?? '能提供便利';
      }
      // 知识技能描述
      else if (category == ResourceCategory.knowledge) {
        final match = RegExp(r'(是[^，。！]*(?:专家|教授|律师|医生)[^，。！]*|懂[^，。！]*)').firstMatch(content);
        description = match?.group(1) ?? '有专业知识';
      }
      // 情感支持描述
      else if (category == ResourceCategory.emotional) {
        description = '可以提供情感支持';
      }
      
      if (description.isNotEmpty) {
        resources.add(ContactResource(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          contactId: contact.id,
          contactName: contact.name,
          category: category,
          description: description,
        ));
      }
    }
    
    return resources;
  }
  
  /// 分析文本情绪
  static String? _analyzeMood(String content) {
    if (_containsAny(content, ['开心', '高兴', '快乐', '棒', '赞', '太好了', '哈哈'])) {
      return MoodType.happy;
    }
    if (_containsAny(content, ['累', '疲惫', '困', '辛苦', '加班'])) {
      return MoodType.tired;
    }
    if (_containsAny(content, ['难过', '伤心', '悲伤', '郁闷', '失落'])) {
      return MoodType.sad;
    }
    if (_containsAny(content, ['生气', '愤怒', '烦', '讨厌', '气死'])) {
      return MoodType.angry;
    }
    if (_containsAny(content, ['激动', '兴奋', '期待', '惊喜'])) {
      return MoodType.excited;
    }
    if (_containsAny(content, ['焦虑', '担心', '紧张', '压力'])) {
      return MoodType.anxious;
    }
    if (_containsAny(content, ['感谢', '感恩', '谢谢', '感激'])) {
      return MoodType.grateful;
    }
    return MoodType.calm;
  }
  
  /// 应用分析结果到数据
  static Future<void> applyAnalysisResult(DiaryAnalysisResult result) async {
    final contacts = await StorageService.loadContacts();
    
    // 1. 添加新联系人
    for (var name in result.newContacts) {
      final newContact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString(),
        name: name,
        heat: 1.0,
      );
      await StorageService.addContact(newContact);
    }
    
    // 2. 更新互动记录和热度
    for (var interaction in result.interactions) {
      final contact = contacts.firstWhere(
        (c) => c.name == interaction.contactName,
        orElse: () => Contact(id: '', name: ''),
      );
      
      if (contact.id.isNotEmpty) {
        // 添加互动记录
        final interactionRecord = Interaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          time: DateTime.now(),
          content: interaction.description,
          type: interaction.type,
          heatGain: interaction.heatGain,
        );
        contact.interactions.add(interactionRecord);
        
        // 添加资源消耗
        if (interaction.resourceCost > 0 && interaction.resourceType != null) {
          final resource = Resource(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            time: DateTime.now(),
            type: interaction.resourceType!,
            description: interaction.description,
            amount: interaction.resourceCost,
          );
          contact.resources.add(resource);
        }
        
        // 更新热度
        contact.heat = HeatCalculator.calculateNewHeat(
          contact, 
          interactionRecord,
          resource: interaction.resourceCost > 0 ? Resource(
            id: '',
            time: DateTime.now(),
            type: interaction.resourceType ?? ResourceType.money,
            description: '',
            amount: interaction.resourceCost,
          ) : null,
        );
        contact.lastInteraction = DateTime.now();
        
        await StorageService.updateContact(contact);
      }
    }
    
    // 3. 保存资源信息
    for (var resource in result.resources) {
      await StorageService.addContactResource(resource);
    }
  }
  
  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}

/// 日记分析结果
class DiaryAnalysisResult {
  List<InteractionAnalysis> interactions = [];
  List<String> newContacts = [];
  List<ContactResource> resources = [];
  String? mood;
  
  bool get hasContent => 
    interactions.isNotEmpty || newContacts.isNotEmpty || resources.isNotEmpty;
}

/// 互动分析结果
class InteractionAnalysis {
  final String contactName;
  InteractionType type = InteractionType.normal;
  double heatGain = 3.0;
  String description = '';
  double resourceCost = 0;
  ResourceType? resourceType;
  
  InteractionAnalysis({required this.contactName});
}
