import 'package:flutter/material.dart';

class TrainersScreen extends StatelessWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trainers = [
      {'name': 'Coach Jean Bosco', 'specialty': 'CrossFit Level 2 & Weightlifting'},
      {'name': 'Coach Aline', 'specialty': 'Endurance & Mobility'},
      {'name': 'Coach Eric', 'specialty': 'Strength & Conditioning'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: const Text('Our Trainers', style: TextStyle(color: Color(0xFF84CC16))),
        backgroundColor: const Color(0xFF14221A),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: ListView.builder(
        itemCount: trainers.length,
        itemBuilder: (context, index) {
          final trainer = trainers[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14221A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF84CC16),
                child: Icon(Icons.fitness_center, color: Color(0xFF0C1611)),
              ),
              title: Text(trainer['name']!, style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
              subtitle: Text(trainer['specialty']!, style: const TextStyle(color: Colors.white70)),
            ),
          );
        },
      ),
    );
  }
}
