import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/user_profile_tile.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserModel>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = ApiService.getUsers();
    });
  }

  void _showEditUserDialog(UserModel user) {
    final nameC = TextEditingController(text: user.name);
    final emailC = TextEditingController(text: user.email);
    final phoneC = TextEditingController(text: user.phoneNumber);
    final memberNoC = TextEditingController(text: user.memberNumber);
    
    String role = ['client', 'coach', 'admin'].contains(user.role.toLowerCase().trim()) 
        ? user.role.toLowerCase().trim() 
        : 'client';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF14221A),
          title: Text('Edit User: ${user.name}', style: const TextStyle(color: Color(0xFF84CC16))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                TextField(controller: memberNoC, decoration: const InputDecoration(labelText: 'Member Number', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: const Color(0xFF14221A),
                  items: ['client', 'coach', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDialogState(() => role = val ?? 'client'),
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
                bool success = await ApiService.updateUser({
                  'id': user.id,
                  'name': nameC.text,
                  'email': emailC.text,
                  'phone_number': phoneC.text,
                  'member_number': memberNoC.text,
                  'birthdate': user.birthdate,
                  'role': role,
                });
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'User updated successfully!' : 'Failed to update user.'),
                  backgroundColor: const Color(0xFF84CC16),
                ));
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14221A),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.redAccent)),
        content: Text('Are you sure you want to delete ${user.name}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              bool success = await ApiService.deleteUser(user.id.toString());
              Navigator.pop(context);
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success ? 'User deleted.' : 'Failed to delete user.'),
                backgroundColor: Colors.redAccent,
              ));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: const Text('Member Directory & Search', style: TextStyle(color: Color(0xFF84CC16))),
        backgroundColor: const Color(0xFF14221A),
        iconTheme: const IconThemeData(color: Color(0xFF84CC16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search members by name, email, phone, or member #',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF84CC16)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF14221A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No members found.', style: TextStyle(color: Colors.white70)));
                  }

                  final users = snapshot.data!.where((u) {
                    final query = _searchQuery.toLowerCase();
                    return u.name.toLowerCase().contains(query) ||
                           u.email.toLowerCase().contains(query) ||
                           u.phoneNumber.toLowerCase().contains(query) ||
                           u.memberNumber.toLowerCase().contains(query);
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(child: Text('No matching members found.', style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserProfileTile(
                        user: user,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF14221A),
                              title: Text(user.name, style: const TextStyle(color: Color(0xFF84CC16))),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${user.email}', style: const TextStyle(color: Colors.white70)),
                                  Text('Phone: ${user.phoneNumber}', style: const TextStyle(color: Colors.white70)),
                                  Text('Member No: ${user.memberNumber}', style: const TextStyle(color: Colors.white70)),
                                  Text('Role: ${user.role}', style: const TextStyle(color: Colors.white70)),
                                  Text('Status: ${user.isActive ? "Active 🟢" : "Inactive 🔴"}', style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditUserDialog(user);
                                  },
                                  child: const Text('Edit', style: TextStyle(color: Color(0xFF84CC16))),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _confirmDelete(user);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), foregroundColor: const Color(0xFF0C1611)),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
