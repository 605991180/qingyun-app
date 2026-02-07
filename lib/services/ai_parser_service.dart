import '../models/contact.dart';
import '../models/contact_resource.dart';
import '../models/diary.dart';
import '../services/storage_service.dart';
import '../services/heat_calculator.dart';

/// AI智能解析服务
/// 模拟AI功能，通过关键词匹配解析日记内容
class AIParserService {
  
  /// 移除书名号、引号等符号中的内容，避免误识别
  static String _removeQuotedContent(String content) {
    // 移除书名号内容
    String result = content.replaceAll(RegExp(r'《[^》]*》'), ' ');
    // 移除双书名号内容
    result = result.replaceAll(RegExp(r'〈[^〉]*〉'), ' ');
    // 保留普通引号内容（可能是对话，包含人名）
    return result;
  }
  
  /// 检查名字是否在有效位置（不在书名号等符号内）
  static bool _isValidNameMatch(String content, String name) {
    // 检查是否在书名号内
    final bookPattern = RegExp('《[^》]*$name[^》]*》');
    if (bookPattern.hasMatch(content)) {
      return false;
    }
    // 检查是否在双书名号内
    final doubleBookPattern = RegExp('〈[^〉]*$name[^〉]*〉');
    if (doubleBookPattern.hasMatch(content)) {
      return false;
    }
    return content.contains(name);
  }
  
