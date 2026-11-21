import 'package:flutter/material.dart';
import '../widgets/user_profile_tile.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Member Directory'),
        backgroundColor: const Color(0xFF1E2022),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          UserProfileTile(
            imageUrl:
                'https://crossfit1000hills.com/uploads/profiles/user_10_1787140276.jpeg',
            title: 'Member Profile',
            subtitle: 'Active Member',
            onTap: () {
              // Handle tile tap action
            },
          ),
        ],
      ),
    );
  }
}
