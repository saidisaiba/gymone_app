import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'website_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int? _userId;
  String _userName = 'Member';

  static const Color bgDark = Color(0xFF0C1611);
  static const Color cardBg = Color(0xFF14221A);
  static const Color accentLime = Color(0xFF84CC16);

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userMap = jsonDecode(userDataStr);
        if (userMap['name'] != null) {
          _userName = userMap['name'];
        }
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(userName: _userName),
      ScheduleTab(userId: _userId, userName: _userName),
      BookingsTab(userId: _userId),
      HealthMetricsTab(userId: _userId),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentLime,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '1K',
                style: TextStyle(
                  color: bgDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CROSSFIT 1000 HILLS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: accentLime),
            tooltip: 'View Website',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WebsiteScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: accentLime),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardBg,
        selectedItemColor: accentLime,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: 'My Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight), label: 'Health'),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 0: HOME / INNER LOOP DASHBOARD
// ==========================================
class HomeTab extends StatelessWidget {
  final String userName;
  const HomeTab({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> birthdays = [
      {'name': 'Saiba Saidi', 'date': 'Oct 6', 'isToday': false},
      {'name': userName, 'date': 'Today 🎉', 'isToday': true},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CROSSFIT 1000 HILLS',
                    style: TextStyle(
                        color: Color(0xFF84CC16),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text('Welcome back, $userName!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Track your training, streak, and community updates.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Announcement Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D4237)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.campaign_outlined,
                            color: Color(0xFF84CC16), size: 18),
                        SizedBox(width: 8),
                        Text('ANNOUNCEMENT',
                            style: TextStyle(
                                color: Color(0xFF84CC16),
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                    Icon(Icons.keyboard_arrow_up,
                        color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join us on Saturday, October 31, 2026 at 9:00 a.m. for a free clinic with our friends from True Sports Physical Therapy. You\'ll learn tips for improving mobility and preventing injuries, and more...',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Weekly Streak Tracker
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D4237)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Let\'s get it started!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text('0 week streak',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    bool isActive = day == 'S';
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF84CC16)
                            : const Color(0xFF0C1611),
                        border: Border.all(
                            color: isActive
                                ? const Color(0xFF84CC16)
                                : const Color(0xFF2D4237)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: TextStyle(
                          color:
                              isActive ? const Color(0xFF0C1611) : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Bookings Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D4237)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('BOOKINGS',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'No class or appointment reservations',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Compact Horizontal Birthdays Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D4237)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.card_giftcard, color: Colors.grey, size: 16),
                    SizedBox(width: 8),
                    Text('BIRTHDAYS',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 55,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: birthdays.length,
                    itemBuilder: (context, index) {
                      final b = birthdays[index];
                      bool isToday = b['isToday'];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C1611),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isToday
                                ? const Color(0xFF84CC16)
                                : const Color(0xFF2D4237),
                          ),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF84CC16),
                              child: Icon(Icons.person,
                                  size: 16, color: Color(0xFF0C1611)),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  b['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  b['date'],
                                  style: TextStyle(
                                    color: isToday
                                        ? const Color(0xFF84CC16)
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: SCHEDULE & BOOKING (Calendar View)
// ==========================================
class ScheduleTab extends StatefulWidget {
  final int? userId;
  final String userName;
  const ScheduleTab({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  bool _isLoading = true;
  List<dynamic> _allClasses = [];
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getClasses();
      if (response['status'] == 'success') {
        setState(() {
          _allClasses = response['classes'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load classes.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredClasses() {
    return _allClasses.where((item) {
      final rawDate = item['date'] ?? item['class_time'] ?? item['start_time'];
      if (rawDate == null) return true;

      try {
        final parsed = DateTime.parse(rawDate.toString());
        return parsed.year == _selectedDate.year &&
            parsed.month == _selectedDate.month &&
            parsed.day == _selectedDate.day;
      } catch (_) {
        return true;
      }
    }).toList();
  }

  Future<void> _bookClass(int classId, String className) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User session missing. Please log in again.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF84CC16))),
    );

    try {
      final response = await ApiService.bookClass(widget.userId!, classId);
      Navigator.pop(context);

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Successfully booked class!'),
              backgroundColor: Color(0xFF84CC16)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Booking failed.'),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _getFilteredClasses();
    final List<String> weekDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    final List<DateTime> dateList = List.generate(
      14,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule & Booking',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon:
                    const Icon(Icons.calendar_month, color: Color(0xFF84CC16)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF84CC16),
                            onPrimary: Color(0xFF0C1611),
                            surface: Color(0xFF14221A),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Date Strip
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dateList.length,
              itemBuilder: (context, index) {
                final date = dateList[index];
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF84CC16)
                          : const Color(0xFF14221A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF84CC16)
                            : const Color(0xFF2D4237),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekDays[date.weekday - 1],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0C1611)
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0C1611)
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Available Classes (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year})',
            style: const TextStyle(
                color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.redAccent)))
                    : filteredClasses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.event_busy,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 10),
                                Text('No training sessions for this date.',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) {
                              final item = filteredClasses[index];
                              final className = item['name'] ??
                                  item['title'] ??
                                  'CrossFit WOD';
                              final classTime =
                                  item['time'] ?? item['start_time'] ?? 'TBD';
                              final coach = item['coach'] ?? 'Coach TBD';
                              final classId =
                                  int.tryParse(item['id'].toString()) ?? 0;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14221A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF2D4237)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF84CC16)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.bolt,
                                          color: Color(0xFF84CC16), size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(className,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('$coach • $classTime',
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF84CC16),
                                        foregroundColor:
                                            const Color(0xFF0C1611),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _bookClass(classId, className),
                                      child: const Text('Book',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: MY BOOKINGS
// ==========================================
class BookingsTab extends StatefulWidget {
  final int? userId;
  const BookingsTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (widget.userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User session not found.';
      });
      return;
    }

    try {
      final response = await ApiService.getUserBookings(widget.userId!);
      if (response['status'] == 'success') {
        setState(() {
          _bookings = response['bookings'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load bookings.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('My Reserved Classes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.redAccent)))
                    : _bookings.isEmpty
                        ? const Center(
                            child: Text('You have not booked any classes yet.',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14221A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF84CC16)
                                          .withOpacity(0.2)),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.check_circle,
                                      color: Color(0xFF84CC16)),
                                  title: Text(
                                      booking['name'] ?? 'Workout Session',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      'Time: ${booking['date'] ?? 'TBD'}',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: HEALTH METRICS
// ==========================================
class HealthMetricsTab extends StatefulWidget {
  final int? userId;
  const HealthMetricsTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<HealthMetricsTab> createState() => _HealthMetricsTabState();
}

class _HealthMetricsTabState extends State<HealthMetricsTab> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _metrics = [];

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    if (widget.userId == null) return;
    try {
      final response = await ApiService.getHealthMetrics(widget.userId!);
      if (response['status'] == 'success') {
        setState(() {
          _metrics = response['metrics'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitMetrics() async {
    if (widget.userId == null) return;
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);

    final response = await ApiService.saveHealthMetrics(widget.userId!,
        weight: weight, height: height, bodyFat: bodyFat);
    if (!mounted) return;
    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Metrics saved successfully!'),
          backgroundColor: Color(0xFF84CC16)));
      _weightController.clear();
      _heightController.clear();
      _bodyFatController.clear();
      _fetchMetrics();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Failed to save.'),
          backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('Health & Fitness Metrics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                TextField(
                  controller: _bodyFatController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Body Fat (%)',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: const Color(0xFF0C1611),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: _submitMetrics,
                  child: const Text('Save Metrics',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('History',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                : _metrics.isEmpty
                    ? const Center(
                        child: Text('No recorded metrics yet.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _metrics.length,
                        itemBuilder: (context, index) {
                          final m = _metrics[index];
                          return ListTile(
                            title: Text(
                                'Weight: ${m['weight'] ?? 'N/A'} kg | Height: ${m['height'] ?? 'N/A'} cm',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'Recorded: ${m['created_at'] ?? 'Recent'}',
                                style: const TextStyle(color: Colors.grey)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
