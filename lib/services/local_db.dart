import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One day of activity for one member, stored on the device.
class DailyActivity {
  final String day; // YYYY-MM-DD
  final int steps;
  final int stepGoal;
  final int water;
  final int waterGoal;
  final int updatedAt;
  final int? syncedAt;

  const DailyActivity({
    required this.day,
    this.steps = 0,
    this.stepGoal = 10000,
    this.water = 0,
    this.waterGoal = 8,
    this.updatedAt = 0,
    this.syncedAt,
  });

  bool get needsSync => syncedAt == null || syncedAt! < updatedAt;

  /// Rough estimates (average stride ~0.76 m, ~0.04 kcal per step).
  double get kilometres => steps * 0.000762;
  int get calories => (steps * 0.04).round();

  factory DailyActivity.fromRow(Map<String, Object?> r) => DailyActivity(
        day: r['day'] as String,
        steps: r['steps'] as int? ?? 0,
        stepGoal: r['step_goal'] as int? ?? 10000,
        water: r['water'] as int? ?? 0,
        waterGoal: r['water_goal'] as int? ?? 8,
        updatedAt: r['updated_at'] as int? ?? 0,
        syncedAt: r['synced_at'] as int?,
      );
}

class WorkoutEntry {
  final int? id;
  final String day;
  final String title;
  final String score;
  final String notes;
  final bool rx;

  const WorkoutEntry({this.id, required this.day, required this.title, this.score = '', this.notes = '', this.rx = false});

  factory WorkoutEntry.fromRow(Map<String, Object?> r) => WorkoutEntry(
        id: r['id'] as int?,
        day: r['day'] as String,
        title: r['title'] as String? ?? '',
        score: r['score'] as String? ?? '',
        notes: r['notes'] as String? ?? '',
        rx: (r['rx'] as int? ?? 0) == 1,
      );
}

class PersonalRecord {
  final int? id;
  final String movement;
  final double value;
  final String unit;
  final String day;

  const PersonalRecord({this.id, required this.movement, required this.value, required this.unit, required this.day});

  factory PersonalRecord.fromRow(Map<String, Object?> r) => PersonalRecord(
        id: r['id'] as int?,
        movement: r['movement'] as String,
        value: (r['value'] as num).toDouble(),
        unit: r['unit'] as String? ?? 'kg',
        day: r['day'] as String,
      );
}

