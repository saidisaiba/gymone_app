import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class HealthSyncScreen extends StatefulWidget {
  final String userId;
  const HealthSyncScreen({super.key, required this.userId});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  final _stepsController = TextEditingController(text: '7500');
  final _stepGoalController = TextEditingController(text: '10000');
  final _waterController = TextEditingController(text: '6');
  final _waterGoalController = TextEditingController(text: '8');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalHealth();
  }

  void _loadLocalHealth() async {
    final metrics = await StorageService.getCachedHealthMetrics();
    setState(() {
      _stepsController.text = metrics['steps'].toString();
      _waterController.text = metrics['water'].toString();
    });
  }

  void _syncHealth() async {
    setState(() => _isLoading = true);
    bool success = await ApiService.saveHealthMetrics(
      userId: widget.userId,
      steps: int.tryParse(_stepsController.text) ?? 0,
      stepGoal: int.tryParse(_stepGoalController.text) ?? 10000,
      waterGlasses: int.tryParse(_waterController.text) ?? 0,
      waterGoal: int.tryParse(_waterGoalController.text) ?? 8,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Health metrics saved & synced locally! 💧' : 'Failed to sync metrics.'),
          backgroundColor: const Color(0xFF84CC16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: const Text('Health & Activity Sync (Local Cache)', style: TextStyle(color: Color(0xFF84CC16))),
        backgroundColor: const Color(0xFF14221A),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Data is stored locally on your phone and synced when online.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(controller: _stepsController, decoration: const InputDecoration(labelText: 'Steps Taken', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _stepGoalController, decoration: const InputDecoration(labelText: 'Step Goal', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _waterController, decoration: const InputDecoration(labelText: 'Water Glasses', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _waterGoalController, decoration: const InputDecoration(labelText: 'Water Goal', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: const Color(0xFF0C1611),
              ),
              onPressed: _isLoading ? null : _syncHealth,
              child: _isLoading ? const CircularProgressIndicator(color: Color(0xFF0C1611)) : const Text('Save Locally & Sync', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
