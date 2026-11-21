import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

enum TimerMode { forTime, amrap, emom, tabata }

/// Pure timing logic, kept separate from the UI so it can be unit-tested.
class WodTimerPlan {
  final TimerMode mode;
  final int minutes; // AMRAP length, For Time cap (0 = no cap), EMOM rounds
  final int work; // Tabata work seconds
  final int rest; // Tabata rest seconds
  final int rounds; // Tabata rounds

  const WodTimerPlan(this.mode, {this.minutes = 12, this.work = 20, this.rest = 10, this.rounds = 8});

  /// Total length in seconds, or null when open-ended (For Time without cap).
  int? get totalSeconds => switch (mode) {
        TimerMode.forTime => minutes == 0 ? null : minutes * 60,
        TimerMode.amrap => minutes * 60,
        TimerMode.emom => minutes * 60,
        TimerMode.tabata => rounds * (work + rest),
      };

  /// What to show [elapsed] seconds after the start.
  ({String phase, int round, int display, bool isWork, bool finished}) at(int elapsed) {
    final total = totalSeconds;
    final finished = total != null && elapsed >= total;
    switch (mode) {
      case TimerMode.forTime:
        return (phase: 'FOR TIME', round: 0, display: total == null ? elapsed : elapsed.clamp(0, total), isWork: true, finished: finished);
      case TimerMode.amrap:
        return (phase: 'AMRAP', round: 0, display: (total! - elapsed).clamp(0, total), isWork: true, finished: finished);
      case TimerMode.emom:
        final round = (elapsed ~/ 60) + 1;
        return (phase: 'EMOM', round: round.clamp(1, minutes), display: finished ? 0 : 60 - elapsed % 60, isWork: true, finished: finished);
      case TimerMode.tabata:
        final cycle = work + rest;
        final round = (elapsed ~/ cycle) + 1;
        final inCycle = elapsed % cycle;
        final isWork = inCycle < work;
        return (
          phase: isWork ? 'WORK' : 'REST',
          round: round.clamp(1, rounds),
          display: finished ? 0 : (isWork ? work - inCycle : cycle - inCycle),
          isWork: isWork,
          finished: finished,
        );
    }
  }
}

/// Gym timer for class or open gym. Runs fully offline.
class WodTimerScreen extends StatefulWidget {
  const WodTimerScreen({super.key});

  @override
  State<WodTimerScreen> createState() => _WodTimerScreenState();
}

class _WodTimerScreenState extends State<WodTimerScreen> {
  TimerMode _mode = TimerMode.amrap;
  int _minutes = 12;
  int _work = 20;
  int _rest = 10;
  int _rounds = 8;

  static const _getReadySeconds = 10;
  final Stopwatch _watch = Stopwatch();
  final Stopwatch _ready = Stopwatch();
  bool _inCountdown = false;
  Timer? _ticker;
  int _lastCountdown = -1;
  String _lastPhaseKey = '';
  final List<int> _splits = [];

