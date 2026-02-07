import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'ai_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nickname = '青云用户';
  String _signature = '量化人际，青云直上';
  int _avatarIndex = 0;
  bool _isLoading = true;
  
  // 预设头像列表
  static const List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.sentiment_very_satisfied,
    Icons.psychology,
    Icons.emoji_emotions,
    Icons.star,
    Icons.favorite,
    Icons.diamond,
  ];
  
  static const List<Color> _avatarColors = [
    Colors.cyan,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('user_nickname') ?? '青云用户';
      _signature = prefs.getString('user_signature') ?? '量化人际，青云直上';
      _avatarIndex = prefs.getInt('user_avatar_index') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', _nickname);
    await prefs.setString('user_signature', _signature);
    await prefs.setInt('user_avatar_index', _avatarIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : CustomScrollView(
              slivers: [
                // 自定义AppBar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: const Color(0xFF16213E),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _avatarColors[_avatarIndex].withAlpha(80),
                            const Color(0xFF16213E),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _showAvatarPicker,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _avatarColors[_avatarIndex].withAlpha(200),
                                      _avatarColors[_avatarIndex].withAlpha(100),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(50),
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  _avatarIcons[_avatarIndex],
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _editNickname,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _nickname,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white.withAlpha(100),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: _editSignature,
                              child: Text(
                                _signature,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 内容列表
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 功能入口
                        _buildSectionCard(
                          title: '功能设置',
                          icon: Icons.settings,
                          color: Colors.cyan,
                          children: [
                            _buildMenuItem(
                              icon: Icons.psychology,
                              title: 'AI模型设置',
                              subtitle: '配置大语言模型API',
                              color: Colors.purple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AISettingsPage()),
                              ),
                            ),
                            _buildMenuItem(
                              icon: Icons.tune,
                              title: '数据管理',
                              subtitle: '导入导出、清除数据',
                              color: Colors.orange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(onDataChanged: () {}),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 关于
                        _buildSectionCard(
                          title: '关于',
                          icon: Icons.info_outline,
                          color: Colors.grey,
                          children: [
                            _buildMenuItem(
                              icon: Icons.verified,
                              title: '版本信息',
                              subtitle: '青云 v1.3',
                              color: Colors.green,
                              onTap: _showVersionInfo,
                            ),
                            _buildMenuItem(
                              icon: Icons.description,
                              title: '设计理念',
                              subtitle: '量化人际关系，提醒主动维护',
                              color: Colors.amber,
                              onTap: _showAbout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withAlpha(50)),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择头像',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _avatarIcons.length,
              itemBuilder: (context, index) {
                final isSelected = index == _avatarIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _avatarIndex = index);
                    _saveProfile();
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColors[index].withAlpha(isSelected ? 150 : 50),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Icon(
                      _avatarIcons[index],
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _editNickname() {
    final controller = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('修改昵称', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: '请输入昵称',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _nickname = name);
                _saveProfile();
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _editSignature() {
    final controller = TextEditingController(text: _signature);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('修改签名', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '请输入个性签名',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final sig = controller.text.trim();
              if (sig.isNotEmpty) {
                setState(() => _signature = sig);
                _saveProfile();
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.cyan),
            SizedBox(width: 8),
            Text('青云', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionItem('当前版本', 'v1.3'),
            _buildVersionItem('更新日期', '2026-02-07'),
            const SizedBox(height: 12),
            const Text(
              '更新内容：',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• 修复API连接问题\n• 设置移至"我的"页面\n• 新增仕农工商分类\n• 支持自定义部门/行业',
              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
            ),
          ],
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

  Widget _buildVersionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withAlpha(150))),
          Text(value, style: const TextStyle(color: Colors.cyan)),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('设计理念', style: TextStyle(color: Colors.white)),
        content: Text(
          '青云App致力于帮助用户量化人际关系，通过科学的热度计算模型，'
          '提醒用户主动维护重要的人际关系。\n\n'
          '核心功能：\n'
          '• 关系热度追踪\n'
          '• 智能日记分析\n'
          '• 人脉资源管理\n'
          '• 数据统计可视化\n\n'
          '愿青云助你人际通达，青云直上！',
          style: TextStyle(color: Colors.white.withAlpha(180), height: 1.5),
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
}
