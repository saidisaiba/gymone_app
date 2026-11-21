import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Class schedule. Members can book and cancel; coaches and admins see attendance numbers.
class ScheduleScreen extends StatefulWidget {
  final UserModel user;
  const ScheduleScreen({super.key, required this.user});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _classes = [];
  Map<String, int> _bookingByClass = {}; // class_id -> booking_id
  bool _loading = true;
  bool _offline = false;
  bool _showPast = false;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classes = await ApiService.getClasses();
    var offline = ApiService.lastResultFromCache;
    final bookings = <String, int>{};
    if (widget.user.isMember) {
      for (final b in await ApiService.getUserBookings()) {
        if (b is Map) bookings['${b['class_id']}'] = int.tryParse('${b['id']}') ?? 0;
      }
      offline = offline || ApiService.lastResultFromCache;
    }
    if (!mounted) return;
    setState(() {
      _classes = classes.whereType<Map>().map((c) => Map<String, dynamic>.from(c)).toList()
        ..sort((a, b) => '${a['class_time']}'.compareTo('${b['class_time']}'));
      _bookingByClass = bookings;
      _offline = offline;
      _loading = false;
    });
  }

  Future<void> _book(Map<String, dynamic> c) async {
    final id = '${c['id']}';
    setState(() => _busy.add(id));
    final ok = await ApiService.bookClass(id);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    showMessage(context, ok ? 'Your place is reserved. See you at the gym! 🏋️' : ApiService.lastError, error: !ok);
    _load();
  }

  Future<void> _cancel(Map<String, dynamic> c) async {
    final id = '${c['id']}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('Free your spot in ${c['title'] ?? 'this class'} (${formatClassTime(c['class_time'])}) for someone else?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy.add(id));
    final ok = await ApiService.cancelBooking(_bookingByClass[id] ?? 0);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    showMessage(context, ok ? 'Booking cancelled.' : ApiService.lastError, error: !ok);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visible = _classes.where((c) {
      final t = parseClassTime(c['class_time']);
      return _showPast || t == null || t.isAfter(now.subtract(const Duration(hours: 1)));
    }).toList();

    final rows = <Widget>[];
    String? lastHeader;
    for (final c in visible) {
      final t = parseClassTime(c['class_time']);
      final header = t == null ? 'Classes' : formatDayHeader(t);
      if (header != lastHeader) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(header, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ));
        lastHeader = header;
      }
      rows.add(_classCard(c));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.isCoach ? 'My Classes' : 'Class Schedule'),
        actions: [
          IconButton(
            tooltip: _showPast ? 'Hide past classes' : 'Show past classes',
            icon: Icon(_showPast ? Icons.history_toggle_off : Icons.history),
            onPressed: () => setState(() => _showPast = !_showPast),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.lime,
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [Loading()])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_offline) const OfflineBanner(),
                  if (visible.isEmpty)
                    InfoCard(ApiService.lastError.isNotEmpty && !_offline ? ApiService.lastError : 'No upcoming classes scheduled.')
                  else
                    ...rows,
                ],
              ),
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> c) {
    final id = '${c['id']}';
    final booked = _bookingByClass.containsKey(id);
    final capacity = int.tryParse('${c['capacity'] ?? ''}');
    final count = int.tryParse('${c['booked_count'] ?? ''}');
    final spots = int.tryParse('${c['available_spots'] ?? ''}') ?? (capacity != null && count != null ? capacity - count : null);
    final full = c['is_full'] == true || c['is_full'] == 1 || (spots != null && spots <= 0);
    final t = parseClassTime(c['class_time']);
    final past = t != null && t.isBefore(DateTime.now());
    final coach = c['coach_name'] ?? c['coach'];

    Widget? action;
    if (widget.user.isMember && !past) {
      if (_busy.contains(id)) {
        action = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime));
      } else if (booked) {
        action = OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
          onPressed: _offline ? null : () => _cancel(c),
          child: const Text('Cancel'),
        );
      } else {
        action = ElevatedButton(onPressed: full || _offline ? null : () => _book(c), child: Text(full ? 'Full' : 'Book'));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(borderOpacity: booked ? 0.9 : 0.25),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text('${c['title'] ?? c['name'] ?? 'CrossFit Class'}',
                    style: TextStyle(color: past ? Colors.grey : AppColors.lime, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (booked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.lime, size: 16),
              ],
            ]),
            const SizedBox(height: 4),
            Text(t == null ? '${c['class_time'] ?? ''}' : formatClassTime(c['class_time']).split('• ').last,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (coach != null && '$coach'.isNotEmpty) Text('Coach: $coach', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (spots != null && capacity != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: capacity == 0 ? 1 : ((capacity - spots) / capacity).clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      color: full ? AppColors.danger : AppColors.lime,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(full ? 'Full' : '$spots of $capacity spots left',
                      style: TextStyle(color: full ? AppColors.danger : Colors.white54, fontSize: 11)),
                ]),
              ),
          ]),
        ),
        if (action != null) ...[const SizedBox(width: 12), action],
      ]),
    );
  }
}
