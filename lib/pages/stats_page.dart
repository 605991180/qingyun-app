import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/diary.dart';
import '../models/occupation.dart';
import '../services/storage_service.dart';
import 'occupation_manage_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Contact> _contacts = [];
  List<Diary> _diaries = [];
  Map<OccupationCategory, int> _occupationStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final contacts = await StorageService.loadContacts();
    final diaries = await StorageService.loadDiaries();
    final occupationStats = await OccupationService.getOccupationStats();
    setState(() {
      _contacts = contacts;
      _diaries = diaries;
      _occupationStats = occupationStats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.cyan, size: 24),
            SizedBox(width: 8),
            Text('数据统计'),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.cyan,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 概览卡片
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    
                    // 仕农工商分类
                    _buildOccupationCard(),
                    const SizedBox(height: 16),
                    
                    // 热度分布
                    _buildHeatDistributionCard(),
                    const SizedBox(height: 16),
                    
                    // 互动趋势
                    _buildInteractionTrendCard(),
                    const SizedBox(height: 16),
                    
                    // 日记统计
                    _buildDiaryStatsCard(),
                    const SizedBox(height: 16),
                    
                    // 资源投入统计
                    _buildResourceStatsCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final avgHeat = _contacts.isEmpty
        ? 0.0
        : _contacts.fold<double>(0, (sum, c) => sum + c.heat) / _contacts.length;
    final totalInteractions = _contacts.fold<int>(0, (sum, c) => sum + c.interactions.length);
    final activeContacts = _contacts.where((c) {
      final daysSince = DateTime.now().difference(c.lastInteraction).inDays;
      return daysSince <= 7;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withAlpha(30),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: Colors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                '总览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildOverviewItem('总联系人', '${_contacts.length}', Colors.cyan)),
              Expanded(child: _buildOverviewItem('平均热度', '${avgHeat.toInt()}%', Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOverviewItem('总互动次数', '$totalInteractions', Colors.green)),
              Expanded(child: _buildOverviewItem('本周活跃', '$activeContacts人', Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(150),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOccupationCard() {
    final total = _occupationStats.values.fold<int>(0, (sum, v) => sum + v);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withAlpha(20),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                '仕农工商',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OccupationManagePage()),
                  );
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text('管理', style: TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '已分类 $total 人',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: OccupationCategory.values.map((cat) {
              final count = _occupationStats[cat] ?? 0;
              final color = Color(OccupationHelper.getColor(cat));
              return Expanded(
                child: GestureDetector(
                  onTap: () => _showOccupationContacts(cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(50)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          OccupationHelper.getIcon(cat),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          OccupationHelper.getName(cat),
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$count人',
                          style: TextStyle(
                            color: Colors.white.withAlpha(150),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showOccupationContacts(OccupationCategory category) async {
    final contactIds = await OccupationService.getContactIdsByOccupation(category);
    final matchedContacts = _contacts.where((c) => contactIds.contains(c.id)).toList();
    final color = Color(OccupationHelper.getColor(category));
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    OccupationHelper.getIcon(category),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    OccupationHelper.getFullName(category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${matchedContacts.length}人',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (matchedContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无联系人',
                  style: TextStyle(color: Colors.white.withAlpha(100)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: matchedContacts.length,
                  itemBuilder: (context, index) {
                    final contact = matchedContacts[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(50),
                        ),
                        child: Center(
                          child: Text(
                            contact.name.isNotEmpty ? contact.name[0] : '?',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      title: Text(contact.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(
                        '${contact.heat.toInt()}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatDistributionCard() {
    // 热度分布统计
    final veryHot = _contacts.where((c) => c.heat >= 80).length;
    final hot = _contacts.where((c) => c.heat >= 50 && c.heat < 80).length;
    final warm = _contacts.where((c) => c.heat >= 30 && c.heat < 50).length;
    final cold = _contacts.where((c) => c.heat < 30).length;
    final total = _contacts.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '热度分布',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeatBar('炽热 (≥80%)', veryHot, total, const Color(0xFFFFD700)),
          const SizedBox(height: 12),
          _buildHeatBar('热络 (50-79%)', hot, total, Colors.orange),
          const SizedBox(height: 12),
          _buildHeatBar('温和 (30-49%)', warm, total, Colors.green),
          const SizedBox(height: 12),
          _buildHeatBar('冷淡 (<30%)', cold, total, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHeatBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
            Text('$count人', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractionTrendCard() {
    // 计算近7天的互动次数
    final now = DateTime.now();
    final weekData = <int>[];
    final weekLabels = <String>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      weekLabels.add('${date.month}/${date.day}');
      
      int count = 0;
      for (var contact in _contacts) {
        count += contact.interactions.where((interaction) {
          return interaction.time.year == date.year &&
                 interaction.time.month == date.month &&
                 interaction.time.day == date.day;
        }).length;
      }
      weekData.add(count);
    }
    
    final maxCount = weekData.isEmpty ? 1 : weekData.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount > 0 ? maxCount : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                '近7天互动趋势',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final height = weekData[index] / effectiveMax * 80;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${weekData[index]}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: height > 0 ? height : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.withAlpha(100), Colors.green],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekLabels[index],
                        style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryStatsCard() {
    // 日记统计
    final now = DateTime.now();
    final thisMonth = _diaries.where((d) =>
        d.date.year == now.year && d.date.month == now.month).length;
    final lastMonth = _diaries.where((d) =>
        d.date.year == now.year && d.date.month == now.month - 1 ||
        (now.month == 1 && d.date.year == now.year - 1 && d.date.month == 12)).length;
    
    // 心情统计
    final moodCounts = <String, int>{};
    for (var diary in _diaries) {
      if (diary.mood != null) {
        moodCounts[diary.mood!] = (moodCounts[diary.mood!] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.book, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                '日记统计',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatBox('总日记数', '${_diaries.length}', Icons.edit_note, Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox('本月', '$thisMonth篇', Icons.calendar_today, Colors.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox('上月', '$lastMonth篇', Icons.history, Colors.grey),
              ),
            ],
          ),
          if (moodCounts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '心情分布',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moodCounts.entries.take(5).map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key} ${entry.value}次',
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceStatsCard() {
    // 资源投入统计
    double totalMoney = 0;
    double totalTime = 0;
    double totalEnergy = 0;
    double totalFavor = 0;

    for (var contact in _contacts) {
      for (var resource in contact.resources) {
        switch (resource.type) {
          case ResourceType.money:
            totalMoney += resource.amount;
            break;
          case ResourceType.time:
            totalTime += resource.amount;
            break;
          case ResourceType.energy:
            totalEnergy += resource.amount;
            break;
          case ResourceType.favor:
            totalFavor += resource.amount;
            break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                '资源投入统计',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildResourceItem('金钱', '${totalMoney.toInt()}元', Icons.attach_money, Colors.green)),
              Expanded(child: _buildResourceItem('时间', '${totalTime.toInt()}小时', Icons.access_time, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildResourceItem('精力', '${totalEnergy.toInt()}点', Icons.bolt, Colors.orange)),
              Expanded(child: _buildResourceItem('人情', '${totalFavor.toInt()}点', Icons.favorite, Colors.pink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