  WodTimerPlan get _plan => WodTimerPlan(_mode, minutes: _minutes, work: _work, rest: _rest, rounds: _rounds);
  bool get _running => _ticker != null;
  int get _elapsed => _watch.elapsed.inSeconds;
  int get _countdown => _inCountdown ? (_getReadySeconds - _ready.elapsed.inSeconds).clamp(0, _getReadySeconds) : 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_watch.elapsedMilliseconds == 0 && !_inCountdown) {
      _inCountdown = true;
      _ready
        ..reset()
        ..start();
    } else if (_inCountdown) {
      _ready.start();
    } else {
      _watch.start();
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 200), _tick);
    setState(() {});
  }

  void _tick(Timer _) {
    if (_inCountdown) {
      final c = _countdown;
      if (c != _lastCountdown) {
        _lastCountdown = c;
        if (c > 0 && c <= 3) HapticFeedback.selectionClick();
      }
      if (c == 0) {
        _inCountdown = false;
        _ready.stop();
        HapticFeedback.heavyImpact();
        _watch.start();
      }
      setState(() {});
      return;
    }
    final now = _plan.at(_elapsed);
    final phaseKey = '${now.round}-${now.isWork}';
    if (_lastPhaseKey.isNotEmpty && phaseKey != _lastPhaseKey) HapticFeedback.heavyImpact();
    _lastPhaseKey = phaseKey;
    if (now.finished) {
      _watch.stop();
      _ticker?.cancel();
      _ticker = null;
      HapticFeedback.vibrate();
    }
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    _ticker = null;
    _watch.stop();
    _ready.stop();
    setState(() {});
  }

  void _reset() {
    _pause();
    _watch.reset();
    _ready.reset();
    _inCountdown = false;
    _lastCountdown = -1;
    _lastPhaseKey = '';
    _splits.clear();
    setState(() {});
  }

  String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final started = _watch.elapsedMilliseconds > 0 || _inCountdown;
    final state = _plan.at(_elapsed);
    final color = _countdown > 0
        ? Colors.amber
        : state.finished
            ? Colors.amber
            : state.isWork
                ? AppColors.lime
                : AppColors.water;

    return Scaffold(
      appBar: AppBar(title: const Text('WOD Timer')),
      body: SafeArea(
        child: Column(children: [
          if (!started) _settings(),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_countdown > 0 ? 'GET READY' : (state.finished ? 'TIME!' : state.phase),
                    style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                FittedBox(
                  child: Text(
                    _countdown > 0 ? '$_countdown' : _mmss(state.display),
                    style: TextStyle(color: color, fontSize: 110, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                if ((_mode == TimerMode.emom || _mode == TimerMode.tabata) && started)
                  Text('Round ${state.round} / ${_mode == TimerMode.emom ? _minutes : _rounds}',
                      style: const TextStyle(color: Colors.white70, fontSize: 20)),
                if (_mode == TimerMode.forTime || _mode == TimerMode.amrap) ...[
                  if (_splits.isNotEmpty)
                    Text('${_mode == TimerMode.amrap ? 'Rounds' : 'Splits'}: ${_splits.length}', style: const TextStyle(color: Colors.white70, fontSize: 20)),
                  if (_splits.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: Text(_splits.map(_mmss).join('  •  '), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                ],
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: started ? _reset : null,
                  child: const Text('Reset'),
                ),
              ),
              if ((_mode == TimerMode.forTime || _mode == TimerMode.amrap) && _running && _countdown == 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    onPressed: () => setState(() => _splits.add(_elapsed)),
                    child: Text(_mode == TimerMode.amrap ? '+1 Round' : 'Split'),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: state.finished ? null : (_running ? _pause : _start),
                  child: Text(_running ? 'Pause' : (started ? 'Resume' : 'Start'), style: const TextStyle(fontSize: 18)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _settings() {
    Widget stepper(String label, int value, int min, int max, ValueChanged<int> onChanged, {int step = 1}) => Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          IconButton(onPressed: value - step >= min ? () => onChanged(value - step) : null, icon: const Icon(Icons.remove_circle_outline)),
          SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(onPressed: value + step <= max ? () => onChanged(value + step) : null, icon: const Icon(Icons.add_circle_outline)),
        ]);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(),
      child: Column(children: [
        SegmentedButton<TimerMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: TimerMode.forTime, label: Text('For Time')),
            ButtonSegment(value: TimerMode.amrap, label: Text('AMRAP')),
            ButtonSegment(value: TimerMode.emom, label: Text('EMOM')),
            ButtonSegment(value: TimerMode.tabata, label: Text('Tabata')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 8),
        if (_mode == TimerMode.forTime) stepper('Time cap (min, 0 = none)', _minutes, 0, 90, (v) => setState(() => _minutes = v)),
        if (_mode == TimerMode.amrap) stepper('Minutes', _minutes, 1, 90, (v) => setState(() => _minutes = v)),
        if (_mode == TimerMode.emom) stepper('Rounds (minutes)', _minutes, 1, 90, (v) => setState(() => _minutes = v)),
        if (_mode == TimerMode.tabata) ...[
          stepper('Work (sec)', _work, 5, 120, (v) => setState(() => _work = v), step: 5),
          stepper('Rest (sec)', _rest, 5, 120, (v) => setState(() => _rest = v), step: 5),
          stepper('Rounds', _rounds, 1, 30, (v) => setState(() => _rounds = v)),
        ],
      ]),
    );
  }
}
