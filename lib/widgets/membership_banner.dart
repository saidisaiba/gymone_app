import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

class MembershipBanner extends StatelessWidget {
  final bool isActive;
  final String expiryDate;
  final String plan;
  final VoidCallback onRenew;

  const MembershipBanner({super.key, required this.isActive, required this.expiryDate, required this.onRenew, this.plan = ''});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.lime : AppColors.danger;
    final expiry = DateTime.tryParse(expiryDate);
    String subtitle;
    if (expiry == null) {
      subtitle = isActive ? 'Membership active' : 'No active membership';
    } else {
      final today = DateTime.now();
      final days = DateTime(expiry.year, expiry.month, expiry.day).difference(DateTime(today.year, today.month, today.day)).inDays;
      final date = DateFormat('d MMM yyyy').format(expiry);
      subtitle = days >= 0 ? 'Expires $date ($days day${days == 1 ? '' : 's'} left)' : 'Expired on $date';
    }
    final expiringSoon = isActive && expiry != null && expiry.difference(DateTime.now()).inDays < 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive ? [AppColors.surface, AppColors.surfaceHigh] : [const Color(0xFF311515), const Color(0xFF1F1313)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isActive ? (plan.isNotEmpty ? plan : 'Membership active') : 'Membership inactive',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: expiringSoon ? Colors.amber : Colors.white70, fontSize: 13)),
          ]),
        ),
        if (!isActive || expiringSoon)
          ElevatedButton.icon(
            onPressed: onRenew,
            icon: const Icon(Icons.phone_android, size: 18),
            label: const Text('MoMo Pay'),
          ),
      ]),
    );
  }
}
