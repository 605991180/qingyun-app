import 'dart:math';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';

class HeatRing extends StatelessWidget {
  final List<Contact> contacts;
  final Function(Contact)? onContactTap;

  const HeatRing({
    super.key,
    required this.contacts,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            const Text(
              '暂无联系人',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮添加第一个联系人',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size / 2, size / 2);
        final radius = size * 0.38;

        // 按热度排序显示
        final sortedContacts = List<Contact>.from(contacts)
          ..sort((a, b) => b.heat.compareTo(a.heat));

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // 背景装饰环
              Center(
                child: Container(
                  width: radius * 2.2,
                  height: radius * 2.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: radius * 1.6,
                  height: radius * 1.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(15),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // 中心显示总人数
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${contacts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '位联系人',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 联系人节点
              ...List.generate(min(sortedContacts.length, 12), (index) {
                final contact = sortedContacts[index];
                final angle = (2 * pi / min(sortedContacts.length, 12)) * index - pi / 2;
                final nodeRadius = 28.0 + (contact.heat / 10).clamp(0, 10);
                final x = center.dx + radius * cos(angle) - nodeRadius;
                final y = center.dy + radius * sin(angle) - nodeRadius;
                final color = Color(HeatCalculator.getHeatColorValue(contact.heat));

                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTap: () => onContactTap?.call(contact),
                    child: Container(
                      width: nodeRadius * 2,
                      height: nodeRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withAlpha(200),
                            color.withAlpha(100),
                          ],
                        ),
                        border: Border.all(color: color, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha((contact.heat * 1.5).toInt().clamp(50, 200)),
                            blurRadius: contact.heat / 5,
                            spreadRadius: contact.heat / 15,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            contact.name.length > 2
                                ? contact.name.substring(0, 2)
                                : contact.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${contact.heat.toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
