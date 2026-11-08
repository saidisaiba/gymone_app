import 'package:flutter/material.dart';
import '../api_service.dart';

class PersonalRecordsScreen extends StatefulWidget {
  final int userId;
  const PersonalRecordsScreen({super.key, required this.userId});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  bool _isLoading = true;
  List<dynamic> _prs = [];
  final _movementController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedDate = DateTime.now().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _fetchPRs();
  }

  Future<void> _fetchPRs() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getPersonalRecords(widget.userId);
    if (res['status'] == 'success' || res['prs'] != null) {
      setState(() {
        _prs = res['prs'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPR() async {
    if (_movementController.text.isEmpty || _valueController.text.isEmpty) return;
    
    final res = await ApiService.addPersonalRecord(
      widget.userId,
      _movementController.text,
      _valueController.text,
      _selectedDate,
    );

    if (res['status'] == 'success') {
      _movementController.clear();
      _valueController.clear();
      _fetchPRs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PR enregistré avec succès !'), backgroundColor: Color(0xFF84CC16)),
      );
    }
  }

  Future<void> _deletePR(int prId) async {
    final res = await ApiService.deletePersonalRecord(prId, widget.userId);
    if (res['status'] == 'success') {
      _fetchPRs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PR supprimé.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Records Personnels (PRs)'),
        backgroundColor: const Color(0xFF14221A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const Text(
                    '+ Enregistrer un nouveau record',
                    style: TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _movementController,
                    decoration: const InputDecoration(
                      labelText: 'Mouvement / WOD (ex: Back Squat)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      labelText: 'Performance (ex: 120 kg ou 3:45)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84CC16),
                        foregroundColor: const Color(0xFF0C1611),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _addPR,
                      child: const Text('Ajouter le PR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Historique des PRs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                : _prs.isEmpty
                    ? const Text('Aucun record enregistré pour le moment.', style: TextStyle(color: Colors.grey))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prs.length,
                        itemBuilder: (context, index) {
                          final pr = _prs[index];
                          return Card(
                            color: const Color(0xFF14221A),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(pr['movement_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Date: ${pr['recorded_date']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    pr['record_value'] ?? '',
                                    style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deletePR(int.parse(pr['id'].toString())),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
