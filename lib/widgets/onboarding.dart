import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 新手引导服务
class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// 检查是否需要显示新手引导
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingCompleteKey) ?? false);
  }

  /// 标记新手引导已完成
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// 重置新手引导状态（用于测试）
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
  }
}

/// 新手引导页面
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: Icons.local_fire_department,
      iconColor: Colors.orange,
      title: '欢迎使用青云',
      description: '用"热度"量化你的人际关系\n让每段关系都有迹可循',
      highlight: '关系热度可视化管理',
    ),
    OnboardingItem(
      icon: Icons.add_circle_outline,
      iconColor: Colors.cyan,
      title: '记录互动',
      description: '点击底部按钮快速记录互动\n支持多种互动类型和资源消耗追踪',
      highlight: '每次互动自动更新热度',
    ),
    OnboardingItem(
      icon: Icons.book_outlined,
      iconColor: Colors.amber,
      title: '写日记',
      description: 'AI自动分析日记内容\n识别人物、互动和情绪',
      highlight: '智能提取人际关系信息',
    ),
    OnboardingItem(
      icon: Icons.warning_amber,
      iconColor: Colors.redAccent,
      title: '关系预警',
      description: '热度低于30%的关系会被标记\n提醒你该联系老朋友了',
      highlight: '不让重要的人被遗忘',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // 引导内容
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildPage(_items[index]),
              ),
            ),
            // 页面指示器
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _items[index].iconColor
                          : Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _currentPage == _items.length - 1 ? _finish : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _items[_currentPage].iconColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _items.length - 1 ? '开始使用' : '下一步',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标容器
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  item.iconColor.withAlpha(100),
                  item.iconColor.withAlpha(30),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: item.iconColor.withAlpha(80),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 60,
              color: item.iconColor,
            ),
          ),
          const SizedBox(height: 48),
          // 标题
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 描述
          Text(
            item.description,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 高亮提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: item.iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.iconColor.withAlpha(50)),
            ),
            child: Text(
              item.highlight,
              style: TextStyle(
                color: item.iconColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finish() async {
    await OnboardingService.completeOnboarding();
    widget.onComplete();
  }
}

/// 引导项数据模型
class OnboardingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String highlight;

  OnboardingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.highlight,
  });
}
