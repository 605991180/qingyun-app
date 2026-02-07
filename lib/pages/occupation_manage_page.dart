import 'package:flutter/material.dart';
import '../models/occupation.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class OccupationManagePage extends StatefulWidget {
  const OccupationManagePage({super.key});

  @override
  State<OccupationManagePage> createState() => _OccupationManagePageState();
}

class _OccupationManagePageState extends State<OccupationManagePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CustomCategory> _categories = [];
  List<Contact> _contacts = [];
  List<ContactOccupation> _occupations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await OccupationService.loadCategories();
    final contacts = await StorageService.loadContacts();
    final occupations = await OccupationService.loadOccupations();
    setState(() {
      _categories = categories;
      _contacts = contacts;
      _occupations = occupations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('仕农工商管理'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: OccupationCategory.values.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(OccupationHelper.getIcon(cat)),
                  const SizedBox(width: 4),
                  Text(OccupationHelper.getName(cat)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : TabBarView(
              controller: _tabController,
              children: OccupationCategory.values.map((cat) {
                return _buildCategoryTab(cat);
              }).toList(),
            ),
    );
  }

  Widget _buildCategoryTab(OccupationCategory category) {
    final categoryItems = _categories.where((c) => c.occupation == category).toList();
    final color = Color(OccupationHelper.getColor(category));
    
    // 获取该分类下的联系人
    final categoryContactIds = _occupations
        .where((o) => o.category == category)
        .map((o) => o.contactId)
        .toList();
    final categoryContacts = _contacts.where((c) => categoryContactIds.contains(c.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Row(
              children: [
                Text(OccupationHelper.getIcon(category), style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        OccupationHelper.getFullName(category),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        OccupationHelper.getDescription(category),
                        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${categoryContacts.length}',
                      style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('人', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 分类管理（仅仕和商有子分类）
          if (category == OccupationCategory.shi || category == OccupationCategory.shang) ...[
            Row(
              children: [
                Text(
                  category == OccupationCategory.shi ? '部门分类' : '行业分类',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddCategoryDialog(category),
                  icon: Icon(Icons.add, color: color, size: 18),
                  label: Text('添加', style: TextStyle(color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (category == OccupationCategory.shi)
              _buildShiCategoryList(categoryItems, color)
            else
              _buildNormalCategoryList(categoryItems, color),
            const SizedBox(height: 20),
          ],

          // 联系人列表
          Row(
            children: [
              const Text(
                '该分类联系人',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddContactDialog(category),
                icon: Icon(Icons.person_add, color: color, size: 18),
                label: Text('添加联系人', style: TextStyle(color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (categoryContacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                '暂无联系人',
                style: TextStyle(color: Colors.white.withAlpha(100)),
              ),
            )
          else
            ...categoryContacts.map((contact) => _buildContactItem(contact, category, color)),
        ],
      ),
    );
  }

  Widget _buildShiCategoryList(List<CustomCategory> items, Color color) {
    // 按级别分组
    final Map<PoliticalLevel, List<CustomCategory>> grouped = {};
    for (var level in PoliticalLevel.values) {
      grouped[level] = items.where((c) => c.politicalLevel == level).toList();
    }

    return Column(
      children: PoliticalLevel.values.map((level) {
        final levelItems = grouped[level] ?? [];
        return ExpansionTile(
          title: Text(
            '${OccupationHelper.getLevelName(level)} (${levelItems.length})',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: levelItems.map((cat) {
                return GestureDetector(
                  onLongPress: () => _confirmDeleteCategory(cat),
                  child: Chip(
                    label: Text(cat.name, style: TextStyle(color: color, fontSize: 12)),
                    backgroundColor: color.withAlpha(20),
                    side: BorderSide(color: color.withAlpha(50)),
                    deleteIcon: Icon(Icons.close, size: 16, color: color),
                    onDeleted: () => _confirmDeleteCategory(cat),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNormalCategoryList(List<CustomCategory> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((cat) {
        return GestureDetector(
          onLongPress: () => _confirmDeleteCategory(cat),
          child: Chip(
            label: Text(cat.name, style: TextStyle(color: color, fontSize: 12)),
            backgroundColor: color.withAlpha(20),
            side: BorderSide(color: color.withAlpha(50)),
            deleteIcon: Icon(Icons.close, size: 16, color: color),
            onDeleted: () => _confirmDeleteCategory(cat),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactItem(Contact contact, OccupationCategory category, Color color) {
    final occupation = _occupations.firstWhere(
      (o) => o.contactId == contact.id,
      orElse: () => ContactOccupation(contactId: '', category: category),
    );
    
    String subtitle = '';
    if (occupation.customCategoryId != null) {
      final customCat = _categories.firstWhere(
        (c) => c.id == occupation.customCategoryId,
        orElse: () => CustomCategory(id: '', name: '', occupation: category),
      );
      if (customCat.name.isNotEmpty) {
        subtitle = customCat.name;
      }
    }
    if (occupation.detail != null && occupation.detail!.isNotEmpty) {
      subtitle = subtitle.isEmpty ? occupation.detail! : '$subtitle · ${occupation.detail}';
    }

    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withAlpha(50),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) => _removeContactFromCategory(contact.id),
      child: ListTile(
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
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12))
            : null,
        trailing: Text(
          '${contact.heat.toInt()}%',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        onTap: () => _showEditOccupationDialog(contact, category),
      ),
    );
  }

  void _showAddCategoryDialog(OccupationCategory occupation) {
    final controller = TextEditingController();
    PoliticalLevel? selectedLevel = occupation == OccupationCategory.shi 
        ? PoliticalLevel.city 
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            occupation == OccupationCategory.shi ? '添加部门' : '添加行业',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (occupation == OccupationCategory.shi) ...[
                DropdownButtonFormField<PoliticalLevel>(
                  value: selectedLevel,
                  dropdownColor: const Color(0xFF16213E),
                  decoration: const InputDecoration(
                    labelText: '级别',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: PoliticalLevel.values.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(OccupationHelper.getLevelName(level)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedLevel = v),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: occupation == OccupationCategory.shi ? '部门名称' : '行业名称',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: occupation == OccupationCategory.shi ? '例如：市公安局' : '例如：新能源汽车',
                  hintStyle: const TextStyle(color: Colors.grey),
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
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                
                final category = CustomCategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  occupation: occupation,
                  politicalLevel: selectedLevel,
                );
                await OccupationService.addCategory(category);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(CustomCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除分类', style: TextStyle(color: Colors.red)),
        content: Text(
          '确定要删除"${category.name}"吗？',
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
              await OccupationService.deleteCategory(category.id);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(OccupationCategory category) {
    // 获取未分类到该类别的联系人
    final existingIds = _occupations
        .where((o) => o.category == category)
        .map((o) => o.contactId)
        .toSet();
    final availableContacts = _contacts.where((c) => !existingIds.contains(c.id)).toList();

    if (availableContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可添加的联系人')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择联系人',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableContacts.length,
                itemBuilder: (context, index) {
                  final contact = availableContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.cyan.withAlpha(50),
                      child: Text(
                        contact.name.isNotEmpty ? contact.name[0] : '?',
                        style: const TextStyle(color: Colors.cyan),
                      ),
                    ),
                    title: Text(contact.name, style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      final occupation = ContactOccupation(
                        contactId: contact.id,
                        category: category,
                      );
                      await OccupationService.setContactOccupation(occupation);
                      Navigator.pop(context);
                      _loadData();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOccupationDialog(Contact contact, OccupationCategory category) {
    final existingOccupation = _occupations.firstWhere(
      (o) => o.contactId == contact.id,
      orElse: () => ContactOccupation(contactId: contact.id, category: category),
    );
    
    final categoryItems = _categories.where((c) => c.occupation == category).toList();
    String? selectedCategoryId = existingOccupation.customCategoryId;
    final detailController = TextEditingController(text: existingOccupation.detail ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text('设置${contact.name}的职业信息', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoryItems.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  dropdownColor: const Color(0xFF16213E),
                  decoration: InputDecoration(
                    labelText: category == OccupationCategory.shi ? '所属部门' : '所属行业',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未指定')),
                    ...categoryItems.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: detailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '详细描述（可选）',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: '例如：科长、经理...',
                  hintStyle: TextStyle(color: Colors.grey),
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
              onPressed: () async {
                final occupation = ContactOccupation(
                  contactId: contact.id,
                  category: category,
                  customCategoryId: selectedCategoryId,
                  detail: detailController.text.trim().isEmpty ? null : detailController.text.trim(),
                );
                await OccupationService.setContactOccupation(occupation);
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

  Future<void> _removeContactFromCategory(String contactId) async {
    final occupations = await OccupationService.loadOccupations();
    occupations.removeWhere((o) => o.contactId == contactId);
    await OccupationService.saveOccupations(occupations);
    _loadData();
  }
}
