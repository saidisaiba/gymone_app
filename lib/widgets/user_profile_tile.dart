import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme.dart';

class UserProfileTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserProfileTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = user.profileImage.startsWith('http');
    final roleLabel = user.isMember ? (user.isActive ? 'ACTIVE' : 'INACTIVE') : user.role.toUpperCase();
    final roleColor = user.isMember ? (user.isActive ? AppColors.lime : AppColors.danger) : Colors.blueAccent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: cardDecoration(borderOpacity: 0.2),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.lime,
          foregroundImage: hasImage ? NetworkImage(user.profileImage) : null,
          child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          user.isMember && user.expiryDate != 'N/A' ? '${user.email}\nExpires ${user.expiryDate}' : user.email,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
