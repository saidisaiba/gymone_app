import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
  static const Color textLight = Color(0xFFE5E7EB);

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ScheduleTab(userId: _userId, userName: _userName),
      BookingsTab(userId: _userId),
      HealthMetricsTab(userId: _userId),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardBg,
        selectedItemColor: accentLime,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Health Metrics',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: SCHEDULE & BOOKING
// ==========================================
class ScheduleTab extends StatefulWidget {
  final int? userId;
  final String userName;
  const ScheduleTab({super.key, required this.userId, required this.userName});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  bool _isLoading = true;
  List<dynamic> _classes = [];
  String? _errorMessage;

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
          _classes = response['classes'] ?? [];
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

  Future<void> _bookClass(int classId, String className) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session missing. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ),
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF84CC16).withValues(alpha: 0.3)),
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
                Text('Welcome, ${widget.userName}!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Select an available WOD session below to reserve your spot.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Available Classes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.redAccent)))
                    : _classes.isEmpty
                        ? const Center(
                            child: Text('No classes scheduled right now.',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _classes.length,
                            itemBuilder: (context, index) {
                              final item = _classes[index];
                              final className = item['name'] ??
                                  item['title'] ??
                                  'CrossFit WOD';
                              final classTime =
                                  item['date'] ?? item['time'] ?? 'TBD';
                              final classId =
                                  int.tryParse(item['id'].toString()) ?? 0;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14221A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.bolt,
                                      color: Color(0xFF84CC16)),
                                  title: Text(className,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text('Time: $classTime',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF84CC16),
                                      foregroundColor: const Color(0xFF0C1611),
                                    ),
                                    onPressed: () =>
                                        _bookClass(classId, className),
                                    child: const Text('Book',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
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
  const BookingsTab({super.key, required this.userId});

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
          const SizedBox(height: 20),
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
                                          .withValues(alpha: 0.2)),
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
  const HealthMetricsTab({super.key, required this.userId});

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
          const SizedBox(height: 20),
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
