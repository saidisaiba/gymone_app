import 'package:flutter/material.dart';

class BookingView extends StatelessWidget {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning & Réservations'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Aujourd\'hui',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildClassCard(
            time: '17:00 - 18:00',
            className: 'CrossFit (WOD)',
            coach: 'Coach Alex',
            spotsLeft: 3,
            totalSpots: 15,
            isBooked: false,
          ),
          _buildClassCard(
            time: '18:00 - 19:00',
            className: 'Haltérophilie',
            coach: 'Coach Sarah',
            spotsLeft: 0,
            totalSpots: 10,
            isBooked: false,
          ),
          _buildClassCard(
            time: '19:00 - 20:00',
            className: 'CrossFit (WOD)',
            coach: 'Coach Alex',
            spotsLeft: 12,
            totalSpots: 15,
            isBooked: true,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String time,
    required String className,
    required String coach,
    required int spotsLeft,
    required int totalSpots,
    required bool isBooked,
  }) {
    final bool isFull = spotsLeft == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '$time | $className',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Coach : $coach'),
            const SizedBox(height: 4),
            Text(
              isFull ? 'Complet' : '$spotsLeft places restantes',
              style: TextStyle(
                color: isFull ? Colors.red : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: isBooked
            ? OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Annuler'),
              )
            : ElevatedButton(
                onPressed: isFull ? null : () {},
                child: const Text('Réserver'),
              ),
      ),
    );
  }
}
