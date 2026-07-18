import 'package:flutter/material.dart';

import 'constants.dart';

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.accentColor,
    required this.notificationsEnabled,
    required this.onChangeAccentColor,
    required this.onToggleNotifications,
  });

  final Color accentColor;
  final bool notificationsEnabled;
  final ValueChanged<Color> onChangeAccentColor;
  final ValueChanged<bool> onToggleNotifications;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined, color: kPinkPrimary),
                title: const Text('Dark Mode'),
                subtitle: const Text('Follows your device system setting'),
                trailing: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: kPinkPrimary,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_none_rounded, color: kPinkPrimary),
                title: const Text('Notifications'),
                value: notificationsEnabled,
                activeColor: kPinkPrimary,
                onChanged: onToggleNotifications,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storefront_outlined, color: kPinkPrimary),
                title: const Text('Bakery Information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/bakery-info'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: kPinkPrimary),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed('/about'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: kPinkPrimary),
                title: const Text('Logout'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class BakeryInfoPage extends StatelessWidget {
  const BakeryInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakery Information')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _DetailRow(label: 'Bakery Name', value: kAppName),
                  _DetailRow(label: 'Address', value: '123 Baker Street'),
                  _DetailRow(label: 'Contact', value: '(02) 8123-4567'),
                  _DetailRow(label: 'Email', value: 'hello@pandebatanguena.com'),
                  _DetailRow(label: 'Operating Hours', value: '7:00 AM – 8:00 PM'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: BakeryLogo(size: 64),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(kAppName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Pastries & Cakes Inventory Management System', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                const Text(
                  'This app demonstrates Flutter widgets, forms, navigation, gestures, state management, and CRUD operations in one complete bakery inventory experience, backed live by Firebase Firestore.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}