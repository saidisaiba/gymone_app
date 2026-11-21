import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Who is booked into which class. Coaches see their own classes; admins see all.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  bool _offline = false;
  bool _upcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService.getAllBookings();
    if (!mounted) return;
    setState(() {
      _bookings = list.whereType<Map>().map((b) => Map<String, dynamic>.from(b)).toList();
      _offline = ApiService.lastResultFromCache;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final b in _bookings) {
      final t = parseClassTime(b['class_time']);
      if (_upcomingOnly && t != null && t.isBefore(now)) continue;
      groups.putIfAbsent('${b['class_id']}', () => []).add(b);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => '${groups[a]!.first['class_time']}'.compareTo('${groups[b]!.first['class_time']}'));
    if (!_upcomingOnly) keys.setAll(0, keys.reversed.toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Attendance'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _upcomingOnly = !_upcomingOnly),
            child: Text(_upcomingOnly ? 'Show past' : 'Upcoming only'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_offline) const OfflineBanner(),
            if (_loading)
              const Loading()
            else if (keys.isEmpty)
              InfoCard(ApiService.lastError.isNotEmpty ? ApiService.lastError : 'No bookings yet.')
            else
              for (final k in keys)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: cardDecoration(),
                  child: ExpansionTile(
                    shape: const Border(),
                    iconColor: AppColors.lime,
                    title: Text('${groups[k]!.first['title'] ?? 'Class'}', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold)),
                    subtitle: Text('${formatClassTime(groups[k]!.first['class_time'])} • ${groups[k]!.length} booked',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    children: [
                      for (final b in groups[k]!)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person, color: Colors.white54),
                          title: Text('${b['user_name'] ?? 'Member #${b['user_id']}'}', style: const TextStyle(color: Colors.white)),
                          subtitle: b['user_email'] == null ? null : Text('${b['user_email']}', style: const TextStyle(color: Colors.white54)),
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
