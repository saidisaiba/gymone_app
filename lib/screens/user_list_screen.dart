import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';
import '../widgets/user_profile_tile.dart';
import 'admin_dashboard_screen.dart' show showAddUserDialog;

/// Admin: all accounts, with search, filters and per-member actions.
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  bool _offline = false;
  String _query = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await ApiService.getUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _offline = ApiService.lastResultFromCache;
      _loading = false;
    });
  }

  List<UserModel> get _visible {
    final q = _query.toLowerCase().trim();
    return _users.where((u) {
      final matchesFilter = switch (_filter) {
        'active' => u.isMember && u.isActive,
        'inactive' => u.isMember && !u.isActive,
        'staff' => !u.isMember,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return [u.name, u.email, u.phoneNumber, u.memberNumber, u.id.toString()].any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  void _showDetails(UserModel u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            title: Text(u.name, style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(
              [u.email, if (u.phoneNumber.isNotEmpty) u.phoneNumber, 'Role: ${u.role == 'client' ? 'member' : u.role}'].join('\n'),
              style: const TextStyle(color: Colors.white70),
            ),
            isThreeLine: true,
          ),
          if (u.isMember)
            ListTile(
              leading: Icon(Icons.circle, size: 12, color: u.isActive ? AppColors.lime : AppColors.danger),
              title: Text(u.isActive ? 'Active until ${u.expiryDate}' : 'Inactive (expiry: ${u.expiryDate})', style: const TextStyle(color: Colors.white)),
            ),
          const Divider(color: Colors.white12),
          if (u.isMember)
            ListTile(
              leading: const Icon(Icons.autorenew, color: AppColors.lime),
              title: const Text('Renew / set membership'),
              onTap: () {
                Navigator.pop(ctx);
                _renew(u);
              },
            ),
          if (u.isMember)
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.lime),
              title: const Text('Proof of payment'),
              onTap: () {
                Navigator.pop(ctx);
                _showReceipt(u);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.lime),
            title: const Text('Edit account'),
            onTap: () {
              Navigator.pop(ctx);
              _edit(u);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: const Text('Delete account', style: TextStyle(color: AppColors.danger)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(u);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _renew(UserModel u) async {
    final current = DateTime.tryParse(u.expiryDate);
    final base = current != null && current.isAfter(DateTime.now()) ? current : DateTime.now();
    var expiry = DateTime(base.year, base.month + 1, base.day);
    final planC = TextEditingController(text: u.membershipType.isNotEmpty ? u.membershipType : 'Monthly');
    final amountC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Membership • ${u.name}', style: const TextStyle(color: AppColors.lime, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: planC, decoration: const InputDecoration(labelText: 'Plan')),
            const SizedBox(height: 10),
            TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount paid (RWF)')),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final m in [1, 3, 6, 12])
                ActionChip(
                  label: Text('+$m mo'),
                  onPressed: () => setD(() => expiry = DateTime(base.year, base.month + m, base.day)),
                ),
            ]),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: AppColors.lime),
              title: Text('Expires ${DateFormat('d MMM yyyy').format(expiry)}'),
              onTap: () async {
                final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: expiry);
                if (d != null) setD(() => expiry = d);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final saved = await ApiService.updateSubscription(
      userId: u.id,
      expiryDate: expiry.toIso8601String().substring(0, 10),
      membershipType: planC.text.trim().isEmpty ? 'Monthly' : planC.text.trim(),
      amount: double.tryParse(amountC.text) ?? 0,
    );
    if (!mounted) return;
    showMessage(context, saved ? 'Membership updated.' : ApiService.lastError, error: !saved);
    _load();
  }

  Future<void> _edit(UserModel u) async {
    final nameC = TextEditingController(text: u.name);
    final emailC = TextEditingController(text: u.email);
    final phoneC = TextEditingController(text: u.phoneNumber);
    final passC = TextEditingController();
    var role = u.role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${u.name}', style: const TextStyle(color: AppColors.lime)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'New password (leave empty to keep)')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: role,
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Member')),
                DropdownMenuItem(value: 'coach', child: Text('Coach')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? role,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok != true) return;
    if (passC.text.isNotEmpty && passC.text.length < 8) {
      if (mounted) showMessage(context, 'Password must contain at least 8 characters.', error: true);
      return;
    }
    final saved = await ApiService.updateUser(u, {
      'name': nameC.text.trim(),
      'email': emailC.text.trim().toLowerCase(),
      'phone_number': phoneC.text.trim(),
      'member_number': u.memberNumber,
      'birthdate': u.birthdate,
      'role': role,
      if (passC.text.isNotEmpty) 'password': passC.text,
    });
    if (!mounted) return;
    showMessage(context, saved ? 'Account updated.' : ApiService.lastError, error: !saved);
    _load();
  }

  Future<void> _confirmDelete(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?', style: TextStyle(color: AppColors.danger)),
        content: Text('This permanently removes ${u.name}, their bookings and membership history. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await ApiService.deleteUser(u.id.toString());
    if (!mounted) return;
    showMessage(context, deleted ? 'Account deleted.' : ApiService.lastError, error: !deleted);
    _load();
  }

  void _showReceipt(UserModel u) {
    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.lime, width: 1.5)),
        title: const Row(children: [
          AppLogo(size: 28),
          SizedBox(width: 8),
          Expanded(child: Text('CROSSFIT 1000 HILLS', style: TextStyle(color: AppColors.lime, fontSize: 14, fontWeight: FontWeight.bold))),
        ]),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MEMBERSHIP STATUS CONFIRMATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const Divider(color: AppColors.lime),
            row('Member', u.name),
            row('Member No.', u.memberNumber.isNotEmpty ? u.memberNumber : '#${u.id}'),
            row('Email', u.email),
            if (u.phoneNumber.isNotEmpty) row('Phone', u.phoneNumber),
            const Divider(color: Colors.white12),
            if (u.membershipType.isNotEmpty) row('Plan', u.membershipType),
            row('Status', u.isActive ? 'ACTIVE' : 'INACTIVE', color: u.isActive ? AppColors.lime : AppColors.danger),
            row('Valid until', u.expiryDate),
            row('Issued', DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())),
            const SizedBox(height: 12),
            const Text('Kigali, Rwanda • info@crossfit1000hills.com', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(title: const Text('Member Directory')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.background,
        tooltip: 'Add account',
        onPressed: () => showAddUserDialog(context, onAdded: _load),
        child: const Icon(Icons.person_add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search name, email, phone or member #',
              prefixIcon: Icon(Icons.search, color: AppColors.lime),
              fillColor: AppColors.surface,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final (key, label) in const [('all', 'All'), ('active', 'Active members'), ('inactive', 'Inactive members'), ('staff', 'Staff')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(label), selected: _filter == key, onSelected: (_) => setState(() => _filter = key)),
              ),
          ]),
        ),
        if (_offline) const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), child: OfflineBanner()),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? ListView(children: const [Loading()])
                : visible.isEmpty
                    ? ListView(padding: const EdgeInsets.all(16), children: [
                        InfoCard(_users.isEmpty && ApiService.lastError.isNotEmpty ? ApiService.lastError : 'No matching accounts.'),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 90),
                        itemCount: visible.length,
                        itemBuilder: (context, i) => UserProfileTile(user: visible[i], onTap: () => _showDetails(visible[i])),
                      ),
          ),
        ),
      ]),
    );
  }
}
