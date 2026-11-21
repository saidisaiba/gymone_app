import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_session.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/step_tracker.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';
import '../widgets/membership_banner.dart';
import 'activity_screen.dart';
import 'schedule_screen.dart';
import 'trainers_screen.dart';
import 'website_screen.dart';
import 'wod_timer_screen.dart';
import 'workout_log_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  final UserModel user;
  final bool startedOffline;
  const ClientDashboardScreen({super.key, required this.user, this.startedOffline = false});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  late UserModel _user = widget.user;
  Map<String, dynamic>? _wod;
  List<dynamic> _bookings = [];
  List<dynamic> _announcements = [];
  List<dynamic> _birthdays = [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _offline = widget.startedOffline;
    _refresh();
  }

  Future<void> _refresh() async {
    var offline = false;
    final fresh = await ApiService.me();
    offline |= ApiService.lastFailureWasNetwork;
    final wod = await ApiService.getTodayWod();
    final bookings = await ApiService.getUserBookings();
    offline |= ApiService.lastResultFromCache;
    final ann = await ApiService.getAnnouncements();
    final bdays = await ApiService.getBirthdays();
    if (!mounted) return;
    setState(() {
      if (fresh != null) _user = fresh;
      _wod = wod;
      _bookings = bookings;
      _announcements = ann;
      _birthdays = bdays;
      _offline = offline;
      _loading = false;
    });
  }

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) => _refresh());

  Future<void> _renewMembership() async {
    final phoneC = TextEditingController(text: _user.phoneNumber);
    final refC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: AppColors.lime),
            SizedBox(width: 10),
            Text(
              'MoMo Payment',
              style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'After paying by Mobile Money, enter the phone number you paid with and the transaction ID from the MoMo SMS. The gym team will confirm your payment and activate your membership.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'MoMo phone number',
                  hintText: '+2507…',
                  prefixIcon: Icon(Icons.phone, color: AppColors.lime),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refC,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID (from SMS)',
                  prefixIcon: Icon(Icons.receipt, color: AppColors.lime),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, phoneC.text.trim().isNotEmpty), child: const Text('Submit Payment')),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ApiService.pay(userId: _user.id.toString(), phone: phoneC.text.trim(), reference: refC.text.trim());
    if (!mounted) return;
    // Payments are confirmed by the gym team, so show the server's own message.
    showMessage(context, result?['message']?.toString() ?? ApiService.lastError, error: result == null);
    if (result != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings.whereType<Map>().where((b) {
      final t = parseClassTime(b['class_time']);
      return t == null || t.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
    }).toList()..sort((a, b) => '${a['class_time']}'.compareTo('${b['class_time']}'));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  Text(
                    _user.name,
                    style: const TextStyle(color: AppColors.lime, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: () => signOut())],
      ),
      body: RefreshIndicator(
        color: AppColors.lime,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_offline) const OfflineBanner(),
            MembershipBanner(isActive: _user.isActive, expiryDate: _user.expiryDate, plan: _user.membershipType, onRenew: _renewMembership),
            const SizedBox(height: 16),
            _stepsCard(),
            const SizedBox(height: 16),
            _wodCard(),
            const SizedBox(height: 24),
            SectionTitle(
              'My upcoming classes',
              trailing: TextButton(
                onPressed: () => _open(ScheduleScreen(user: _user)),
                child: const Text('Book a class'),
              ),
            ),
            if (_loading)
              const Loading()
            else if (upcoming.isEmpty)
              const InfoCard('No classes booked. Tap "Book a class" to reserve your spot!')
            else
              for (final b in upcoming.take(3))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: cardDecoration(borderOpacity: 0.4),
                  child: ListTile(
                    leading: const Icon(Icons.event_available, color: AppColors.lime),
                    title: Text(
                      '${b['title'] ?? 'CrossFit Class'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(formatClassTime(b['class_time']), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _open(ScheduleScreen(user: _user)),
                  ),
                ),
            const SizedBox(height: 16),
            _menuGrid(),
            const SizedBox(height: 24),
            const SectionTitle('📢 Box announcements'),
            if (_loading)
              const Loading()
            else if (_announcements.isEmpty)
              const InfoCard('No recent announcements.')
            else
              for (final a in _announcements.whereType<Map>().take(5)) _announcementCard(a),
            if (_birthdays.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionTitle('🥳 Upcoming birthdays'),
              SizedBox(
                height: 70,
                child: ListView(scrollDirection: Axis.horizontal, children: [for (final b in _birthdays.whereType<Map>()) _birthdayChip(b)]),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _stepsCard() {
    return ListenableBuilder(
      listenable: StepTracker.instance,
      builder: (context, _) {
        final t = StepTracker.instance.today;
        final progress = t.stepGoal == 0 ? 0.0 : (t.steps / t.stepGoal).clamp(0.0, 1.0);
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(ActivityScreen(userId: _user.id)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: Colors.white10,
                          color: progress >= 1 ? Colors.amber : AppColors.lime,
                        ),
                      ),
                      Icon(Icons.directions_walk, color: progress >= 1 ? Colors.amber : AppColors.lime),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${NumberFormat.decimalPattern().format(t.steps)} steps',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(progress * 100).round()}% of ${NumberFormat.decimalPattern().format(t.stepGoal)} • ${t.kilometres.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: AppColors.water, size: 14),
                          const SizedBox(width: 4),
                          Text('${t.water}/${t.waterGoal} glasses', style: const TextStyle(color: AppColors.water, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wodCard() {
    final wod = _wod;
    final title = wod == null ? "Today's WOD" : '${wod['title'] ?? 'WOD'}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(borderOpacity: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.lime, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's WOD",
                  style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (wod != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.lime, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _loading ? 'Loading…' : (wod == null ? "Today's WOD hasn't been posted yet. Check back later or ask your coach." : '${wod['details'] ?? ''}'),
            style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(onPressed: () => _open(const WodTimerScreen()), icon: const Icon(Icons.timer_outlined), label: const Text('Timer')),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _open(WorkoutLogScreen(userId: _user.id, prefillTitle: title)),
                icon: const Icon(Icons.edit_note),
                label: const Text('Log my score'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(Map a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: cardDecoration(borderOpacity: 0.2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign, color: AppColors.lime, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${a['title'] ?? ''}',
                style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${a['message'] ?? a['text'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
      ],
    ),
  );

  Widget _birthdayChip(Map b) {
    final date = DateTime.tryParse('${b['birthdate'] ?? ''}');
    final label = b['date'] ?? (date == null ? '' : DateFormat('d MMM').format(date));
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b['name'] ?? ''}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.cake, size: 12, color: AppColors.lime),
              const SizedBox(width: 4),
              Text(
                '$label',
                style: const TextStyle(color: AppColors.lime, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuGrid() {
    final items = <(String, IconData, Widget)>[
      ('Schedule', Icons.calendar_month, ScheduleScreen(user: _user)),
      ('Activity', Icons.directions_walk, ActivityScreen(userId: _user.id)),
      ('Training log', Icons.emoji_events_outlined, WorkoutLogScreen(userId: _user.id)),
      ('WOD timer', Icons.timer_outlined, const WodTimerScreen()),
      ('Trainers', Icons.sports, const TrainersScreen()),
      ('About the box', Icons.info_outline, const WebsiteScreen()),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final (title, icon, screen) in items)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(screen),
            child: Container(
              decoration: cardDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: AppColors.lime),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
