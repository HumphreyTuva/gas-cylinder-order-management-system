import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0x1A1B6F5C),
                child: Text(
                  (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 32, color: Color(0xFF1B6F5C), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(user?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge),
            ),
            Center(
              child: Chip(
                label: Text(_roleLabel(user?.role)),
                backgroundColor: const Color(0x1A1B6F5C),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.person_outline), title: const Text('Username'), subtitle: Text(user?.username ?? '')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Phone Number'), subtitle: Text(user?.phoneNumber ?? '')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(user?.email ?? 'Not provided')),
                  if (user?.defaultDeliveryAddress?.isNotEmpty == true) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Default Delivery Address'),
                      subtitle: Text(user!.defaultDeliveryAddress!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'staff':
        return 'Staff';
      case 'management':
        return 'Management';
      default:
        return 'Customer';
    }
  }
}