/// Consecutive days the step goal was reached, counting back from today.
/// Today only breaks the streak once it is over, so an unfinished today is skipped.
int goalStreak(List<DailyActivity> oldestFirst) {
  var streak = 0;
  for (var i = oldestFirst.length - 1; i >= 0; i--) {
    final d = oldestFirst[i];
    final met = d.steps >= d.stepGoal && d.stepGoal > 0;
    if (met) {
      streak++;
    } else if (i == oldestFirst.length - 1) {
      continue; // today, still in progress
    } else {
      break;
    }
  }
  return streak;
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// On-device SQLite database.
///
/// What lives here (and never needs server storage):
///  * full daily step / water history,
///  * the personal workout log and personal records (PRs),
///  * cached copies of server lists so the app works offline.
/// Only a compact daily summary (steps + water per day) is synced to the server.
class LocalDb {
  static Database? _db;

  static Future<Database> get db async {
    return _db ??= await openDatabase(
      p.join(await getDatabasesPath(), 'crossfit1000hills.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE daily_activity(
            user_id INTEGER NOT NULL,
            day TEXT NOT NULL,
            steps INTEGER NOT NULL DEFAULT 0,
            step_goal INTEGER NOT NULL DEFAULT 10000,
            water INTEGER NOT NULL DEFAULT 0,
            water_goal INTEGER NOT NULL DEFAULT 8,
            updated_at INTEGER NOT NULL DEFAULT 0,
            synced_at INTEGER,
            PRIMARY KEY(user_id, day))''');
        await db.execute('''
          CREATE TABLE workouts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            day TEXT NOT NULL,
            title TEXT NOT NULL,
            score TEXT,
            notes TEXT,
            rx INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL)''');
        await db.execute('''
          CREATE TABLE personal_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            movement TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT NOT NULL,
            day TEXT NOT NULL,
            created_at INTEGER NOT NULL)''');
        await db.execute('CREATE TABLE api_cache(key TEXT PRIMARY KEY, body TEXT NOT NULL, fetched_at INTEGER NOT NULL)');
      },
    );
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  // ----------------------------------------------------------- daily activity

  static Future<DailyActivity> getDay(int userId, String day, {int stepGoal = 10000, int waterGoal = 8}) async {
    final rows = await (await db).query('daily_activity', where: 'user_id=? AND day=?', whereArgs: [userId, day]);
    return rows.isEmpty ? DailyActivity(day: day, stepGoal: stepGoal, waterGoal: waterGoal) : DailyActivity.fromRow(rows.first);
  }

  static Future<DailyActivity> _upsert(int userId, String day, Map<String, Object?> Function(DailyActivity current) change,
      {int stepGoal = 10000, int waterGoal = 8}) async {
    final database = await db;
    return database.transaction((txn) async {
      final rows = await txn.query('daily_activity', where: 'user_id=? AND day=?', whereArgs: [userId, day]);
      final current = rows.isEmpty ? DailyActivity(day: day, stepGoal: stepGoal, waterGoal: waterGoal) : DailyActivity.fromRow(rows.first);
      final values = {
        'user_id': userId,
        'day': day,
        'steps': current.steps,
        'step_goal': current.stepGoal,
        'water': current.water,
        'water_goal': current.waterGoal,
        'synced_at': current.syncedAt,
        ...change(current),
        'updated_at': _now(),
      };
      await txn.insert('daily_activity', values, conflictAlgorithm: ConflictAlgorithm.replace);
      return DailyActivity.fromRow(values);
    });
  }

  static Future<DailyActivity> addSteps(int userId, String day, int delta, {int stepGoal = 10000, int waterGoal = 8}) =>
      _upsert(userId, day, (c) => {'steps': c.steps + delta}, stepGoal: stepGoal, waterGoal: waterGoal);

  static Future<DailyActivity> setSteps(int userId, String day, int steps, {int stepGoal = 10000, int waterGoal = 8}) =>
      _upsert(userId, day, (c) => {'steps': steps < 0 ? 0 : steps}, stepGoal: stepGoal, waterGoal: waterGoal);

  static Future<DailyActivity> setWater(int userId, String day, int glasses, {int stepGoal = 10000, int waterGoal = 8}) =>
      _upsert(userId, day, (c) => {'water': glasses < 0 ? 0 : glasses}, stepGoal: stepGoal, waterGoal: waterGoal);

  static Future<DailyActivity> setGoals(int userId, String day, {required int stepGoal, required int waterGoal}) =>
      _upsert(userId, day, (c) => {'step_goal': stepGoal, 'water_goal': waterGoal}, stepGoal: stepGoal, waterGoal: waterGoal);

  /// Last [days] days, oldest first, with empty days filled in.
  static Future<List<DailyActivity>> history(int userId, int days, {int stepGoal = 10000, int waterGoal = 8}) async {
    final today = DateTime.now();
    final from = dayKey(today.subtract(Duration(days: days - 1)));
    final rows = await (await db).query('daily_activity', where: 'user_id=? AND day>=?', whereArgs: [userId, from]);
    final byDay = {for (final r in rows) r['day'] as String: DailyActivity.fromRow(r)};
    return [
      for (var i = days - 1; i >= 0; i--)
        byDay[dayKey(today.subtract(Duration(days: i)))] ??
            DailyActivity(day: dayKey(today.subtract(Duration(days: i))), stepGoal: stepGoal, waterGoal: waterGoal),
    ];
  }

  static Future<List<DailyActivity>> unsynced(int userId, {int limit = 30}) async {
    final rows = await (await db).query('daily_activity',
        where: 'user_id=? AND (synced_at IS NULL OR synced_at < updated_at)', whereArgs: [userId], orderBy: 'day DESC', limit: limit);
    return rows.map(DailyActivity.fromRow).toList();
  }

  /// Marks a day as synced, unless it changed again while the upload was in flight.
  static Future<void> markSynced(int userId, String day, int updatedAtSent) async {
    await (await db).update('daily_activity', {'synced_at': _now()},
        where: 'user_id=? AND day=? AND updated_at=?', whereArgs: [userId, day, updatedAtSent]);
  }

  /// Restores days from the server (e.g. on a new phone) without overwriting newer local data.
  static Future<void> importServerDay(int userId, DailyActivity d) async {
    final database = await db;
    final rows = await database.query('daily_activity', where: 'user_id=? AND day=?', whereArgs: [userId, d.day]);
    if (rows.isNotEmpty && DailyActivity.fromRow(rows.first).steps >= d.steps) return;
    final now = _now();
    await database.insert(
      'daily_activity',
      {
        'user_id': userId,
        'day': d.day,
        'steps': d.steps,
        'step_goal': d.stepGoal,
        'water': d.water,
        'water_goal': d.waterGoal,
        'updated_at': now,
        'synced_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------- workout log

  static Future<List<WorkoutEntry>> workouts(int userId) async {
    final rows = await (await db).query('workouts', where: 'user_id=?', whereArgs: [userId], orderBy: 'day DESC, id DESC', limit: 500);
    return rows.map(WorkoutEntry.fromRow).toList();
  }

  static Future<void> addWorkout(int userId, WorkoutEntry w) async {
    await (await db).insert('workouts', {
      'user_id': userId,
      'day': w.day,
      'title': w.title,
      'score': w.score,
      'notes': w.notes,
      'rx': w.rx ? 1 : 0,
      'created_at': _now(),
    });
  }

  static Future<void> deleteWorkout(int userId, int id) async {
    await (await db).delete('workouts', where: 'user_id=? AND id=?', whereArgs: [userId, id]);
  }

  // -------------------------------------------------------- personal records

  /// Best value per movement (highest), newest first.
  static Future<List<PersonalRecord>> bestRecords(int userId) async {
    final rows = await (await db).rawQuery('''
      SELECT pr.* FROM personal_records pr
      WHERE pr.user_id = ? AND pr.id = (
        SELECT id FROM personal_records x
        WHERE x.user_id = pr.user_id AND lower(x.movement) = lower(pr.movement)
        ORDER BY x.value DESC, x.id DESC LIMIT 1)
      ORDER BY pr.day DESC''', [userId]);
    return rows.map(PersonalRecord.fromRow).toList();
  }

  static Future<List<PersonalRecord>> recordHistory(int userId, String movement) async {
    final rows = await (await db).query('personal_records',
        where: 'user_id=? AND lower(movement)=lower(?)', whereArgs: [userId, movement], orderBy: 'day ASC, id ASC');
    return rows.map(PersonalRecord.fromRow).toList();
  }

  /// Saves an attempt. Returns true if it beats the previous best.
  static Future<bool> addRecord(int userId, PersonalRecord r) async {
    final database = await db;
    final prev = await database.rawQuery(
        'SELECT MAX(value) AS best FROM personal_records WHERE user_id=? AND lower(movement)=lower(?)', [userId, r.movement]);
    final best = (prev.first['best'] as num?)?.toDouble();
    await database.insert('personal_records', {
      'user_id': userId,
      'movement': r.movement.trim(),
      'value': r.value,
      'unit': r.unit,
      'day': r.day,
      'created_at': _now(),
    });
    return best == null || r.value > best;
  }

  static Future<void> deleteRecordsFor(int userId, String movement) async {
    await (await db).delete('personal_records', where: 'user_id=? AND lower(movement)=lower(?)', whereArgs: [userId, movement]);
  }

  // ------------------------------------------------------------ offline cache

  static Future<void> putCache(String key, Object? value) async {
    await (await db).insert('api_cache', {'key': key, 'body': jsonEncode(value), 'fetched_at': _now()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<({Object? value, DateTime fetchedAt})?> getCache(String key) async {
    final rows = await (await db).query('api_cache', where: 'key=?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return (
      value: jsonDecode(rows.first['body'] as String),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(rows.first['fetched_at'] as int),
    );
  }

  /// Cached server data belongs to the signed-in account; drop it on sign-out.
  /// (Activity, workouts and PRs are kept per user id, so they survive sign-out.)
  static Future<void> clearCache() async {
    await (await db).delete('api_cache');
  }
}
