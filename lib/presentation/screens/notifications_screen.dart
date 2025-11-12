import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> notifications = const [
    {'title': 'Price Alert', 'body': 'Bitcoin hit \$65,000!', 'time': '2 min ago'},
    {'title': 'Security', 'body': 'New login from Chrome', 'time': '1 hour ago'},
    {'title': 'Update', 'body': 'Krypton v1.2 is available', 'time': '3 hours ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0D0D1C),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications', style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final n = notifications[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.cyanAccent,
                    child: Icon(Icons.notifications, color: Colors.black),
                  ),
                  title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(n['body']!),
                  trailing: Text(n['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              },
            ),
    );
  }
}