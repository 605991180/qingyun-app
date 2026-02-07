import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import 'diary_edit_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  List<Diary> _diaries = [];
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final diaries = await StorageService.loadDiaries();
    final contacts = await StorageService.loadContacts();
    diaries.sort((a, b) => b.date.compareTo(a.date)); // 按日期倒序
    setState(() {
      _diaries = diaries;
      _contacts = contacts;
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
            Icon(Icons.book, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('我的日记'),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _diaries.isEmpty
              ? _buildEmptyState()
              : _buildDiaryList(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 快捷语音记录按钮
          FloatingActionButton.small(
            heroTag: 'voice',
            onPressed: _quickVoiceRecord,
            backgroundColor: Colors.green,
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          // 写日记按钮
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: _addDiary,
            backgroundColor: Colors.amber,
            child: const Icon(Icons.edit, color: Colors.white),
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
          Icon(Icons.book_outlined, size: 80, color: Colors.white.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            '还没有日记',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始记录',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    // 按月份分组
    final Map<String, List<Diary>> grouped = {};
    for (var diary in _diaries) {
      final key = '${diary.date.year}年${diary.date.month}月';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(diary);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final month = grouped.keys.elementAt(index);
        final monthDiaries = grouped[month]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                month,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...monthDiaries.map((diary) => _buildDiaryCard(diary)),
          ],
        );
      },
    );
  }

  Widget _buildDiaryCard(Diary diary) {
    final moodEmoji = diary.mood != null ? MoodType.getEmoji(diary.mood!) : '📝';
    final moodColor = diary.mood != null 
        ? Color(MoodType.getColor(diary.mood!)) 
        : Colors.grey;
    
    // 获取关联的联系人
    final mentionedContacts = _contacts
        .where((c) => diary.mentionedContactIds.contains(c.id))
        .toList();

    return GestureDetector(
      onTap: () => _editDiary(diary),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: moodColor.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${diary.date.month}月${diary.date.day}日 ${_getWeekday(diary.date)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (diary.mood != null)
                        Text(
                          diary.mood!,
                          style: TextStyle(color: moodColor, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withAlpha(50)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diary.content.length > 100 
                  ? '${diary.content.substring(0, 100)}...' 
                  : diary.content,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (mentionedContacts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mentionedContacts.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.cyan),
                      const SizedBox(width: 4),
                      Text(
                        c.name,
                        style: const TextStyle(color: Colors.cyan, fontSize: 12),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  void _addDiary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditPage(contacts: _contacts),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _editDiary(Diary diary) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditPage(diary: diary, contacts: _contacts),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _quickVoiceRecord() {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '快捷记录',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '使用语音输入法快速记录',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, height: 1.5),
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: '点击这里，使用语音输入法快速记录...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入内容')),
                          );
                          return;
                        }
                        
                        // 查找今天的日记
                        final today = DateTime.now();
                        final todayStart = DateTime(today.year, today.month, today.day);
                        final existingDiary = _diaries.firstWhere(
                          (d) => d.date.year == todayStart.year && 
                                 d.date.month == todayStart.month && 
                                 d.date.day == todayStart.day,
                          orElse: () => Diary(
                            id: '',
                            date: todayStart,
                            content: '',
                          ),
                        );
                        
                        final timeStr = '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
                        
                        if (existingDiary.id.isNotEmpty) {
                          // 追加到今天的日记
                          final updatedDiary = Diary(
                            id: existingDiary.id,
                            date: existingDiary.date,
                            content: '${existingDiary.content}\n\n[$timeStr] $text',
                            mood: existingDiary.mood,
                            mentionedContactIds: existingDiary.mentionedContactIds,
                            createdAt: existingDiary.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          await StorageService.updateDiary(updatedDiary);
                        } else {
                          // 创建新日记
                          final newDiary = Diary(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            date: todayStart,
                            content: '[$timeStr] $text',
                          );
                          await StorageService.addDiary(newDiary);
                        }
                        
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已记录'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('保存到今日日记'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
