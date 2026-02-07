import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/heat_calculator.dart';

class WarningList extends StatelessWidget {
  final List<Contact> contacts;
  final Function(Contact)? onContactTap;

  const WarningList({
    super.key,
    required this.contacts,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final warnings = contacts
        .where((c) => HeatCalculator.needsWarning(c))
        .toList()
      ..sort((a, b) => a.heat.compareTo(b.heat));

    if (warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.withAlpha(200), size: 20),
            const SizedBox(width: 12),
            Text(
              '所有关系状态良好',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: warnings.length,
      itemBuilder: (context, index) {
        final contact = warnings[index];
        final color = Color(HeatCalculator.getHeatColorValue(contact.heat));
        final daysSinceContact =
            DateTime.now().difference(contact.lastInteraction).inDays;
        final warningMsg = HeatCalculator.getWarningMessage(contact);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: ListTile(
            onTap: () => onContactTap?.call(contact),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withAlpha(150), color.withAlpha(80)],
                ),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$daysSinceContact天未联系 · ${HeatCalculator.getHeatLevel(contact.heat)}',
                  style: TextStyle(color: color, fontSize: 12),
                ),
                if (warningMsg != null)
                  Text(
                    warningMsg,
                    style: TextStyle(
                      color: Colors.orange.withAlpha(200),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${contact.heat.toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Icon(Icons.keyboard_arrow_right, color: color.withAlpha(150), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
