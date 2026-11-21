import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/local_db.dart';
import '../services/step_tracker.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../theme.dart';

/// Steps, water and daily goals. All data is stored on the phone; only one small
/// summary row per day is backed up to the gym server (optional).
class ActivityScreen extends StatefulWidget {
  final int userId;
  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final tracker = StepTracker.instance;
  int _range = 7;
  List<DailyActivity> _history = [];
  bool _syncEnabled = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    tracker.addListener(_reloadHistory);
    tracker.start(widget.userId);
    _reloadHistory();
    StorageService.getSyncActivity().then((v) => mounted ? setState(() => _syncEnabled = v) : null);
  }

  @override
  void dispose() {
    tracker.removeListener(_reloadHistory);
    super.dispose();
  }

  Future<void> _reloadHistory() async {
    final h = await LocalDb.history(widget.userId, _range,
        stepGoal: await StorageService.getStepGoal(), waterGoal: await StorageService.getWaterGoal());
    if (mounted) setState(() => _history = h);
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final n = await SyncService.syncPending(widget.userId);
    if (!mounted) return;
    setState(() => _syncing = false);
    showMessage(context, n < 0 ? 'Offline — your activity is saved on this phone and will sync later.' : 'Activity backed up ($n day${n == 1 ? '' : 's'} sent).',
        error: n < 0);
  }

  Future<void> _editGoals() async {
    final stepsC = TextEditingController(text: '${tracker.today.stepGoal}');
    final waterC = TextEditingController(text: '${tracker.today.waterGoal}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily goals', style: TextStyle(color: AppColors.lime)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: stepsC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Steps per day')),
          const SizedBox(height: 12),
          TextField(controller: waterC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Glasses of water per day')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final s = int.tryParse(stepsC.text) ?? 10000;
    final w = int.tryParse(waterC.text) ?? 8;
    await tracker.setGoals(stepGoal: s.clamp(500, 100000), waterGoal: w.clamp(1, 30));
  }

  Future<void> _editSteps() async {
    final c = TextEditingController(text: '${tracker.today.steps}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Today's steps", style: TextStyle(color: AppColors.lime)),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Steps', helperText: 'Use this if your phone has no step sensor, or to correct the count.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) await tracker.setSteps((int.tryParse(c.text) ?? 0).clamp(0, 200000));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [IconButton(icon: const Icon(Icons.flag_outlined), tooltip: 'Daily goals', onPressed: _editGoals)],
      ),
      body: ListenableBuilder(
        listenable: tracker,
        builder: (context, _) {
          final t = tracker.today;
          return RefreshIndicator(
            onRefresh: () async {
              await tracker.reloadToday();
              await _reloadHistory();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statusBanner(),
                _stepsRing(t),
                const SizedBox(height: 16),
                _waterCard(t),
                const SizedBox(height: 16),
                _historyCard(),
                const SizedBox(height: 16),
                _syncCard(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBanner() {
    String? text;
    Widget? action;
    switch (tracker.status) {
      case StepStatus.permissionDenied:
        text = 'Allow "Physical activity" access so the app can count your steps.';
        action = const TextButton(onPressed: openAppSettings, child: Text('Open settings'));
      case StepStatus.unavailable:
        text = 'This phone has no step sensor. You can enter your steps manually.';
        action = TextButton(onPressed: _editSteps, child: const Text('Enter steps'));
      case StepStatus.unsupported:
        text = 'Automatic step counting works on Android and iPhone. You can enter steps manually.';
        action = TextButton(onPressed: _editSteps, child: const Text('Enter steps'));
      case StepStatus.idle:
      case StepStatus.active:
        return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: cardDecoration(border: Colors.amber, borderOpacity: 0.6),
      child: Row(children: [
        const Icon(Icons.directions_walk, color: Colors.amber),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        action,
      ]),
    );
  }

  Widget _stepsRing(DailyActivity t) {
    final progress = t.stepGoal == 0 ? 0.0 : (t.steps / t.stepGoal).clamp(0.0, 1.0);
    final fmt = NumberFormat.decimalPattern();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(children: [
        GestureDetector(
          onLongPress: _editSteps,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white10,
                  color: progress >= 1 ? Colors.amber : AppColors.lime,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(progress >= 1 ? Icons.emoji_events : Icons.directions_walk, color: progress >= 1 ? Colors.amber : AppColors.lime, size: 30),
                Text(fmt.format(t.steps), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('of ${fmt.format(t.stepGoal)} steps', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('${t.kilometres.toStringAsFixed(2)} km', 'Distance'),
          _stat('${t.calories} kcal', 'Burned'),
          _stat('${(progress * 100).round()}%', 'Goal'),
          _stat('${goalStreak(_history)} 🔥', 'Day streak'),
        ]),
        if (tracker.status == StepStatus.active)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Counting with your phone sensor • long-press the ring to correct', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
      ]),
    );
  }

  Widget _stat(String value, String label) => Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]);

  Widget _waterCard(DailyActivity t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(border: AppColors.water),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.water_drop, color: AppColors.water),
          const SizedBox(width: 8),
          const Text('Hydration', style: TextStyle(color: AppColors.water, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Text('${t.water} / ${t.waterGoal} glasses', style: const TextStyle(color: Colors.white70)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < math.max(t.waterGoal, t.water); i++)
            Icon(i < t.water ? Icons.local_drink : Icons.local_drink_outlined, color: i < t.water ? AppColors.water : Colors.white24, size: 26),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton.outlined(onPressed: t.water > 0 ? () => tracker.setWater(t.water - 1) : null, icon: const Icon(Icons.remove)),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.water, foregroundColor: AppColors.background),
            onPressed: () => tracker.setWater(t.water + 1),
            icon: const Icon(Icons.add),
            label: const Text('Glass'),
          ),
        ]),
      ]),
    );
  }

  Widget _historyCard() {
    final goal = _history.isEmpty ? 10000 : _history.last.stepGoal;
    final total = _history.fold<int>(0, (s, d) => s + d.steps);
    final best = _history.fold<int>(0, (s, d) => math.max(s, d.steps));
    final maxY = math.max(goal, best) * 1.15;
    final fmt = NumberFormat.compact();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('History', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [ButtonSegment(value: 7, label: Text('7 days')), ButtonSegment(value: 30, label: Text('30 days'))],
            selected: {_range},
            onSelectionChanged: (s) {
              setState(() => _range = s.first);
              _reloadHistory();
            },
          ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(fmt.format(total), 'Total'),
          _stat(fmt.format(_history.isEmpty ? 0 : total ~/ _history.length), 'Daily avg'),
          _stat(fmt.format(best), 'Best day'),
          _stat('${_history.where((d) => d.steps >= d.stepGoal && d.stepGoal > 0).length}', 'Goals hit'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _history.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.lime))
              : BarChart(BarChartData(
                  maxY: maxY <= 0 ? 1 : maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(y: goal.toDouble(), color: Colors.amber.withValues(alpha: 0.7), strokeWidth: 1, dashArray: [4, 4]),
                  ]),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${DateFormat('EEE d MMM').format(DateTime.parse(_history[group.x].day))}\n${NumberFormat.decimalPattern().format(rod.toY.round())} steps',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _history.length) return const SizedBox.shrink();
                          if (_range == 30 && i % 5 != 4) return const SizedBox.shrink();
                          final d = DateTime.parse(_history[i].day);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_range == 7 ? DateFormat('E').format(d) : DateFormat('d/M').format(d),
                                style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < _history.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: _history[i].steps.toDouble(),
                          width: _range == 7 ? 18 : 6,
                          borderRadius: BorderRadius.circular(4),
                          color: _history[i].steps >= _history[i].stepGoal ? Colors.amber : AppColors.lime,
                        ),
                      ]),
                  ],
                )),
        ),
      ]),
    );
  }

  Widget _syncCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(borderOpacity: 0.15),
      child: Column(children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.lime,
          title: const Text('Back up daily totals to the gym', style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text(
            'Your full history stays on this phone. When on, only one line per day (steps + water) is sent, so your coach can follow your progress and you can restore it on a new phone.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: _syncEnabled,
          onChanged: (v) async {
            await StorageService.setSyncActivity(v);
            setState(() => _syncEnabled = v);
            if (v) _syncNow();
          },
        ),
        if (_syncEnabled)
          Row(children: [
            ValueListenableBuilder<DateTime?>(
              valueListenable: SyncService.lastSync,
              builder: (_, t, __) => Text(t == null ? 'Not synced this session' : 'Last sync ${DateFormat.Hm().format(t)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Sync now'),
            ),
          ]),
      ]),
    );
  }
}
