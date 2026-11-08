import 'package:flutter/material.dart';

class WebsiteScreen extends StatelessWidget {
  const WebsiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: const Text('About CrossFit 1000 Hills', style: TextStyle(color: Color(0xFF84CC16))),
        backgroundColor: const Color(0xFF14221A),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text('CrossFit 1000 Hills', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF84CC16))),
            SizedBox(height: 12),
            Text('The premier fitness and CrossFit box in Rwanda. Push your limits with community, strength, and endurance workouts.', style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 20),
            Text('Location: Kigali, Rwanda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Contact: info@crossfit1000hills.com', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
