import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

/// Class times arrive as "2026-11-21 06:00:00" (or occasionally a bare "06:00 AM").
DateTime? parseClassTime(dynamic raw) => DateTime.tryParse('${raw ?? ''}'.replaceFirst(' ', 'T'));

String formatClassTime(dynamic raw) {
  final t = parseClassTime(raw);
  if (t == null) return '${raw ?? ''}';
  return DateFormat('EEE d MMM • HH:mm').format(t);
}

String formatDayHeader(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return DateFormat('EEEE d MMMM').format(d);
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.lime, fontSize: 17, fontWeight: FontWeight.bold))),
          if (trailing != null) trailing!,
        ]),
      );
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoCard(this.text, {super.key, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(borderOpacity: 0.1),
        child: Row(children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
      );
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.cloud_off, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Offline — showing saved data. Pull down to refresh.', style: TextStyle(color: Colors.amber, fontSize: 12))),
        ]),
      );
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppColors.lime)));
}
