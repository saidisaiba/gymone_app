import 'package:flutter/material.dart';

import '../theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lime, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text('CF', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: size * 0.4)),
          ),
        ),
      ),
    );
  }
}
