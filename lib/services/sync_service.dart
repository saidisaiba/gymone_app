import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'local_db.dart';
import 'storage_service.dart';

/// Uploads the compact daily activity summary (steps + water per day) to the server.
///
/// Data is always written to the phone first; uploads happen in the background, are
/// debounced so a walk doesn't trigger hundreds of requests, and are retried later
/// when the phone was offline.
class SyncService {
  static Timer? _debounce;
  static bool _running = false;
  static final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  static void scheduleSync(int userId, {Duration delay = const Duration(minutes: 2)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () => syncPending(userId));
  }

  /// Returns the number of days uploaded, or -1 if the server could not be reached.
  static Future<int> syncPending(int userId) async {
    if (_running || !await StorageService.getSyncActivity()) return 0;
    _running = true;
    var uploaded = 0;
    try {
      for (final day in await LocalDb.unsynced(userId)) {
        if (!await ApiService.saveDailyActivity(day)) {
          return ApiService.lastFailureWasNetwork ? -1 : uploaded;
        }
        await LocalDb.markSynced(userId, day.day, day.updatedAt);
        uploaded++;
      }
      lastSync.value = DateTime.now();
      return uploaded;
    } catch (_) {
      return uploaded;
    } finally {
      _running = false;
    }
  }

  /// Pulls the server's daily summaries into the phone (useful after changing phones).
  static Future<void> restoreFromServer(int userId) async {
    try {
      for (final d in await ApiService.getActivityHistory()) {
        await LocalDb.importServerDay(userId, d);
      }
    } catch (_) {/* best effort */}
  }

  static void cancel() => _debounce?.cancel();
}
