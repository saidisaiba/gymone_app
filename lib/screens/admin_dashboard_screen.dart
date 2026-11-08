import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import 'user_list_screen.dart';
import 'schedule_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAddUserDialog() {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final phoneC = TextEditingController();
    final memberNoC = TextEditingController();
    String role = 'client';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14221A),
        title: const Text('Add New Client / User', style: TextStyle(color: Color(0xFF84CC16))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              TextField(controller: memberNoC, decoration: const InputDecoration(labelText: 'Member Number', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                dropdownColor: const Color(0xFF14221A),
                items: ['client', 'coach', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => role = val ?? 'client',
                decoration: const InputDecoration(labelText: 'Role', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
            onPressed: () async {
              bool success = await ApiService.addUser({
                'name': nameC.text,
                'email': emailC.text,
                'password': passC.text,
                'phone_number': phoneC.text,
                'member_number': memberNoC.text,
                'role': role,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success ? 'User added successfully!' : 'Failed to add user.'),
                backgroundColor: const Color(0xFF84CC16),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProofOfPaymentDialog() async {
    List<UserModel> users = await ApiService.getUsers();
    if (!mounted) return;

    UserModel? selectedUser;
    final searchC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          List<UserModel> filteredUsers = users.where((u) {
            final query = searchC.text.toLowerCase();
            return u.name.toLowerCase().contains(query) ||
                   u.email.toLowerCase().contains(query) ||
                   u.memberNumber.toLowerCase().contains(query) ||
                   u.phoneNumber.toLowerCase().contains(query) ||
                   u.id.toString() == query;
          }).toList();

          return AlertDialog(
            backgroundColor: const Color(0xFF14221A),
            title: const Text('🧾 Generate Proof of Payment', style: TextStyle(color: Color(0xFF84CC16))),
            content: SizedBox(
              width: 400,
              height: 450,
              child: Column(
                children: [
                  TextField(
                    controller: searchC,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Search by Name, Email, Phone, or Member No',
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF84CC16)),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const Center(child: Text('No matching users found.', style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final u = filteredUsers[index];
                              bool isSelected = selectedUser?.id == u.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF84CC16).withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  title: Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text('${u.email} | No: ${u.memberNumber.isNotEmpty ? u.memberNumber : "N/A"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(u.isActive ? 'Active 🟢' : 'Inactive 🔴', style: TextStyle(fontSize: 12, color: u.isActive ? Colors.green : Colors.red)),
                                      if (!u.isActive) ...[
                                        const SizedBox(width: 8),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFF84CC16),
                                            foregroundColor: const Color(0xFF0C1611),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            minimumSize: const Size(50, 24),
                                          ),
                                          onPressed: () async {
                                            final phoneInputC = TextEditingController(text: u.phoneNumber.isNotEmpty ? u.phoneNumber : '+250780000000');
                                            bool? paid = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: const Color(0xFF14221A),
                                                title: Text('💳 MoMo Pay: ${u.name}', style: const TextStyle(color: Color(0xFF84CC16), fontSize: 16)),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('Enter MoMo phone number for payment:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                    const SizedBox(height: 8),
                                                    TextField(controller: phoneInputC, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.grey))),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
                                                    onPressed: () async {
                                                      await ApiService.pay(userId: u.id.toString(), phone: phoneInputC.text);
                                                      Navigator.pop(ctx, true);
                                                    },
                                                    child: const Text('Confirm Pay'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (paid == true) {
                                              UserModel? updatedU = await ApiService.getUser(u.id.toString());
                                              setDialogState(() {
                                                int idx = users.indexWhere((x) => x.id == u.id);
                                                if (idx != -1 && updatedU != null) users[idx] = updatedU;
                                                if (selectedUser?.id == u.id && updatedU != null) selectedUser = updatedU;
                                              });
                                            }
                                          },
                                          child: const Text('MoMo Pay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  onTap: () => setDialogState(() => selectedUser = u),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
                onPressed: selectedUser == null ? null : () {
                  Navigator.pop(context);
                  _showProofReceiptDialog(selectedUser!);
                },
                child: const Text('Generate Proof'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProofReceiptDialog(UserModel u) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14221A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF84CC16), width: 1.5),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                AppLogo(size: 28),
                SizedBox(width: 8),
                Text('CROSSFIT 1000 HILLS', style: TextStyle(color: Color(0xFF84CC16), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            Chip(
              label: const Text('OFFICIAL PROOF', style: TextStyle(fontSize: 10, color: Color(0xFF0C1611))),
              backgroundColor: const Color(0xFF84CC16),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Color(0xFF84CC16)),
              const SizedBox(height: 8),
              const Text('PAYMENT & MEMBERSHIP RECEIPT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildProofRow('Client Name:', u.name),
              _buildProofRow('Member Number:', u.memberNumber.isNotEmpty ? u.memberNumber : 'N/A'),
              _buildProofRow('Email:', u.email),
              _buildProofRow('Phone Number:', u.phoneNumber.isNotEmpty ? u.phoneNumber : 'N/A'),
              const Divider(color: Colors.grey, height: 24),
              _buildProofRow('Status:', u.isActive ? 'ACTIVE 🟢' : 'INACTIVE 🔴', valueColor: u.isActive ? const Color(0xFF84CC16) : Colors.redAccent),
              _buildProofRow('Expiry Date:', u.expiryDate),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1611),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Thank you for training with CrossFit 1000 Hills! Kigali, Rwanda.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Proof of payment generated and saved successfully! 📄'),
                  backgroundColor: Color(0xFF84CC16),
                ),
              );
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProofRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Admin - ${widget.user.name}',
                style: const TextStyle(color: Color(0xFF84CC16), fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF14221A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF84CC16)),
            tooltip: 'Log Off',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Admin Management Console', style: TextStyle(color: Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAdminTile(Icons.person_add, 'Add New Client / User', 'Register new member account', _showAddUserDialog),
            _buildAdminTile(Icons.people, 'Manage All Clients & Users', 'View, update, or remove client accounts', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListScreen()));
            }),
            _buildAdminTile(Icons.receipt_long, 'Generate Proof of Payment', 'Search members and generate official payment receipt proof', _showProofOfPaymentDialog),
            _buildAdminTile(Icons.calendar_month, 'Manage Classes & Schedule', 'Add or remove workout classes', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(userId: widget.user.id.toString())));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14221A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF84CC16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF84CC16), size: 16),
        onTap: onTap,
      ),
    );
  }
}
