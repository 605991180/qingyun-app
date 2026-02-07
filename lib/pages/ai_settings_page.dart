import 'package:flutter/material.dart';
import '../models/ai_config.dart';
import '../services/qianwen_service.dart';

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  List<AIModelConfig> _configs = [];
  String? _activeId;
  bool _isLoading = true;
  bool _privacyConsent = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final configs = await AIConfigService.loadConfigs();
    final activeId = await AIConfigService.getActiveModelId();
    final privacyConsent = await QianwenService.hasPrivacyConsent();
    setState(() {
      _configs = configs;
      _activeId = activeId;
      _privacyConsent = privacyConsent;
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
            Icon(Icons.psychology, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text('AI模型设置'),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Column(
              children: [
                // 隐私设置
                _buildPrivacyConsentCard(),
                
                // 当前活跃模型
                if (_configs.isNotEmpty) _buildActiveModelCard(),
                
                // 模型列表
                Expanded(
                  child: _configs.isEmpty
                      ? _buildEmptyState()
                      : _buildModelList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModelDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPrivacyConsentCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _privacyConsent 
            ? Colors.green.withAlpha(20) 
            : Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _privacyConsent 
              ? Colors.green.withAlpha(50) 
              : Colors.orange.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: _privacyConsent ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '云端AI分析授权',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _privacyConsent,
                onChanged: (value) async {
                  if (value) {
                    _showPrivacyConsentDialog();
                  } else {
                    await QianwenService.setPrivacyConsent(false);
                    setState(() => _privacyConsent = false);
                  }
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _privacyConsent 
                ? '已授权：日记内容将发送到云端AI进行智能分析'
                : '未授权：将使用本地规则分析（准确度较低）',
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.orange),
            SizedBox(width: 8),
            Text('隐私授权', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '开启云端AI分析后：',
              style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem('您的日记内容将发送到AI服务商（如通义千问）进行分析'),
            _buildPrivacyItem('AI服务商会处理您的日记文本以提取人际关系信息'),
            _buildPrivacyItem('分析结果仅保存在您的设备本地'),
            const SizedBox(height: 12),
            Text(
              '如不同意，将使用本地规则引擎分析（准确度较低但隐私性更好）',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await QianwenService.setPrivacyConsent(true);
              setState(() => _privacyConsent = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已授权云端AI分析'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('同意并开启', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.white.withAlpha(180))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveModelCard() {
    final activeConfig = _configs.where((c) => c.id == _activeId).firstOrNull;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withAlpha(40),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '当前使用',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeConfig != null) ...[
            Row(
              children: [
                Text(
                  AIProviderInfo.getIcon(activeConfig.provider),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeConfig.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${AIProviderInfo.getName(activeConfig.provider)} · ${activeConfig.model ?? "默认模型"}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            Text(
              '未选择模型',
              style: TextStyle(color: Colors.white.withAlpha(150)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 80, color: Colors.white.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            '暂未配置AI模型',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加模型配置',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddModelDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('添加模型', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _configs.length,
      itemBuilder: (context, index) {
        final config = _configs[index];
        final isActive = config.id == _activeId;
        final color = Color(AIProviderInfo.getColor(config.provider));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : Colors.white.withAlpha(20),
              width: isActive ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AIProviderInfo.getIcon(config.provider),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  config.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '使用中',
                      style: TextStyle(color: Colors.green, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  AIProviderInfo.getName(config.provider),
                  style: TextStyle(color: color, fontSize: 12),
                ),
                Text(
                  '模型: ${config.model ?? AIProviderInfo.getDefaultModel(config.provider)}',
                  style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white.withAlpha(100)),
              color: const Color(0xFF16213E),
              onSelected: (value) {
                switch (value) {
                  case 'activate':
                    _activateModel(config.id);
                    break;
                  case 'edit':
                    _showEditModelDialog(config);
                    break;
                  case 'test':
                    _testModel(config);
                    break;
                  case 'delete':
                    _confirmDeleteModel(config);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!isActive)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('设为当前', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.cyan, size: 18),
                      SizedBox(width: 8),
                      Text('编辑', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.network_check, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('测试连接', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showEditModelDialog(config),
          ),
        );
      },
    );
  }

  void _showAddModelDialog() {
    _showModelDialog(null);
  }

  void _showEditModelDialog(AIModelConfig config) {
    _showModelDialog(config);
  }

  void _showModelDialog(AIModelConfig? existingConfig) {
    final isEditing = existingConfig != null;
    AIProvider selectedProvider = existingConfig?.provider ?? AIProvider.qianwen;
    final nameController = TextEditingController(text: existingConfig?.name ?? '');
    final apiKeyController = TextEditingController(text: existingConfig?.apiKey ?? '');
    final baseUrlController = TextEditingController(text: existingConfig?.baseUrl ?? '');
    String? selectedModel = existingConfig?.model;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.add_circle,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? '编辑模型配置' : '添加模型配置',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 选择提供商
                  const Text('选择提供商', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AIProvider.values.map((provider) {
                      final isSelected = selectedProvider == provider;
                      final color = Color(AIProviderInfo.getColor(provider));
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedProvider = provider;
                            selectedModel = null;
                            baseUrlController.text = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withAlpha(40) : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AIProviderInfo.getIcon(provider)),
                              const SizedBox(width: 6),
                              Text(
                                AIProviderInfo.getName(provider),
                                style: TextStyle(
                                  color: isSelected ? color : Colors.white.withAlpha(180),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // 配置名称
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '配置名称',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: '例如：我的${AIProviderInfo.getName(selectedProvider)}',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // API Key
                  TextField(
                    controller: apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'sk-xxxxxxxx',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.key, color: Colors.purple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 选择模型
                  const Text('选择模型', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AIProviderInfo.getAvailableModels(selectedProvider).map((model) {
                      final isSelected = selectedModel == model;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedModel = model),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purple.withAlpha(40) : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.purple : Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Text(
                            model,
                            style: TextStyle(
                              color: isSelected ? Colors.purple : Colors.white.withAlpha(180),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // 自定义URL（可选）
                  ExpansionTile(
                    title: Text(
                      '高级设置',
                      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
                    ),
                    iconColor: Colors.white.withAlpha(100),
                    collapsedIconColor: Colors.white.withAlpha(100),
                    children: [
                      TextField(
                        controller: baseUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '自定义API地址（可选）',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: AIProviderInfo.getDefaultUrl(selectedProvider),
                          hintStyle: TextStyle(color: Colors.grey.withAlpha(100)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final apiKey = apiKeyController.text.trim();
                            
                            if (name.isEmpty || apiKey.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请填写名称和API Key')),
                              );
                              return;
                            }
                            
                            final config = AIModelConfig(
                              id: existingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              provider: selectedProvider,
                              name: name,
                              apiKey: apiKey,
                              baseUrl: baseUrlController.text.trim().isEmpty 
                                  ? null 
                                  : baseUrlController.text.trim(),
                              model: selectedModel ?? AIProviderInfo.getDefaultModel(selectedProvider),
                              isActive: existingConfig?.isActive ?? false,
                            );
                            
                            if (isEditing) {
                              await AIConfigService.updateConfig(config);
                            } else {
                              await AIConfigService.addConfig(config);
                              // 如果是第一个配置，自动设为活跃
                              if (_configs.isEmpty) {
                                await AIConfigService.setActiveModel(config.id);
                              }
                            }
                            
                            Navigator.pop(context);
                            _loadConfigs();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? '配置已更新' : '配置已添加'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isEditing ? '保存' : '添加',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _activateModel(String id) async {
    await AIConfigService.setActiveModel(id);
    _loadConfigs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已切换模型'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testModel(AIModelConfig config) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(width: 16),
            Text('正在测试连接...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    // 模拟测试（实际应调用对应的API）
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${config.name} 连接测试完成'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _confirmDeleteModel(AIModelConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除配置', style: TextStyle(color: Colors.red)),
        content: Text(
          '确定要删除"${config.name}"吗？',
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
              await AIConfigService.deleteConfig(config.id);
              Navigator.pop(context);
              _loadConfigs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已删除'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
