import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String userId;
  const ScheduleScreen({super.key, required this.userId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<dynamic>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = ApiService.getClasses();
  }

  void _bookClass(String classId) async {
    bool success = await ApiService.bookClass(userId: widget.userId, classId: classId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Class booked successfully! 🏋️' : 'Booking failed.'),
          backgroundColor: const Color(0xFF84CC16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: const Text('Class Schedule', style: TextStyle(color: Color(0xFF84CC16))),
        backgroundColor: const Color(0xFF14221A),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No classes scheduled.', style: TextStyle(color: Colors.white70)));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final c = classes[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14221A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
                ),
                child: ListTile(
                  title: Text(c['title'] ?? '', style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
                  subtitle: Text('Time: ${c['class_time'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: const Color(0xFF0C1611),
                    ),
                    onPressed: () => _bookClass(c['id'].toString()),
                    child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
