import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/local_db.dart';
import '../theme.dart';

/// Personal training diary: WOD results and personal records (PRs).
/// Stored only on this phone — nothing is uploaded, so it costs no server storage.
class WorkoutLogScreen extends StatefulWidget {
  final int userId;
  final String? prefillTitle;
  const WorkoutLogScreen({super.key, required this.userId, this.prefillTitle});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  List<WorkoutEntry> _workouts = [];
  List<PersonalRecord> _records = [];
  bool _loading = true;

  static const commonLifts = [
    'Back Squat', 'Front Squat', 'Deadlift', 'Clean & Jerk', 'Snatch', 'Bench Press', 'Strict Press', 'Push Press', 'Overhead Squat', 'Clean',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.prefillTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addWorkout(title: widget.prefillTitle));
    }
  }

  Future<void> _load() async {
    final w = await LocalDb.workouts(widget.userId);
    final r = await LocalDb.bestRecords(widget.userId);
    if (mounted) {
      setState(() {
        _workouts = w;
        _records = r;
        _loading = false;
      });
    }
  }

  Future<void> _addWorkout({String? title}) async {
    final titleC = TextEditingController(text: title ?? '');
    final scoreC = TextEditingController();
    final notesC = TextEditingController();
    var rx = true;
    var date = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Log a workout', style: TextStyle(color: AppColors.lime)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Workout (e.g. "Fran" or today\'s WOD)')),
              const SizedBox(height: 10),
              TextField(controller: scoreC, decoration: const InputDecoration(labelText: 'Score / time / rounds', hintText: '4:35 or 12 rds + 5')),
              const SizedBox(height: 10),
              TextField(controller: notesC, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (weights, scaling, feeling)')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rx (as prescribed)'),
                value: rx,
                onChanged: (v) => setD(() => rx = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: AppColors.lime),
                title: Text(DateFormat('EEE d MMM yyyy').format(date)),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, firstDate: DateTime(2015), lastDate: DateTime.now(), initialDate: date);
                  if (d != null) setD(() => date = d);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, titleC.text.trim().isNotEmpty), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await LocalDb.addWorkout(
      widget.userId,
      WorkoutEntry(day: dayKey(date), title: titleC.text.trim(), score: scoreC.text.trim(), notes: notesC.text.trim(), rx: rx),
    );
    _load();
  }

  Future<void> _addRecord({String? movement}) async {
    final moveC = TextEditingController(text: movement ?? '');
    final valueC = TextEditingController();
    var unit = 'kg';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Record a lift / PR', style: TextStyle(color: AppColors.lime)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: movement ?? ''),
                optionsBuilder: (v) => commonLifts.where((l) => l.toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (s) => moveC.text = s,
                fieldViewBuilder: (context, c, focus, onSubmit) {
                  c.addListener(() => moveC.text = c.text);
                  return TextField(controller: c, focusNode: focus, decoration: const InputDecoration(labelText: 'Movement'));
                },
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: valueC,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: unit,
                  items: const ['kg', 'lb', 'reps', 'sec', 'm', 'cal']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (u) => setD(() => unit = u ?? 'kg'),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final value = double.tryParse(valueC.text.replaceAll(',', '.'));
    if (ok != true || moveC.text.trim().isEmpty || value == null) return;
    final isPr = await LocalDb.addRecord(widget.userId, PersonalRecord(movement: moveC.text.trim(), value: value, unit: unit, day: dayKey(DateTime.now())));
    if (!mounted) return;
    showMessage(context, isPr ? 'New personal record! 🏆' : 'Saved. Your best is still higher — keep pushing!');
    _load();
  }

  Future<void> _showRecordHistory(PersonalRecord best) async {
    final history = await LocalDb.recordHistory(widget.userId, best.movement);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(best.movement, style: const TextStyle(color: AppColors.lime, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Best: ${_fmt(best.value)} ${best.unit} • ${history.length} entries', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          if (history.length > 1)
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < history.length; i++) FlSpot(i.toDouble(), history[i].value)],
                    color: AppColors.lime,
                    barWidth: 3,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              )),
            ),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await LocalDb.deleteRecordsFor(widget.userId, best.movement);
                _load();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              label: const Text('Delete all', style: TextStyle(color: AppColors.danger)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addRecord(movement: best.movement);
              },
              child: const Text('Add attempt'),
            ),
          ]),
        ]),
      ),
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Training Log'),
            bottom: const TabBar(
              indicatorColor: AppColors.lime,
              labelColor: AppColors.lime,
              tabs: [Tab(text: 'Workouts'), Tab(text: 'Personal Records')],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.lime,
            foregroundColor: AppColors.background,
            onPressed: () => DefaultTabController.of(context).index == 0 ? _addWorkout() : _addRecord(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.lime))
              : TabBarView(children: [_workoutList(), _recordList()]),
        );
      }),
    );
  }

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
        ),
      );

  Widget _workoutList() {
    if (_workouts.isEmpty) return _empty('No workouts logged yet.\nTap "Add" after class to record your score.\nYour log is private and stays on this phone.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _workouts.length,
      itemBuilder: (context, i) {
        final w = _workouts[i];
        return Dismissible(
          key: ValueKey('w${w.id}'),
          direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: AppColors.danger)),
          onDismissed: (_) async {
            await LocalDb.deleteWorkout(widget.userId, w.id!);
            _load();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: cardDecoration(borderOpacity: 0.2),
            child: ListTile(
              title: Text(w.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                [DateFormat('EEE d MMM').format(DateTime.parse(w.day)), if (w.notes.isNotEmpty) w.notes].join(' • '),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(w.score.isEmpty ? '—' : w.score, style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold)),
                Text(w.rx ? 'Rx' : 'Scaled', style: TextStyle(color: w.rx ? Colors.amber : Colors.grey, fontSize: 11)),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _recordList() {
    if (_records.isEmpty) return _empty('No personal records yet.\nTrack your 1RM lifts and benchmark results to see your progress.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _records.length,
      itemBuilder: (context, i) {
        final r = _records[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: cardDecoration(borderOpacity: 0.2),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(r.movement, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Set on ${DateFormat('d MMM yyyy').format(DateTime.parse(r.day))}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            trailing: Text('${_fmt(r.value)} ${r.unit}', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 16)),
            onTap: () => _showRecordHistory(r),
          ),
        );
      },
    );
  }
}
