import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymone_app/main.dart';
import 'package:gymone_app/models/user_model.dart';
import 'package:gymone_app/screens/login_screen.dart';
import 'package:gymone_app/screens/wod_timer_screen.dart';
import 'package:gymone_app/services/api_service.dart';
import 'package:gymone_app/services/local_db.dart';
import 'package:gymone_app/services/step_tracker.dart';
import 'package:gymone_app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('UserModel', () {
    test('parses string flags, nested subscription and legacy member role', () {
      final future = DateTime.now().add(const Duration(days: 10)).toIso8601String().substring(0, 10);
      final u = UserModel.fromJson({
        'id': '7',
        'name': 'Test Member',
        'email': 'member@example.com',
        'role': 'user',
        'member_number': null,
        'subscription': {'is_active': '1', 'expiry_date': future, 'membership_type': 'Monthly'},
      });
      expect(u.id, 7);
      expect(u.role, 'client');
      expect(u.serverRole, 'user');
      expect(u.isMember, isTrue);
      expect(u.isActive, isTrue);
      expect(u.membershipType, 'Monthly');
      expect(u.memberNumber, '');
    });

    test('an active flag with a past expiry date is not active', () {
      final u = UserModel.fromJson({'id': 1, 'role': 'client', 'is_active': 1, 'expiry_date': '2020-01-01'});
      expect(u.isActive, isFalse);
    });
  });

  group('StepMath', () {
    test('Android cumulative counter', () {
      expect(StepMath.delta(previous: null, current: 5000, firstInSession: true, countsFromZeroEachSession: false), 0);
      expect(StepMath.delta(previous: 5000, current: 5120, firstInSession: true, countsFromZeroEachSession: false), 120);
      // reboot resets the counter
      expect(StepMath.delta(previous: 5000, current: 40, firstInSession: false, countsFromZeroEachSession: false), 40);
      // nonsense jump is ignored
      expect(StepMath.delta(previous: 0, current: 500000, firstInSession: false, countsFromZeroEachSession: false), 0);
    });

    test('iOS counts from zero each session', () {
      expect(StepMath.delta(previous: 9000, current: 30, firstInSession: true, countsFromZeroEachSession: true), 30);
      expect(StepMath.delta(previous: 30, current: 55, firstInSession: false, countsFromZeroEachSession: true), 25);
    });
  });

  test('goalStreak skips an unfinished today', () {
    DailyActivity d(int steps) => DailyActivity(day: '2026-01-01', steps: steps, stepGoal: 1000);
    expect(goalStreak([d(1200), d(500), d(1500), d(1000), d(200)]), 2);
    expect(goalStreak([d(1200), d(1500), d(1000)]), 3);
    expect(goalStreak([d(100), d(100)]), 0);
  });

  test('WodTimerPlan', () {
    const tabata = WodTimerPlan(TimerMode.tabata);
    expect(tabata.totalSeconds, 240);
    expect(tabata.at(0).isWork, isTrue);
    expect(tabata.at(21).phase, 'REST');
    expect(tabata.at(31).round, 2);
    expect(tabata.at(240).finished, isTrue);

    const amrap = WodTimerPlan(TimerMode.amrap, minutes: 10);
    expect(amrap.at(60).display, 540);

    const emom = WodTimerPlan(TimerMode.emom, minutes: 5);
    expect(emom.at(125).round, 3);
    expect(emom.at(125).display, 55);

    expect(const WodTimerPlan(TimerMode.forTime, minutes: 0).totalSeconds, isNull);
  });

  group('ApiService', () {
    test('falls back to an older action name only on "Unknown API action"', () async {
      final called = <String>[];
      ApiService.client = MockClient((req) async {
        final action = req.url.queryParameters['action']!;
        called.add(action);
        if (action == 'get_classes') return http.Response(jsonEncode({'status': 'error', 'message': 'Unknown API action.'}), 404);
        return http.Response(jsonEncode({'status': 'success', 'classes': [{'id': 1, 'title': 'WOD'}]}), 200);
      });
      final classes = await ApiService.getClasses();
      expect(called, ['get_classes', 'schedule']);
      expect(classes, hasLength(1));
    });

    test('sends the bearer token and clears the session on 401', () async {
      await StorageService.saveToken('abc.def');
      String? auth;
      ApiService.client = MockClient((req) async {
        auth = req.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'error', 'message': 'Your session has expired. Please sign in again.'}), 401);
      });
      expect(await ApiService.me(), isNull);
      expect(auth, 'Bearer abc.def');
      expect(await StorageService.getToken(), isNull);
      expect(ApiService.lastError, contains('expired'));
    });

    test('login stores the token and reports server errors', () async {
      ApiService.client = MockClient((req) async {
        final body = jsonDecode(req.body) as Map;
        if (body['password'] == 'right-password') {
          return http.Response(jsonEncode({'status': 'success', 'token': 'tok.sig', 'user': {'id': 3, 'name': 'A', 'email': 'a@example.com', 'role': 'coach'}}), 200);
        }
        return http.Response(jsonEncode({'status': 'error', 'message': 'The email or password is incorrect.'}), 401);
      });
      expect(await ApiService.login('a@example.com', 'wrong'), isNull);
      expect(ApiService.lastError, 'The email or password is incorrect.');
      final user = await ApiService.login(' A@example.com ', 'right-password');
      expect(user?.isCoach, isTrue);
      expect(await StorageService.getToken(), 'tok.sig');
    });

    test('new members are created with the database role "user"', () async {
      Map? sent;
      ApiService.client = MockClient((req) async {
        sent = jsonDecode(req.body) as Map;
        return http.Response(jsonEncode({'status': 'success', 'user_id': 200}), 200);
      });
      expect(await ApiService.addUser({'name': 'New', 'email': 'new@example.com', 'password': 'longenough', 'role': 'client'}), isTrue);
      expect(sent?['role'], 'user');
      await ApiService.addUser({'name': 'C', 'email': 'c@example.com', 'password': 'longenough', 'role': 'coach'});
      expect(sent?['role'], 'coach');
    });

    test('no invented WOD when none is published', () async {
      ApiService.client = MockClient((req) async {
        final action = req.url.queryParameters['action'];
        if (action == 'get_today_wod') return http.Response(jsonEncode({'status': 'error', 'message': 'Unknown API action.'}), 404);
        return http.Response(jsonEncode({'status': 'success', 'announcements': [{'title': 'Welcome!', 'message': 'Hello'}]}), 200);
      });
      expect(await ApiService.getTodayWod(), isNull);
    });

    test('network failure is reported as offline', () async {
      ApiService.client = MockClient((req) async => throw http.ClientException('no route'));
      expect(await ApiService.bookClass('4'), isFalse);
      expect(ApiService.lastFailureWasNetwork, isTrue);
    });
  });

  testWidgets('login screen validates empty input', (tester) async {
    await tester.pumpWidget(const CrossFitApp(home: LoginScreen()));
    expect(find.text('CROSSFIT 1000 HILLS'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email and password.'), findsOneWidget);
  });
}
