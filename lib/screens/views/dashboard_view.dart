import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrossFit 1000 Hills'),
        automaticallyImplyLeading: false, // Enlève la flèche de retour
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bonjour, Membre !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Carte du WOD du jour
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WOD du Jour',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Metcon',
                            style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      'AMRAP 15 Minutes :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 15 Wall Balls (20/14 lbs)\n'
                        '• 10 Burpees\n'
                        '• 5 Power Cleans (135/95 lbs)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
