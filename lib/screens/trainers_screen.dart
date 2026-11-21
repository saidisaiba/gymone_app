import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Coaches, built from the live class schedule (so the list is always current).
class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  Map<String, List<Map>> _byCoach = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classes = await ApiService.getClasses();
    final now = DateTime.now();
    final map = <String, List<Map>>{};
    for (final c in classes.whereType<Map>()) {
      final coach = '${c['coach_name'] ?? c['coach'] ?? ''}'.trim();
      if (coach.isEmpty) continue;
      final list = map.putIfAbsent(coach, () => []);
      final t = parseClassTime(c['class_time']);
      if (t == null || t.isAfter(now)) list.add(c);
    }
    if (mounted) {
      setState(() {
        _byCoach = map;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = _byCoach.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Our Coaches')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Loading()
            else if (names.isEmpty)
              const InfoCard('Coach information will appear here once classes are assigned to coaches.')
            else
              for (final name in names)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: cardDecoration(),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lime,
                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold)),
                    subtitle: Text('${_byCoach[name]!.length} upcoming class${_byCoach[name]!.length == 1 ? '' : 'es'}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    children: [
                      for (final c in _byCoach[name]!.take(10))
                        ListTile(
                          dense: true,
                          title: Text('${c['title'] ?? 'Class'}', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(formatClassTime(c['class_time']), style: const TextStyle(color: Colors.white54)),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
