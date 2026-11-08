import 'package:flutter/material.dart';

class MembershipBanner extends StatelessWidget {
  final bool isActive;
  final String expiryDate;
  final VoidCallback onRenew;

  const MembershipBanner({
    super.key,
    required this.isActive,
    required this.expiryDate,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF14221A) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF84CC16) : Colors.redAccent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? 'Membership Active 🟢' : 'Membership Inactive 🔴',
                style: TextStyle(
                  color: isActive ? const Color(0xFF84CC16) : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expires: $expiryDate',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84CC16),
              foregroundColor: const Color(0xFF0C1611),
            ),
            onPressed: onRenew,
            child: const Text('Renew / Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
