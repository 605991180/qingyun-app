import 'package:flutter/material.dart';
import '../models/contact_resource.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  Map<ResourceCategory, List<ContactResource>> _groupedResources = {};
  List<Contact> _contacts = [];
  bool _isLoading = true;
  ResourceCategory? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final grouped = await StorageService.getResourcesGroupedByCategory();
    final contacts = await StorageService.loadContacts();
    setState(() {
      _groupedResources = grouped;
      _contacts = contacts;
      _isLoading = false;
    });
  }

  int get _totalResources {
    int count = 0;
    for (var list in _groupedResources.values) {
      count += list.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('人脉资源'),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddResourceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _totalResources == 0
              ? _buildEmptyState()
              : _buildResourceList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.white.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            '暂无资源记录',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '通过日记记录或手动添加人脉资源',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddResourceDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('添加资源', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 统计卡片
        _buildStatsCard(),
        const SizedBox(height: 20),
        
        // 按类别显示资源
        ...ResourceCategory.values.map((category) {
          final resources = _groupedResources[category] ?? [];
          if (resources.isEmpty) return const SizedBox.shrink();
          return _buildCategoryCard(category, resources);
        }),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总资源数', '$_totalResources', Colors.amber, Icons.folder_special),
              _buildStatItem('涉及人数', '${_getUniqueContactCount()}', Colors.cyan, Icons.people),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ResourceCategory.values.take(3).map((cat) {
              final count = _groupedResources[cat]?.length ?? 0;
              return _buildMiniStat(
                ResourceCategoryHelper.getIcon(cat),
                count.toString(),
                Color(ResourceCategoryHelper.getColor(cat)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ResourceCategory.values.skip(3).map((cat) {
              final count = _groupedResources[cat]?.length ?? 0;
              return _buildMiniStat(
                ResourceCategoryHelper.getIcon(cat),
                count.toString(),
                Color(ResourceCategoryHelper.getColor(cat)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String emoji, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getUniqueContactCount() {
    final contactIds = <String>{};
    for (var list in _groupedResources.values) {
      for (var resource in list) {
        contactIds.add(resource.contactId);
      }
    }
    return contactIds.length;
  }

  Widget _buildCategoryCard(ResourceCategory category, List<ContactResource> resources) {
    final color = Color(ResourceCategoryHelper.getColor(category));
    final isExpanded = _expandedCategory == category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          // 类别标题
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ResourceCategoryHelper.getIcon(category),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ResourceCategoryHelper.getLabel(category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${resources.length}个资源 · ${_getCategoryContactCount(resources)}人',
                          style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white.withAlpha(100),
                  ),
                ],
              ),
            ),
          ),
          // 展开的资源列表
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: resources.map((resource) => _buildResourceItem(resource, color)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  int _getCategoryContactCount(List<ContactResource> resources) {
    return resources.map((r) => r.contactId).toSet().length;
  }

  Widget _buildResourceItem(ContactResource resource, Color color) {
    return Dismissible(
      key: Key(resource.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withAlpha(50),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) async {
        await StorageService.deleteContactResource(resource.id);
        _loadData();
      },
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              resource.contactName.isNotEmpty ? resource.contactName[0] : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          resource.contactName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          resource.description,
          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
        ),
      ),
    );
  }

  void _showAddResourceDialog() {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加联系人')),
      );
      return;
    }

    Contact? selectedContact;
    ResourceCategory selectedCategory = ResourceCategory.social;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('添加人脉资源', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 选择联系人
                DropdownButtonFormField<Contact>(
                  dropdownColor: const Color(0xFF16213E),
                  decoration: const InputDecoration(
                    labelText: '联系人',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: _contacts.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedContact = v),
                ),
                const SizedBox(height: 16),
                // 选择类别
                DropdownButtonFormField<ResourceCategory>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF16213E),
                  decoration: const InputDecoration(
                    labelText: '资源类别',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ResourceCategory.values.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(ResourceCategoryHelper.getIcon(cat)),
                        const SizedBox(width: 8),
                        Text(ResourceCategoryHelper.getLabel(cat)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                // 描述
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '资源描述',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: '例如：在银行工作，可以帮忙办贷款',
                    hintStyle: TextStyle(color: Colors.grey),
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
                if (selectedContact == null || descController.text.isEmpty) {
                  return;
                }
                final resource = ContactResource(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  contactId: selectedContact!.id,
                  contactName: selectedContact!.name,
                  category: selectedCategory,
                  description: descController.text,
                );
                await StorageService.addContactResource(resource);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
