import 'dart:math';
import '../models/contact.dart';

/// 热度计算器
/// 公式: 当前热度 = 上次热度 × e^(-λ×天数) + 本次互动增益 - 资源消耗
class HeatCalculator {
  static const double minHeat = 1.0; // 最低热度底线 1%
  static const double maxHeat = 200.0; // 挚友可超150%，上限200%
  
  /// 获取衰减系数λ（梯度下降）
  /// 3天衰减1%，半年后递减
  static double getDecayLambda(Contact contact) {
    final daysSinceCreated = DateTime.now().difference(contact.createdAt).inDays;
    
    // 基础衰减系数：3天衰减1% => λ ≈ 0.00333
    double baseLambda = 0.00333;
    
    // 半年(180天)后递减
    if (daysSinceCreated > 180) {
      // 关系越久，衰减越慢
      baseLambda *= 0.5;
    }
    if (daysSinceCreated > 365) {
      baseLambda *= 0.5;
    }
    
    // 热度越高的关系衰减越慢（梯度下降）
    if (contact.heat > 100) {
      baseLambda *= 0.7;
    } else if (contact.heat > 50) {
      baseLambda *= 0.85;
    }
    
    return baseLambda;
  }

  /// 计算时间衰减后的热度
  /// 使用指数衰减公式: heat × e^(-λ×天数)
  static double calculateDecay(Contact contact) {
    final daysPassed = DateTime.now().difference(contact.lastInteraction).inDays;
    if (daysPassed <= 0) return contact.heat;

    final lambda = getDecayLambda(contact);
    double newHeat = contact.heat * exp(-lambda * daysPassed);
    
    // 底线保护
    if (newHeat < minHeat) {
      newHeat = minHeat;
    }
    
    return newHeat;
  }

  /// 添加互动后计算新热度
  /// 公式: 当前热度 = 衰减后热度 + 互动增益 - 资源消耗
  static double calculateNewHeat(Contact contact, Interaction interaction, {Resource? resource}) {
    // 先计算衰减
    double decayedHeat = calculateDecay(contact);
    
    // 加上互动增益
    double newHeat = decayedHeat + interaction.heatGain;
    
    // 减去资源消耗
    if (resource != null) {
      newHeat -= resource.cost;
    }
    
    // 边界处理
    if (newHeat < minHeat) newHeat = minHeat;
    if (newHeat > maxHeat) newHeat = maxHeat;
    
    return newHeat;
  }

  /// 更新联系人热度（仅衰减）
  static void updateContactHeat(Contact contact) {
    contact.heat = calculateDecay(contact);
  }

  /// 判断是否需要预警（热度低于阈值）
  static bool needsWarning(Contact contact, {double threshold = 30.0}) {
    return contact.heat < threshold;
  }

  /// 获取热度等级描述
  static String getHeatLevel(double heat) {
    if (heat >= 150) return '挚友';
    if (heat >= 100) return '密友';
    if (heat >= 70) return '好友';
    if (heat >= 40) return '朋友';
    if (heat >= 20) return '熟人';
    if (heat >= 5) return '认识';
    return '陌生';
  }

  /// 获取热度对应颜色值（蓝→橙→红→黑/金）
  static int getHeatColorValue(double heat) {
    if (heat >= 150) return 0xFFFFD700; // 金色 - 挚友
    if (heat >= 100) return 0xFFFF1744; // 深红 - 密友
    if (heat >= 70) return 0xFFFF5722; // 红橙 - 好友
    if (heat >= 40) return 0xFFFF9800; // 橙色 - 朋友
    if (heat >= 20) return 0xFFFFC107; // 黄橙 - 熟人
    if (heat >= 5) return 0xFF42A5F5; // 蓝色 - 认识
    return 0xFF90CAF9; // 浅蓝 - 陌生
  }

  /// 预测多少天后热度降到某个值
  static int predictDaysToHeat(Contact contact, double targetHeat) {
    if (contact.heat <= targetHeat) return 0;
    
    final lambda = getDecayLambda(contact);
    // heat × e^(-λ×days) = targetHeat
    // days = -ln(targetHeat/heat) / λ
    final days = -log(targetHeat / contact.heat) / lambda;
    return days.ceil();
  }

  /// 获取预警信息
  static String? getWarningMessage(Contact contact) {
    if (contact.heat < 10) {
      return '关系即将冷却，建议尽快联系';
    } else if (contact.heat < 20) {
      return '热度较低，${predictDaysToHeat(contact, 10)}天后将变得陌生';
    } else if (contact.heat < 30) {
      return '注意维护，${predictDaysToHeat(contact, 20)}天后热度将偏低';
    }
    return null;
  }
}
