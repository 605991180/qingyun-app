import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import '../services/heat_calculator.dart';
import '../services/qianwen_service.dart';
import '../services/ai_parser_service.dart';

class DiaryEditPage extends StatefulWidget {
  final Diary? diary;
  final List<Contact> contacts;

  const DiaryEditPage({
    super.key,
    this.diary,
    required this.contacts,
  });

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  late TextEditingController _contentController;
  late DateTime _selectedDate;
  String? _selectedMood;
  Set<String> _selectedContactIds = {};
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.diary != null;
    _contentController = TextEditingController(text: widget.diary?.content ?? '');
    _selectedDate = widget.diary?.date ?? DateTime.now();
    _selectedMood = widget.diary?.mood;
    _selectedContactIds = widget.diary?.mentionedContactIds.toSet() ?? {};
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日记' : '写日记'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除日记',
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期选择
            _buildDateSection(),
            const SizedBox(height: 20),

            // 心情选择
            _buildMoodSection(),
            const SizedBox(height: 20),

            // 日记内容
            _buildContentSection(),
            const SizedBox(height: 20),

            // 关联联系人
            _buildContactsSection(),
            const SizedBox(height: 20),

            // 快速记录互动
            if (_selectedContactIds.isNotEmpty) _buildQuickInteractionSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Semantics(
      button: true,
      label: '日期：${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日，点击修改',
      child: GestureDetector(
        onTap: _selectDate,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit, color: Colors.white.withAlpha(100), size: 18),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mood, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              const Text(
                '今天的心情',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_selectedMood != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedMood = null),
                  child: Icon(Icons.close, color: Colors.white.withAlpha(100), size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MoodType.all.map((mood) {
              final isSelected = _selectedMood == mood;
              final color = Color(MoodType.getColor(mood));
              return Semantics(
                button: true,
                selected: isSelected,
                label: '心情：$mood${isSelected ? "，已选中" : ""}',
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(40) : Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.white.withAlpha(30),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(MoodType.getEmoji(mood), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          mood,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white.withAlpha(180),
                            fontSize: 13,
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

  Widget _buildContentSection() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final textLength = _contentController.text.length;
        final isLongText = textLength > 2000;
        final isVeryLongText = textLength > 5000;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '日记内容',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // 字符计数
                  Text(
                    '$textLength 字',
                    style: TextStyle(
                      color: isVeryLongText 
                          ? Colors.orange 
                          : isLongText 
                              ? Colors.amber.withAlpha(180)
                              : Colors.white.withAlpha(100),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // 超长文本提示
              if (isLongText) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isVeryLongText 
                        ? Colors.orange.withAlpha(30) 
                        : Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVeryLongText 
                          ? Colors.orange.withAlpha(50) 
                          : Colors.amber.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVeryLongText ? Icons.warning_amber : Icons.info_outline,
                        color: isVeryLongText ? Colors.orange : Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isVeryLongText 
                              ? '文本较长，AI分析可能需要更多时间'
                              : '文本已超过2000字，建议适当精简',
                          style: TextStyle(
                            color: isVeryLongText ? Colors.orange : Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white, height: 1.6),
                maxLines: 10,
                minLines: 5,
                onChanged: (_) => setLocalState(() {}),
                decoration: InputDecoration(
                  hintText: '今天发生了什么？\n遇见了谁？\n有什么感想？',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: Colors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                '今天见了谁',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            '选择今天互动过的联系人',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (widget.contacts.isEmpty)
            Text(
              '暂无联系人，请先添加联系人',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.contacts.map((c) {
                final isSelected = _selectedContactIds.contains(c.id);
                final color = Color(HeatCalculator.getHeatColorValue(c.heat));
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${c.name}，热度${c.heat.toInt()}%${isSelected ? "，已选中" : ""}',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedContactIds.remove(c.id);
                        } else {
                          _selectedContactIds.add(c.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withAlpha(40) : Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.white.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(Icons.check, size: 16, color: Colors.white),
                          if (isSelected) const SizedBox(width: 4),
                          Text(
                            c.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withAlpha(180),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${c.heat.toInt()}%',
                          style: TextStyle(color: color, fontSize: 11),
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

  Widget _buildQuickInteractionSection() {
    final selectedContacts = widget.contacts
        .where((c) => _selectedContactIds.contains(c.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withAlpha(30),
            Colors.green.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                '快速记录互动',
                style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '保存日记时，自动为以下联系人添加一次日常互动：',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedContacts.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${c.name} +3%',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.white,
              surface: Color(0xFF16213E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    final diary = Diary(
      id: widget.diary?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      content: _contentController.text.trim(),
      mood: _selectedMood,
      mentionedContactIds: _selectedContactIds.toList(),
      createdAt: widget.diary?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      await StorageService.updateDiary(diary);
    } else {
      await StorageService.addDiary(diary);
    }

    // 为选中的联系人添加互动记录
    if (_selectedContactIds.isNotEmpty) {
      final contacts = await StorageService.loadContacts();
      for (final contactId in _selectedContactIds) {
        final contact = contacts.firstWhere(
          (c) => c.id == contactId,
          orElse: () => Contact(id: '', name: ''),
        );
        if (contact.id.isNotEmpty) {
          final interaction = Interaction(
            id: DateTime.now().millisecondsSinceEpoch.toString() + contactId,
            time: _selectedDate,
            content: '日记记录：${_contentController.text.length > 30 ? '${_contentController.text.substring(0, 30)}...' : _contentController.text}',
            type: InteractionType.normal,
          );
          contact.interactions.add(interaction);
          contact.heat = HeatCalculator.calculateNewHeat(contact, interaction);
          contact.lastInteraction = _selectedDate;
          await StorageService.updateContact(contact);
        }
      }
    }

    // 使用AI分析日记（异步，不阻塞保存）
    _runAiAnalysis();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '日记已更新' : '日记已保存'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  /// 运行AI分析
  Future<void> _runAiAnalysis() async {
    try {
      final contacts = await StorageService.loadContacts();
      final content = _contentController.text.trim();
      
      // 使用云端AI分析（如果配置了API Key），否则使用本地分析
      final result = await QianwenService.analyzeDiary(content, contacts);
      
      // 如果分析出了有效内容，应用结果
      if (result.hasContent) {
        await AIParserService.applyAnalysisResult(result);
      }
    } catch (e) {
      // 分析失败不影响日记保存
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除日记', style: TextStyle(color: Colors.red)),
        content: Text(
          '确定要删除这篇日记吗？',
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
              await StorageService.deleteDiary(widget.diary!.id);
              if (mounted) {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context, true); // 返回列表页
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
