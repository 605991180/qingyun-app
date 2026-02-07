import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';
import '../services/storage_service.dart';
import 'add_interaction_page.dart';

class ContactDetailPage extends StatefulWidget {
  final Contact contact;
  final Function() onUpdate;

  const ContactDetailPage({
    super.key,
    required this.contact,
    required this.onUpdate,
  });

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late Contact _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Color get _heatColor => Color(HeatCalculator.getHeatColorValue(_contact.heat));

  @override
  Widget build(BuildContext context) {
    final daysSinceContact = DateTime.now().difference(_contact.lastInteraction).inDays;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(_contact.name),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editContact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 热度卡片
            _buildHeatCard(daysSinceContact),
            const SizedBox(height: 20),
            
            // 资源消耗卡片
            _buildResourceCard(),
            const SizedBox(height: 20),
            
            // 互动记录
            _buildInteractionList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInteraction,
        backgroundColor: _heatColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('记录互动', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeatCard(int daysSinceContact) {
    final warningMsg = HeatCalculator.getWarningMessage(_contact);
    final daysToWarning = HeatCalculator.predictDaysToHeat(_contact, 30);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _heatColor.withAlpha(40),
            _heatColor.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _heatColor.withAlpha(100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 头像
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_heatColor, _heatColor.withAlpha(150)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _heatColor.withAlpha(150),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _contact.name.isNotEmpty ? _contact.name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_contact.heat.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _heatColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _heatColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            HeatCalculator.getHeatLevel(_contact.heat),
                            style: TextStyle(color: _heatColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysSinceContact天未联系',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warningMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMsg,
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 统计信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('互动次数', '${_contact.interactions.length}'),
              _buildStatItem('资源投入', '${_contact.totalResourceCost.toStringAsFixed(1)}'),
              _buildStatItem('预警倒计时', '$daysToWarning天'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResourceCard() {
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
              const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                '资源消耗',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _addResource,
                child: const Text('+ 添加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_contact.resources.isEmpty)
            Text(
              '暂无资源消耗记录',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
            )
          else
            ...(_contact.resources.reversed.take(5).map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.typeLabel,
                      style: const TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.description,
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                    ),
                  ),
                  Text(
                    '-${r.cost.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ),
            ))),
        ],
      ),
    );
  }

  Widget _buildInteractionList() {
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
              const Icon(Icons.history, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                '互动记录',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '共${_contact.interactions.length}次',
                style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_contact.interactions.isEmpty)
            Text(
              '暂无互动记录',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
            )
          else
            ...(_contact.interactions.reversed.take(10).map((i) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        '${i.time.month}/${i.time.day}',
                        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                      ),
                      Text(
                        '${i.time.hour}:${i.time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _heatColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                i.typeLabel,
                                style: TextStyle(color: _heatColor, fontSize: 10),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${i.heatGain.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          i.content,
                          style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))),
        ],
      ),
    );
  }

  void _addInteraction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddInteractionPage(contact: _contact),
      ),
    );
    if (result == true) {
      widget.onUpdate();
      setState(() {});
    }
  }

  void _addResource() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    ResourceType selectedType = ResourceType.money;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('添加资源消耗', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ResourceType>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF16213E),
                  decoration: const InputDecoration(
                    labelText: '资源类型',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ResourceType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_getResourceTypeLabel(t)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '描述',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: '例如：请吃饭、送礼物',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: amountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '数量',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: _getAmountHint(selectedType),
                    hintStyle: const TextStyle(color: Colors.grey),
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
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  final resource = Resource(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    time: DateTime.now(),
                    type: selectedType,
                    description: descController.text.isEmpty ? _getResourceTypeLabel(selectedType) : descController.text,
                    amount: amount,
                  );
                  _contact.resources.add(resource);
                  StorageService.updateContact(_contact);
                  widget.onUpdate();
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  String _getResourceTypeLabel(ResourceType type) {
    switch (type) {
      case ResourceType.money: return '金钱';
      case ResourceType.time: return '时间';
      case ResourceType.energy: return '精力';
      case ResourceType.favor: return '人情';
    }
  }

  String _getAmountHint(ResourceType type) {
    switch (type) {
      case ResourceType.money: return '金额（元）';
      case ResourceType.time: return '时长（小时）';
      case ResourceType.energy: return '消耗程度（1-10）';
      case ResourceType.favor: return '人情大小（1-10）';
    }
  }

  void _editContact() {
    final nameController = TextEditingController(text: _contact.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('编辑联系人', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '姓名',
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _contact.name = nameController.text.trim();
                StorageService.updateContact(_contact);
                widget.onUpdate();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除联系人', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除 ${_contact.name} 吗？所有互动记录将被清除。',
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
              await StorageService.deleteContact(_contact.id);
              widget.onUpdate();
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回上一页
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