  /// 解析日记并返回分析结果
  static Future<DiaryAnalysisResult> analyzeDiary(String content, List<Contact> contacts) async {
    final result = DiaryAnalysisResult();
    
    // 1. 识别提到的联系人（排除书名号中的内容）
    for (var contact in contacts) {
      if (_isValidNameMatch(content, contact.name)) {
        final interaction = _analyzeInteraction(content, contact.name);
        result.interactions.add(interaction);
      }
    }
    
    // 2. 识别新联系人（格式：认识了XXX、结识了XXX）
    final cleanContent = _removeQuotedContent(content);
    final newContactPatterns = [
      RegExp(r'认识了[「」""'']*([^\s,，。！!?？、《》〈〉]{2,4})'),
      RegExp(r'结识了[「」""'']*([^\s,，。！!?？、《》〈〉]{2,4})'),
      RegExp(r'新认识[「」""'']*([^\s,，。！!?？、《》〈〉]{2,4})'),
      RegExp(r'遇到了[「」""'']*([^\s,，。！!?？、《》〈〉]{2,4})'),
    ];
    
    for (var pattern in newContactPatterns) {
      final matches = pattern.allMatches(cleanContent);
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
    
    // 先检查负面互动（优先级更高，避免误判）
    if (_containsAny(content, ['吵架', '争吵', '吵了', '大吵', '争执', '冲突', '翻脸'])) {
      analysis.type = InteractionType.conflict;
      analysis.heatGain = -5.0;
      analysis.description = '发生争吵';
    } else if (_containsAny(content, ['冷战', '不理', '没说话', '不联系', '互不理睬'])) {
      analysis.type = InteractionType.coldWar;
      analysis.heatGain = -3.0;
      analysis.description = '冷战中';
    } else if (_containsAny(content, ['背叛', '出卖', '欺骗', '骗了', '背后', '阴了'])) {
      analysis.type = InteractionType.betrayal;
      analysis.heatGain = -15.0;
      analysis.description = '遭遇背叛';
    } else if (_containsAny(content, ['疏远', '淡了', '不来往', '断联', '失联', '很久没'])) {
      analysis.type = InteractionType.neglect;
      analysis.heatGain = -2.0;
      analysis.description = '关系疏远';
    }
    // 正面互动识别
    else if (_containsAny(content, ['请客', '请吃', '送礼', '送了', '礼物'])) {
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
  
  /// 分析文本情绪（优化版）
  static String? _analyzeMood(String content) {
    // 情绪关键词映射表，按优先级和权重组织
    final moodKeywords = {
      MoodType.happy: {
        'high': ['太开心了', '超级高兴', '特别快乐', '非常棒', '超赞', '太好了', '完美'],
        'medium': ['开心', '高兴', '快乐', '棒', '赞', '好', '不错', '满意', '惊喜'],
        'low': ['哈哈', '嘻嘻', '呵呵', '还行', '可以'],
      },
      MoodType.sad: {
        'high': ['崩溃', '绝望', '心碎', '痛苦', '太难过了', '哭死', '受不了'],
        'medium': ['难过', '伤心', '悲伤', '郁闷', '失落', '委屈', '心酸'],
        'low': ['唉', '叹气', '遗憾', '可惜', '不开心'],
      },
      MoodType.angry: {
        'high': ['气死了', '愤怒', '暴怒', '火大', '受够了', '忍无可忍'],
        'medium': ['生气', '烦', '讨厌', '恼火', '不爽', '无语'],
        'low': ['烦躁', '不满', '郁闷'],
      },
      MoodType.tired: {
        'high': ['累死了', '精疲力竭', '撑不住', '要倒了', '快不行了'],
        'medium': ['累', '疲惫', '困', '辛苦', '加班', '熬夜', '没精神'],
        'low': ['有点累', '还好', '一般'],
      },
      MoodType.excited: {
        'high': ['太激动了', '兴奋死了', '超期待', '燃爆了', '太棒了'],
        'medium': ['激动', '兴奋', '期待', '惊喜', '振奋', '热血'],
        'low': ['有点期待', '还蛮期待'],
      },
      MoodType.anxious: {
        'high': ['焦虑死了', '快疯了', '崩溃边缘', '压力山大', '喘不过气'],
        'medium': ['焦虑', '担心', '紧张', '压力', '不安', '忐忑', '心慌'],
        'low': ['有点紧张', '稍微担心'],
      },
      MoodType.grateful: {
        'high': ['太感谢了', '感激不尽', '永远感恩', '万分感谢'],
        'medium': ['感谢', '感恩', '谢谢', '感激', '幸运', '庆幸'],
        'low': ['多亏', '托福', '还好有'],
      },
      MoodType.calm: {
        'high': ['非常平静', '内心安宁', '很满足'],
        'medium': ['平静', '安宁', '放松', '舒适', '惬意', '自在'],
        'low': ['还好', '一般', '正常', '普通'],
      },
    };
    
    // 计算每种情绪的得分
    final scores = <String, double>{};
    
    for (var mood in moodKeywords.keys) {
      double score = 0;
      final keywords = moodKeywords[mood]!;
      
      // 高权重关键词 (+3分)
      for (var keyword in keywords['high']!) {
        if (content.contains(keyword)) score += 3;
      }
      // 中权重关键词 (+2分)
      for (var keyword in keywords['medium']!) {
        if (content.contains(keyword)) score += 2;
      }
      // 低权重关键词 (+1分)
      for (var keyword in keywords['low']!) {
        if (content.contains(keyword)) score += 1;
      }
      
      if (score > 0) {
        scores[mood] = score;
      }
    }
    
    // 如果没有检测到任何情绪，返回平静
    if (scores.isEmpty) {
      return MoodType.calm;
    }
    
    // 返回得分最高的情绪
    final sortedMoods = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMoods.first.key;
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
    
    // 2. 合并同一联系人的多次互动
    final mergedInteractions = _mergeInteractionsByContact(result.interactions);
    
    // 3. 更新互动记录和热度
    for (var interaction in mergedInteractions) {
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
    
    // 4. 保存资源信息
    for (var resource in result.resources) {
      await StorageService.addContactResource(resource);
    }
  }
  
  /// 合并同一联系人的多次互动
  static List<InteractionAnalysis> _mergeInteractionsByContact(List<InteractionAnalysis> interactions) {
    if (interactions.isEmpty) return [];
    
    // 按联系人名字分组
    final Map<String, List<InteractionAnalysis>> grouped = {};
    for (var interaction in interactions) {
      grouped.putIfAbsent(interaction.contactName, () => []);
      grouped[interaction.contactName]!.add(interaction);
    }
    
    // 合并每个联系人的互动
    final merged = <InteractionAnalysis>[];
    for (var entry in grouped.entries) {
      final contactInteractions = entry.value;
      
      if (contactInteractions.length == 1) {
        merged.add(contactInteractions.first);
      } else {
        // 需要合并多次互动
        merged.add(_mergeSingleContactInteractions(entry.key, contactInteractions));
      }
    }
    
    return merged;
  }
  
  /// 合并单个联系人的多次互动
  static InteractionAnalysis _mergeSingleContactInteractions(
    String contactName, 
    List<InteractionAnalysis> interactions
  ) {
    final result = InteractionAnalysis(contactName: contactName);
    
    // 收集所有描述
    final descriptions = <String>[];
    double totalHeatGain = 0;
    double totalResourceCost = 0;
    ResourceType? resourceType;
    
    // 定义互动类型优先级（绝对值越大越优先）
    InteractionType bestType = InteractionType.normal;
    double bestTypeWeight = 0;
    
    for (var interaction in interactions) {
      // 合并描述（去重）
      if (interaction.description.isNotEmpty && 
          !descriptions.contains(interaction.description)) {
        descriptions.add(interaction.description);
      }
      
      // 累加热度增益
      totalHeatGain += interaction.heatGain;
      
      // 累加资源消耗
      if (interaction.resourceCost > 0) {
        totalResourceCost += interaction.resourceCost;
        resourceType ??= interaction.resourceType;
      }
      
      // 选择影响最大的互动类型（按热度绝对值）
      final weight = interaction.heatGain.abs();
      if (weight > bestTypeWeight) {
        bestTypeWeight = weight;
        bestType = interaction.type;
      }
    }
    
    // 设置合并后的属性
    result.type = bestType;
    result.heatGain = totalHeatGain;
    result.description = descriptions.length > 1 
        ? '${descriptions.join("、")}（共${interactions.length}次互动）'
        : descriptions.isNotEmpty ? descriptions.first : '多次互动';
    result.resourceCost = totalResourceCost;
    result.resourceType = resourceType;
    
    return result;
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
