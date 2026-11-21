import 'package:flutter/material.dart';

class UserProfileTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const UserProfileTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(30, 32, 34, 1.0),
      borderRadius: BorderRadius.circular(12.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Image.network(
            imageUrl,
            width: 48.0,
            height: 48.0,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 48.0,
                height: 48.0,
                color: Colors.grey[800],
                child: const Icon(
                  Icons.person,
                  color: Colors.white70,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 48.0,
                height: 48.0,
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              );
            },
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
      ),
    );
  }
}
