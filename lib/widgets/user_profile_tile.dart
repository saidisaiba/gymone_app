import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProfileTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserProfileTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14221A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF84CC16),
          backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
          child: user.profileImage.isEmpty ? const Icon(Icons.person, color: Color(0xFF0C1611)) : null,
        ),
        title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('${user.email} | No: ${user.memberNumber.isNotEmpty ? user.memberNumber : "N/A"}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        trailing: Chip(
          label: Text(user.role),
          backgroundColor: user.role == 'admin' ? const Color(0xFF84CC16) : Colors.blue,
          labelStyle: TextStyle(color: user.role == 'admin' ? const Color(0xFF0C1611) : Colors.white),
        ),
      ),
    );
  }
}
