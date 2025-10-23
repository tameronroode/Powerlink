import 'package:flutter/material.dart';

class MessagesEmployeeScreen extends StatelessWidget {
  const MessagesEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget is now just the body, the Scaffold is in the main dashboard
    return _buildConversationList(context);
  }

  Widget _buildConversationList(BuildContext context) {
    final List<Map<String, Object>> mockConversations = [
      {
        'name': 'John Smith',
        'message': 'Hey, just checking in on the new proposal.',
        'time': '10:45 AM',
        'isRead': false,
      },
      {
        'name': 'Jane Doe',
        'message': 'Can you send over the report?',
        'time': '9:30 AM',
        'isRead': true,
      },
      {
        'name': 'Sales Team',
        'message': "Alex: Don't forget the meeting tomorrow!",
        'time': 'Yesterday',
        'isRead': false,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: mockConversations.length,
      separatorBuilder: (context, index) => const Divider(indent: 80, height: 1),
      itemBuilder: (context, index) {
        final conversation = mockConversations[index];
        return _buildConversationTile(
          context,
          name: conversation['name'] as String,
          lastMessage: conversation['message'] as String,
          time: conversation['time'] as String,
          isRead: conversation['isRead'] as bool,
          onTap: () {
            print("Tapped on ${conversation['name']}'s chat");
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    {
    required String name,
    required String lastMessage,
    required String time,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final unreadColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: primaryColor,
        child: Icon(Icons.person, color: theme.colorScheme.onPrimary, size: 30),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, color: isRead ? null : unreadColor),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isRead ? theme.textTheme.bodySmall?.color : unreadColor,
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? theme.textTheme.bodySmall?.color : primaryColor,
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (!isRead)
            CircleAvatar(
              radius: 5,
              backgroundColor: primaryColor,
            )
          else
            const SizedBox(height: 10), // To keep alignment consistent
        ],
      ),
    );
  }
}
