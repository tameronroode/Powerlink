import 'package:flutter/material.dart';

// Customer messaging screen to interact with employees.
class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  // --- Mock Data ---
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Support Team',
      'message': 'Welcome! How can we help you today?',
      'time': '10:45 AM',
      'isRead': false,
      'avatar': 'S',
    },
    {
      'name': 'John (Sales Rep)',
      'message': 'Just checking in on your recent inquiry.',
      'time': 'Yesterday',
      'isRead': true,
      'avatar': 'J',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final theme = Theme.of(context);
          final bool isUnread = !(conversation['isRead'] as bool);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: Text(
                conversation['avatar'],
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
            title: Text(
              conversation['name'],
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(conversation['message']),
            trailing: Text(
              conversation['time'],
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                color: isUnread ? theme.primaryColor : theme.textTheme.bodySmall?.color,
              ),
            ),
            onTap: () {
              print("Tapped on ${conversation['name']}'s chat");
            },
          );
        },
      ),
    );
  }
}
