import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Admin: MoMo payments submitted by members, waiting for confirmation.
class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService.getPaymentRequests();
    if (!mounted) return;
    setState(() {
      _requests = list.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();
      _error = ApiService.lastError;
      _loading = false;
    });
  }

  Future<void> _decide(Map<String, dynamic> r, bool approve) async {
    final id = int.tryParse('${r['id']}') ?? 0;
    var note = '';
    if (!approve) {
      final c = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject payment'),
          content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Reason (shown to the member)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      note = c.text.trim();
    }
    final ok = approve ? await ApiService.approvePayment(id) : await ApiService.rejectPayment(id, note: note);
    if (!mounted) return;
    showMessage(context, ok ? (approve ? 'Payment approved — membership activated.' : 'Payment rejected.') : ApiService.lastError, error: !ok);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Loading()
            else if (_requests.isEmpty)
              InfoCard(_error.isNotEmpty ? _error : 'No payments waiting for confirmation.')
            else
              for (final r in _requests)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r['name'] ?? r['user_name'] ?? 'Member #${r['user_id']}'}',
                        style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Phone: ${r['phone'] ?? '—'}', style: const TextStyle(color: Colors.white70)),
                    if ('${r['reference'] ?? ''}'.isNotEmpty) Text('MoMo ref: ${r['reference']}', style: const TextStyle(color: Colors.white70)),
                    if (r['amount'] != null) Text('Amount: ${r['amount']} RWF', style: const TextStyle(color: Colors.white70)),
                    if (r['created_at'] != null) Text('Submitted: ${r['created_at']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () => _decide(r, false), child: const Text('Reject', style: TextStyle(color: AppColors.danger))),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => _decide(r, true), child: const Text('Approve')),
                    ]),
                  ]),
                ),
          ],
        ),
      ),
    );
  }
}
