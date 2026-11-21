import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  // Hardcoded for testing; replace with actual authenticated user ID from login
  final int userId = 1; 

  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _stepGoalController = TextEditingController(text: '10000');
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _waterGoalController = TextEditingController(text: '8');

  bool _isLoading = false;

  Future<void> _syncMetrics() async {
    setState(() {
      _isLoading = true;
    });

    // Pointing directly to your live server
    const String apiUrl = 'https://crossfit1000hills.com/calendar/api_sync_health.php';
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final Map<String, dynamic> payload = {
      "user_id": userId,
      "record_date": currentDate,
      "steps": int.tryParse(_stepsController.text) ?? 0,
      "step_goal": int.tryParse(_stepGoalController.text) ?? 10000,
      "water_glasses": int.tryParse(_waterController.text) ?? 0,
      "water_goal": int.tryParse(_waterGoalController.text) ?? 8,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        _showMessage('Metrics synchronized successfully!', Colors.green);
      } else {
        final error = json.decode(response.body)['message'] ?? 'Sync failed';
        _showMessage('Error: $error', Colors.red);
      }
    } catch (e) {
      _showMessage('Network error. Check your connection.', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Health Metrics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildInputField('Steps Taken', _stepsController, Icons.directions_walk),
            const SizedBox(height: 16),
            _buildInputField('Step Goal', _stepGoalController, Icons.flag),
            const SizedBox(height: 16),
            _buildInputField('Water Glasses', _waterController, Icons.local_drink),
            const SizedBox(height: 16),
            _buildInputField('Water Goal', _waterGoalController, Icons.flag),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90D348),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _isLoading ? null : _syncMetrics,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Sync to CrossFit 1000 Hills',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF90D348)),
        filled: true,
        fillColor: const Color(0xFF233327),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}