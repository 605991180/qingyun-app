import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/heat_ring.dart';
import '../widgets/voice_button.dart';
import '../widgets/warning_list.dart';
import 'contact_detail_page.dart';
import 'add_interaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await StorageService.loadContacts();
    // 更新所有联系人的热度（计算衰减）
    for (var contact in contacts) {
      HeatCalculator.updateContactHeat(contact);
    }
    await StorageService.saveContacts(contacts);
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final warningCount = _contacts.where((c) => HeatCalculator.needsWarning(c)).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('关系热度'),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          if (warningCount > 0)
            Semantics(
              label: '$warningCount个联系人需要关注',
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$warningCount',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadContacts,
              color: Colors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 统计卡片
                    _buildStatsCard(),
                    
                    // 环形热力图
                    SizedBox(
                      height: 320,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HeatRing(
                          contacts: _contacts,
                          onContactTap: _showContactDetail,
                        ),
                      ),
                    ),

                    // 预警列表
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '需要关注',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '热度<30%',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(100),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          WarningList(
                            contacts: _contacts,
                            onContactTap: _showContactDetail,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // 全部联系人列表
                    if (_contacts.isNotEmpty) _buildAllContactsList(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: VoiceButton(
        isListening: false,
        onPressed: _addInteraction,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatsCard() {
    final avgHeat = _contacts.isEmpty
        ? 0.0
        : _contacts.fold<double>(0, (sum, c) => sum + c.heat) / _contacts.length;
    final hotCount = _contacts.where((c) => c.heat >= 70).length;
    final coldCount = _contacts.where((c) => c.heat < 30).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16213E),
            const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '总人数',
            '${_contacts.length}',
            Colors.cyan,
            Icons.people,
            () => _showContactListDialog('全部联系人', _contacts),
          ),
          _buildStatItem(
            '平均热度',
            '${avgHeat.toInt()}%',
            Colors.orange,
            Icons.whatshot,
            () => _showContactListDialog(
              '平均热度附近',
              _contacts.where((c) => (c.heat - avgHeat).abs() <= 15).toList(),
            ),
          ),
          _buildStatItem(
            '热络',
            '$hotCount',
            Colors.green,
            Icons.favorite,
            () => _showContactListDialog(
              '热络（>=70%）',
              _contacts.where((c) => c.heat >= 70).toList(),
            ),
          ),
          _buildStatItem(
            '冷淡',
            '$coldCount',
            Colors.blue,
            Icons.ac_unit,
            () => _showContactListDialog(
              '冷淡（<30%）',
              _contacts.where((c) => c.heat < 30).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: '$label：$value，点击查看详情',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
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
        ),
      ),
    );
  }

  void _showContactListDialog(String title, List<Contact> contacts) {
    final sortedContacts = List<Contact>.from(contacts)
      ..sort((a, b) => b.heat.compareTo(a.heat));
    
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
                    title,
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
                      color: Colors.orange.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sortedContacts.length}人',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (sortedContacts.isEmpty)
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
                  itemCount: sortedContacts.length,
                  itemBuilder: (context, index) {
                    final contact = sortedContacts[index];
                    final color = Color(HeatCalculator.getHeatColorValue(contact.heat));
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _showContactDetail(contact);
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [color.withAlpha(180), color.withAlpha(80)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            contact.name.isNotEmpty ? contact.name[0] : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildAllContactsList() {
    final sortedContacts = List<Contact>.from(_contacts)
      ..sort((a, b) => b.heat.compareTo(a.heat));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people, color: Colors.cyan, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '全部联系人',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '按热度排序',
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedContacts.length,
            itemBuilder: (context, index) {
              final contact = sortedContacts[index];
              final color = Color(HeatCalculator.getHeatColorValue(contact.heat));
              final daysSince = DateTime.now().difference(contact.lastInteraction).inDays;

              return ListTile(
                onTap: () => _showContactDetail(contact),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color.withAlpha(180), color.withAlpha(80)],
                    ),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (contact.relationType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(contact.relationType!.color).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          contact.relationType!.label,
                          style: TextStyle(
                            color: Color(contact.relationType!.color),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '$daysSince天前 · ${HeatCalculator.getHeatLevel(contact.heat)}',
                  style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${contact.heat.toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white.withAlpha(50)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showContactDetail(Contact contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(
          contact: contact,
          onUpdate: _loadContacts,
        ),
      ),
    );
    _loadContacts();
  }

  void _addInteraction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddInteractionPage(allContacts: _contacts),
      ),
    );
    if (result == true) {
      _loadContacts();
    }
  }
}
