import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import '../services/qianwen_service.dart';

class SettingsPage extends StatefulWidget {
  final Function() onDataChanged;

  const SettingsPage({super.key, required this.onDataChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasApiKey = false;
  bool _isTestingApi = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await QianwenService.hasApiKey();
    setState(() => _hasApiKey = hasKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI智能分析
          _buildSection(
            title: 'AI智能分析',
            icon: Icons.psychology,
            color: Colors.purple,
            children: [
              _buildListTile(
                icon: _hasApiKey ? Icons.check_circle : Icons.key,
                title: '通义千问 API',
                subtitle: _hasApiKey ? '已配置，点击修改' : '点击配置API Key',
                onTap: _showApiKeyDialog,
              ),
              if (_hasApiKey)
                _buildListTile(
                  icon: Icons.network_check,
                  title: '测试连接',
                  subtitle: _isTestingApi ? '测试中...' : '验证API是否可用',
                  onTap: _isTestingApi ? () {} : _testApiConnection,
                ),
              if (_hasApiKey)
                _buildListTile(
                  icon: Icons.delete_outline,
                  title: '清除API Key',
                  subtitle: '删除已保存的密钥',
                  onTap: _confirmRemoveApiKey,
                  danger: true,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 数据管理
          _buildSection(
            title: '数据管理',
            icon: Icons.storage,
            color: Colors.cyan,
            children: [
              _buildListTile(
                icon: Icons.upload_file,
                title: '批量导入联系人',
                subtitle: '从文本快速添加多个联系人',
                onTap: _showBatchImport,
              ),
              _buildListTile(
                icon: Icons.file_download,
                title: '导出数据',
                subtitle: '导出所有联系人和互动记录',
                onTap: _exportData,
              ),
              _buildListTile(
                icon: Icons.delete_sweep,
                title: '清空所有数据',
                subtitle: '删除所有联系人和记录',
                onTap: _confirmClearData,
                danger: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 热度参数
          _buildSection(
            title: '热度参数说明',
            icon: Icons.tune,
            color: Colors.amber,
            children: [
              _buildInfoTile('衰减公式', '热度 × e^(-λ×天数)'),
              _buildInfoTile('3天衰减', '约1%'),
              _buildInfoTile('半年后', '衰减速度减半'),
              _buildInfoTile('热度底线', '1%（不会归零）'),
              _buildInfoTile('热度上限', '200%（挚友级别）'),
            ],
          ),
          const SizedBox(height: 20),

          // 互动增益说明
          _buildSection(
            title: '互动增益规则',
            icon: Icons.trending_up,
            color: Colors.green,
            children: [
              _buildInfoTile('日常互动', '+3%'),
              _buildInfoTile('对方主动', '+5%'),
              _buildInfoTile('付费交易', '+5%（上限）'),
              _buildInfoTile('帮助TA', '+8%'),
              _buildInfoTile('深度交流', '+10%'),
              _buildInfoTile('送礼物', '+10%'),
              _buildInfoTile('线下见面', '+15%'),
            ],
          ),
          const SizedBox(height: 20),

          // 资源消耗说明
          _buildSection(
            title: '资源消耗折算',
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
            children: [
              _buildInfoTile('金钱', '每100元 = -1%热度'),
              _buildInfoTile('时间', '每小时 = -0.5%热度'),
              _buildInfoTile('精力', '每1点 = -1%热度'),
              _buildInfoTile('人情', '每1点 = -2%热度'),
            ],
          ),
          const SizedBox(height: 20),

          // 关于
          _buildSection(
            title: '关于',
            icon: Icons.info_outline,
            color: Colors.grey,
            children: [
              _buildInfoTile('版本', '1.0.0'),
              _buildInfoTile('设计理念', '量化人际关系，提醒主动维护'),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.red : Colors.white.withAlpha(180)),
      title: Text(
        title,
        style: TextStyle(color: danger ? Colors.red : Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withAlpha(50),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showBatchImport() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('批量导入联系人', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每行一个，支持格式：\n'
                '• 姓名（默认热度1%）\n'
                '• 姓名+50%（指定初始热度）',
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '张三\n李四+50%\n王五+80%',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lines = controller.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              
              if (lines.isEmpty) return;

              int added = 0;
              for (final line in lines) {
                String name;
                double heat = 1.0;
                
                // 解析格式：姓名+50% 或 姓名+50
                final heatMatch = RegExp(r'^(.+?)\+(\d+)%?$').firstMatch(line);
                if (heatMatch != null) {
                  name = heatMatch.group(1)!.trim();
                  heat = double.tryParse(heatMatch.group(2)!) ?? 1.0;
                  // 确保热度在合理范围
                  heat = heat.clamp(1.0, 200.0);
                } else {
                  name = line;
                }
                
                if (name.isEmpty) continue;
                
                final contact = Contact(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + added.toString(),
                  name: name,
                  heat: heat,
                );
                await StorageService.addContact(contact);
                added++;
              }

              widget.onDataChanged();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已添加 $added 个联系人'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    final contacts = await StorageService.loadContacts();
    final buffer = StringBuffer();
    buffer.writeln('=== 关系热度数据导出 ===\n');
    
    for (final c in contacts) {
      buffer.writeln('【${c.name}】热度: ${c.heat.toStringAsFixed(1)}%');
      buffer.writeln('  互动次数: ${c.interactions.length}');
      buffer.writeln('  资源投入: ${c.totalResourceCost.toStringAsFixed(1)}');
      if (c.interactions.isNotEmpty) {
        buffer.writeln('  最近互动:');
        for (final i in c.interactions.reversed.take(3)) {
          buffer.writeln('    - ${i.time.month}/${i.time.day}: ${i.content}');
        }
      }
      buffer.writeln('');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('导出数据', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('清空所有数据', style: TextStyle(color: Colors.red)),
        content: Text(
          '此操作将删除所有联系人和互动记录，且不可恢复。确定要继续吗？',
          style: TextStyle(color: Colors.white.withAlpha(180)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await StorageService.clearAll();
              widget.onDataChanged();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('数据已清空'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('确认清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    
    // 如果已有key，先获取它
    QianwenService.getApiKey().then((key) {
      if (key != null) {
        controller.text = key;
      }
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('配置通义千问 API', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请输入阿里云通义千问的API Key\n'
              '获取地址：dashscope.console.aliyun.com',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'sk-xxxxxxxxxxxxxxxx',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.key, color: Colors.purple),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入API Key')),
                );
                return;
              }
              await QianwenService.saveApiKey(key);
              Navigator.pop(context);
              _checkApiKey();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API Key 已保存'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _testApiConnection() async {
    setState(() => _isTestingApi = true);
    
    final result = await QianwenService.testConnectionWithDetails();
    final success = result.startsWith('连接成功');
    
    setState(() => _isTestingApi = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _confirmRemoveApiKey() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('清除API Key', style: TextStyle(color: Colors.red)),
        content: Text(
          '确定要删除已保存的API Key吗？删除后将使用本地规则分析日记。',
          style: TextStyle(color: Colors.white.withAlpha(180)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await QianwenService.removeApiKey();
              Navigator.pop(context);
              _checkApiKey();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API Key 已删除'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('确认删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
