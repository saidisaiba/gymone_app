import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Compact birthday list (matching your database / web format)
  final List<Map<String, dynamic>> _birthdays = [
    {'name': 'Saiba Saidi', 'date': 'Oct 6', 'isToday': false},
    {'name': 'Rudasingwa John', 'date': 'Today 🎉', 'isToday': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14221A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF84CC16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '1K',
                style: TextStyle(
                  color: Color(0xFF0C1611),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white70),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('1',
                      style: TextStyle(fontSize: 9, color: Colors.white)),
                ),
              )
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // 2. Weekly Streak Tracker ("Let's get it started!")
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
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
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
                            color: isActive
                                ? const Color(0xFF0C1611)
                                : Colors.grey,
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
                      itemCount: _birthdays.length,
                      itemBuilder: (context, index) {
                        final b = _birthdays[index];
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF14221A),
        selectedItemColor: const Color(0xFF84CC16),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Results'),
        ],
      ),
    );
  }
}
