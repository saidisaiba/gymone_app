import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/membership_banner.dart';
import '../widgets/app_logo.dart';
import 'schedule_screen.dart';
import 'health_sync_screen.dart';
import 'trainers_screen.dart';
import 'website_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class ClientDashboardScreen extends StatefulWidget {
  final UserModel user;
  const ClientDashboardScreen({super.key, required this.user});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool isActive = false;
  String expiryDate = 'N/A';
  late Future<List<dynamic>> _announcementsFuture;
  late Future<List<dynamic>> _birthdaysFuture;
  late Future<Map<String, dynamic>?> _wodFuture;
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    isActive = widget.user.isActive;
    expiryDate = widget.user.expiryDate;
    _announcementsFuture = ApiService.getAnnouncements();
    _birthdaysFuture = ApiService.getBirthdays();
    _wodFuture = ApiService.getTodayWod();
    _bookingsFuture = ApiService.getUserBookings(widget.user.id.toString());
  }

  void _renewMembership() async {
    final phoneC = TextEditingController(text: widget.user.phoneNumber.isNotEmpty ? widget.user.phoneNumber : '+250780000000');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14221A),
        title: const Text('💳 MoMo Payment', style: TextStyle(color: Color(0xFF84CC16))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter MTN / Airtel Mobile Money Number for subscription renewal:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: phoneC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.pay(userId: widget.user.id.toString(), phone: phoneC.text);
              if (result != null && mounted) {
                setState(() {
                  isActive = result['is_active'] == 1;
                  expiryDate = result['expiry_date'];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Membership renewed successfully via MoMo! 🎉'),
                    backgroundColor: Color(0xFF84CC16),
                  ),
                );
              }
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Welcome, ${widget.user.name}',
                style: const TextStyle(color: Color(0xFF84CC16), fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF14221A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF84CC16)),
            tooltip: 'Log Off',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            MembershipBanner(isActive: isActive, expiryDate: expiryDate, onRenew: _renewMembership),
            const SizedBox(height: 20),

            // Today's Featured WOD (Dynamic from Backend API)
            FutureBuilder<Map<String, dynamic>?>(
              future: _wodFuture,
              builder: (context, snapshot) {
                final wod = snapshot.data;
                final title = wod?['title'] ?? 'AMRAP 20 mins';
                final details = wod?['details'] ?? '• 5 Pull-ups\n• 10 Push-ups\n• 15 Air Squats';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14221A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF84CC16), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("🔥 Today's Featured WOD ($title)", style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('RX / Scaled', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.replaceAll('\n', '\n'),
                        style: const TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // My Booked Classes Section
            const Text('🏋️ My Booked Classes', style: TextStyle(color: Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFF14221A), borderRadius: BorderRadius.circular(8)),
                    child: const Text('No classes booked yet. Go to Schedule & Classes to book.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  );
                }
                final bookings = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14221A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['title'] ?? 'CrossFit Class', style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Time: ${b['class_time'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const Chip(
                            label: Text('Booked ✅', style: TextStyle(fontSize: 11, color: Color(0xFF0C1611))),
                            backgroundColor: Color(0xFF84CC16),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            const Text('📢 Box Announcements', style: TextStyle(color: Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _announcementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No recent announcements.', style: TextStyle(color: Colors.white70));
                }
                final ann = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ann.length,
                  itemBuilder: (context, index) {
                    final item = ann[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF14221A), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] ?? '', style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['message'] ?? item['text'] ?? '', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            const Text('🥳 Upcoming Birthdays', style: TextStyle(color: Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _birthdaysFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No upcoming birthdays.', style: TextStyle(color: Colors.white70));
                }
                final bdays = snapshot.data!;
                return SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: bdays.length,
                    itemBuilder: (context, index) {
                      final b = bdays[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF14221A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(b['date'] ?? '', style: const TextStyle(color: Color(0xFF84CC16), fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMenuCard(context, 'Schedule & Classes', Icons.calendar_today, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(userId: widget.user.id.toString())));
                }),
                _buildMenuCard(context, 'Health & Fitness', Icons.monitor_weight, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HealthSyncScreen(userId: widget.user.id.toString())));
                }),
                _buildMenuCard(context, 'Trainers', Icons.sports, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainersScreen()));
                }),
                _buildMenuCard(context, 'About Box', Icons.info, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WebsiteScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14221A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF84CC16)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
