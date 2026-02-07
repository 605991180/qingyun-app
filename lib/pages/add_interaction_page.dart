import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';
import '../services/storage_service.dart';

class AddInteractionPage extends StatefulWidget {
  final Contact? contact;
  final List<Contact>? allContacts;

  const AddInteractionPage({
    super.key,
    this.contact,
    this.allContacts,
  });

  @override
  State<AddInteractionPage> createState() => _AddInteractionPageState();
}

class _AddInteractionPageState extends State<AddInteractionPage> {
  final _contentController = TextEditingController();
  Contact? _selectedContact;
  InteractionType _selectedType = InteractionType.normal;
  bool _addResource = false;
  ResourceType _resourceType = ResourceType.money;
  final _resourceAmountController = TextEditingController();
  final _resourceDescController = TextEditingController();
  final _newContactNameController = TextEditingController();
  bool _isNewContact = false;

  @override
  void initState() {
    super.initState();
    _selectedContact = widget.contact;
    if (widget.contact == null && (widget.allContacts?.isEmpty ?? true)) {
      _isNewContact = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('记录互动'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 联系人选择
            _buildContactSection(),
            const SizedBox(height: 24),

            // 互动类型
            _buildInteractionTypeSection(),
            const SizedBox(height: 24),

            // 互动内容
            _buildContentSection(),
            const SizedBox(height: 24),

            // 资源消耗（可选）
            _buildResourceSection(),
            const SizedBox(height: 32),

            // 预览
            if (_selectedContact != null || _isNewContact) _buildPreview(),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确认保存',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
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
              Icon(Icons.person, color: Colors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                '联系人',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.contact != null)
            _buildSelectedContactChip(widget.contact!)
          else if (widget.allContacts != null && widget.allContacts!.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.allContacts!.map((c) => ChoiceChip(
                  label: Text(c.name),
                  selected: _selectedContact?.id == c.id && !_isNewContact,
                  onSelected: (selected) {
                    setState(() {
                      _selectedContact = selected ? c : null;
                      _isNewContact = false;
                    });
                  },
                  selectedColor: const Color(0xFFFF9800),
                  labelStyle: TextStyle(
                    color: _selectedContact?.id == c.id && !_isNewContact ? Colors.white : Colors.grey,
                  ),
                )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: Colors.cyan),
                  label: const Text('新建'),
                  labelStyle: TextStyle(
                    color: _isNewContact ? Colors.cyan : Colors.grey,
                  ),
                  backgroundColor: _isNewContact ? Colors.cyan.withAlpha(30) : null,
                  onPressed: () {
                    setState(() {
                      _isNewContact = true;
                      _selectedContact = null;
                    });
                  },
                ),
              ],
            ),
            if (_isNewContact) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _newContactNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '新联系人姓名',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: '输入姓名',
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
          ] else ...[
            TextField(
              controller: _newContactNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '联系人姓名',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: '输入姓名创建第一个联系人',
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
        ],
      ),
    );
  }

  Widget _buildSelectedContactChip(Contact contact) {
    final color = Color(HeatCalculator.getHeatColorValue(contact.heat));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '当前热度 ${contact.heat.toInt()}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTypeSection() {
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
              Icon(Icons.category, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                '互动类型',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InteractionType.values.map((type) {
              final isSelected = _selectedType == type;
              final heatGain = _getTypeHeatGain(type);
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.withAlpha(40) : Colors.white.withAlpha(5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.white.withAlpha(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white.withAlpha(180),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$heatGain%',
                        style: TextStyle(
                          color: Colors.greenAccent.withAlpha(isSelected ? 255 : 150),
                          fontSize: 11,
                        ),
                      ),
                    ],
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
              Icon(Icons.edit_note, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                '互动内容',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '描述这次互动的内容...\n例如：一起吃午饭聊了很久',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection() {
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
              const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                '资源消耗',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _addResource,
                onChanged: (v) => setState(() => _addResource = v),
                activeColor: Colors.purple,
              ),
            ],
          ),
          Text(
            '记录为这段关系付出的资源（可选）',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
          ),
          if (_addResource) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<ResourceType>(
              value: _resourceType,
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
              onChanged: (v) => setState(() => _resourceType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resourceAmountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '数量',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: _getAmountHint(_resourceType),
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resourceDescController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: '例如：请吃饭',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final heatGain = _getTypeHeatGain(_selectedType);
    double resourceCost = 0;
    if (_addResource) {
      final amount = double.tryParse(_resourceAmountController.text) ?? 0;
      resourceCost = Resource(
        id: '',
        time: DateTime.now(),
        type: _resourceType,
        description: '',
        amount: amount,
      ).cost;
    }
    final netGain = heatGain - resourceCost;

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
          const Text(
            '预览',
            style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPreviewItem('互动增益', '+$heatGain%', Colors.greenAccent),
              if (_addResource && resourceCost > 0)
                _buildPreviewItem('资源消耗', '-${resourceCost.toStringAsFixed(1)}%', Colors.redAccent),
              _buildPreviewItem(
                '净增益',
                '${netGain >= 0 ? '+' : ''}${netGain.toStringAsFixed(1)}%',
                netGain >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
        ),
      ],
    );
  }

  String _getTypeLabel(InteractionType type) {
    switch (type) {
      case InteractionType.normal: return '日常互动';
      case InteractionType.paidTransaction: return '付费交易';
      case InteractionType.theyInitiated: return '对方主动';
      case InteractionType.deepTalk: return '深度交流';
      case InteractionType.meetup: return '线下见面';
      case InteractionType.help: return '帮助TA';
      case InteractionType.gift: return '送礼物';
    }
  }

  double _getTypeHeatGain(InteractionType type) {
    switch (type) {
      case InteractionType.paidTransaction: return 5.0;
      case InteractionType.theyInitiated: return 5.0;
      case InteractionType.deepTalk: return 10.0;
      case InteractionType.meetup: return 15.0;
      case InteractionType.help: return 8.0;
      case InteractionType.gift: return 10.0;
      case InteractionType.normal: return 3.0;
    }
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

  void _save() async {
    // 确定联系人
    Contact contact;
    if (_selectedContact != null) {
      contact = _selectedContact!;
    } else if (_isNewContact || (widget.allContacts?.isEmpty ?? true)) {
      final name = _newContactNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入联系人姓名')),
        );
        return;
      }
      contact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        heat: 1.0, // 初识陌生人
      );
      await StorageService.addContact(contact);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择联系人')),
      );
      return;
    }

    // 创建资源消耗记录
    Resource? resource;
    if (_addResource) {
      final amount = double.tryParse(_resourceAmountController.text) ?? 0;
      if (amount > 0) {
        resource = Resource(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          time: DateTime.now(),
          type: _resourceType,
          description: _resourceDescController.text.isEmpty 
              ? _getResourceTypeLabel(_resourceType) 
              : _resourceDescController.text,
          amount: amount,
        );
        contact.resources.add(resource);
      }
    }

    // 创建互动记录
    final interaction = Interaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: DateTime.now(),
      content: _contentController.text.isEmpty ? _getTypeLabel(_selectedType) : _contentController.text,
      type: _selectedType,
    );
    contact.interactions.add(interaction);

    // 计算新热度
    contact.heat = HeatCalculator.calculateNewHeat(contact, interaction, resource: resource);
    contact.lastInteraction = DateTime.now();

    // 保存
    await StorageService.updateContact(contact);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录与 ${contact.name} 的互动'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }
}
