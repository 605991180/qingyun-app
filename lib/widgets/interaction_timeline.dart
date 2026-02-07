import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';

/// 互动时间线视图
class InteractionTimeline extends StatelessWidget {
  final List<Interaction> interactions;
  final Color themeColor;

  const InteractionTimeline({
    super.key,
    required this.interactions,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              '暂无互动记录',
              style: TextStyle(color: Colors.grey.withAlpha(150), fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 按时间排序（最新的在前）
    final sortedInteractions = List<Interaction>.from(interactions)
      ..sort((a, b) => b.time.compareTo(a.time));

    // 按日期分组
    final groupedByDate = <String, List<Interaction>>{};
    for (var interaction in sortedInteractions) {
      final dateKey = _formatDateKey(interaction.time);
      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(interaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupedByDate.length,
      itemBuilder: (context, index) {
        final dateKey = groupedByDate.keys.elementAt(index);
        final dayInteractions = groupedByDate[dateKey]!;
        
        return _buildDateSection(dateKey, dayInteractions);
      },
    );
  }

  Widget _buildDateSection(String dateKey, List<Interaction> dayInteractions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withAlpha(50)),
                ),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dayInteractions.length}次互动',
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  height: 1,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ],
          ),
        ),
        // 当天的互动列表
        ...dayInteractions.asMap().entries.map((entry) {
          final index = entry.key;
          final interaction = entry.value;
          final isLast = index == dayInteractions.length - 1;
          return _buildTimelineItem(interaction, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(Interaction interaction, bool isLast) {
    final isNegative = interaction.heatGain < 0;
    final itemColor = isNegative ? Colors.redAccent : themeColor;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线部分
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // 时间点圆圈
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: itemColor,
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withAlpha(100),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // 连接线
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            itemColor.withAlpha(100),
                            itemColor.withAlpha(30),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 内容部分
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: itemColor.withAlpha(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：时间和热度变化
                  Row(
                    children: [
                      Text(
                        _formatTime(interaction.time),
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // 互动类型标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: itemColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          interaction.typeLabel,
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 热度变化
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNegative 
                              ? Colors.red.withAlpha(30) 
                              : Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNegative ? Icons.trending_down : Icons.trending_up,
                              size: 12,
                              color: isNegative ? Colors.redAccent : Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isNegative ? "" : "+"}${interaction.heatGain.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isNegative ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 互动内容
                  Text(
                    interaction.content,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateKey(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return '今天';
    } else if (date == yesterday) {
      return '昨天';
    } else if (now.difference(time).inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else if (time.year == now.year) {
      return '${time.month}月${time.day}日';
    } else {
      return '${time.year}年${time.month}月${time.day}日';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
