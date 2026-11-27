import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_db.dart';
import 'storage_service.dart';
import 'sync_service.dart';

enum StepStatus { idle, active, permissionDenied, unavailable, unsupported }

/// Converts raw pedometer readings into "steps taken since the last reading".
///
/// On both platforms the `pedometer` plugin reports a cumulative count since the phone
/// last booted (on iOS it queries CMPedometer from the boot date), so every reading is
/// compared with the last saved one. Steps taken while the app was closed are still
/// counted: the next reading includes them. The very first reading is only a baseline.
///
/// A reading lower than the previous one:
/// * Android: the phone rebooted, so the new value is all new steps.
/// * iOS: either a reboot or CMPedometer dropping data older than 7 days. The two can't
///   be told apart, so the reading only becomes the new baseline (never double-counts).
@visibleForTesting
class StepMath {
  static const maxPlausibleDelta = 100000;

  static int delta({required int? previous, required int current, required bool dropMeansReboot}) {
    if (current < 0 || previous == null) return 0;
    final d = current >= previous ? current - previous : (dropMeansReboot ? current : 0);
    return d > maxPlausibleDelta ? 0 : d;
  }
}

/// Live step counting from the phone's motion sensor, stored day by day in [LocalDb].
class StepTracker extends ChangeNotifier {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  int? _userId;
  StepStatus status = StepStatus.idle;
  DailyActivity today = DailyActivity(day: dayKey(DateTime.now()));

  StreamSubscription<StepCount>? _sub;
  Future<void> _queue = Future.value();

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> start(int userId) async {
    if (_userId == userId && _sub != null) return;
    await stop();
    _userId = userId;
    await reloadToday();

    if (!_isMobile) {
      _setStatus(StepStatus.unsupported);
      return;
    }
    final permission = defaultTargetPlatform == TargetPlatform.android ? Permission.activityRecognition : Permission.sensors;
    var granted = await permission.isGranted;
    if (!granted) granted = (await permission.request()).isGranted;
    if (!granted) {
      _setStatus(StepStatus.permissionDenied);
      return;
    }

    _sub = Pedometer.stepCountStream.listen(
      (event) => _queue = _queue.then((_) => _onReading(userId, event.steps)),
      onError: (_) => _setStatus(StepStatus.unavailable),
      cancelOnError: true,
    );
    _setStatus(StepStatus.active);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _userId = null;
    status = StepStatus.idle;
  }

  /// Re-reads today's row (also rolls over to a new day after midnight).
  Future<void> reloadToday() async {
    final uid = _userId;
    if (uid == null) return;
    today = await LocalDb.getDay(uid, dayKey(DateTime.now()),
        stepGoal: await StorageService.getStepGoal(), waterGoal: await StorageService.getWaterGoal());
    notifyListeners();
  }

  Future<void> _onReading(int userId, int raw) async {
    if (_userId != userId) return;
    final saved = await StorageService.getStepCounter();
    // A reading recorded for another account on this phone is only a baseline.
    final previous = saved.owner == userId ? saved.value : null;
    final d = StepMath.delta(previous: previous, current: raw, dropMeansReboot: !_isIos);
    await StorageService.saveStepCounter(raw, userId);
    if (status != StepStatus.active) _setStatus(StepStatus.active);
    if (d <= 0) return;
    today = await LocalDb.addSteps(userId, dayKey(DateTime.now()),
        d, stepGoal: await StorageService.getStepGoal(), waterGoal: await StorageService.getWaterGoal());
    notifyListeners();
    SyncService.scheduleSync(userId);
  }

  // ----------------------------------------------------- manual adjustments

  Future<void> setWater(int glasses) => _edit((uid, g) => LocalDb.setWater(uid, today.day, glasses, stepGoal: g.$1, waterGoal: g.$2));

  /// For phones without a step sensor, or to correct the count.
  Future<void> setSteps(int steps) => _edit((uid, g) => LocalDb.setSteps(uid, today.day, steps, stepGoal: g.$1, waterGoal: g.$2));

  Future<void> setGoals({required int stepGoal, required int waterGoal}) async {
    await StorageService.saveGoals(stepGoal: stepGoal, waterGoal: waterGoal);
    await _edit((uid, _) => LocalDb.setGoals(uid, today.day, stepGoal: stepGoal, waterGoal: waterGoal));
  }

  Future<void> _edit(Future<DailyActivity> Function(int uid, (int, int) goals) change) async {
    final uid = _userId;
    if (uid == null) return;
    if (today.day != dayKey(DateTime.now())) await reloadToday();
    final goals = (await StorageService.getStepGoal(), await StorageService.getWaterGoal());
    today = await change(uid, goals);
    notifyListeners();
    SyncService.scheduleSync(uid);
  }

  void _setStatus(StepStatus s) {
    status = s;
    notifyListeners();
  }
}
