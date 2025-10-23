import 'package:flutter/material.dart';
import 'employee_profile.dart'; // Use consistent relative import
import 'messages_employee.dart'; // Import the new messages screen
import 'settings_screen.dart';

// Main stateful widget that acts as the navigation shell
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  // List of the main pages for the dashboard
  // These widgets should not have their own Scaffolds
  static const List<Widget> _pages = <Widget>[
    _DashboardHomePage(), // The main dashboard view
    MessagesEmployeeScreen(),
    Center(child: Text('Voice AI Screen - Coming Soon')), // Placeholder
    Center(child: Text('Gamification Screen - Coming Soon')), // Placeholder
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        // The leading back button is removed automatically when it's a top-level screen
        automaticallyImplyLeading: false,
      ),
      // Use IndexedStack to preserve the state of each page when switching
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
        // No hardcoded colors - will use the theme from main.dart
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: 'Voice AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            activeIcon: Icon(Icons.games),
            label: 'Gamify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// The content for the "Home" tab of the dashboard
class _DashboardHomePage extends StatelessWidget {
  const _DashboardHomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Assigned Tasks'),
          _buildTaskList(),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Customer Leads'),
          _buildLeadsList(context),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Recent Interactions'),
          _buildInteractionsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Make the avatar a button to navigate to the profile page
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeProfile()),
            );
          },
          child: const CircleAvatar(
            radius: 30,
            child: Icon(Icons.person, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Alex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor, // Apply consistent color
              ),
            ),
            Text(
              'Today: October 20, 2025',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = [
      {'title': 'Follow up with client #123', 'status': 'In Progress'},
      {'title': 'Prepare proposal for new lead', 'status': 'Pending'},
      {'title': 'Team meeting at 3 PM', 'status': 'Completed'},
    ];

    return Column(
      children: tasks.map((task) {
        Color statusColor;
        switch (task['status']) {
          case 'Completed':
            statusColor = Colors.green;
            break;
          case 'In Progress':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(task['title']!),
            trailing: Text(
              task['status']!,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeadsList(BuildContext context) {
    final leads = [
      {'name': 'John Smith', 'source': 'Website Form', 'status': 'New'},
      {'name': 'Jane Doe', 'source': 'Referral', 'status': 'Contacted'},
    ];

    return Column(
      children: leads.map((lead) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
            title: Text(lead['name']!),
            subtitle: Text('Source: ${lead['source']}'),
            trailing: Text(lead['status']!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionsList(BuildContext context) {
    final interactions = [
      {'type': 'Call', 'with': 'John Smith', 'time': '10:00 AM'},
      {'type': 'Email', 'with': 'Jane Doe', 'time': 'Yesterday'},
      {'type': 'Meeting', 'with': 'Team', 'time': 'Tomorrow 3 PM'},
    ];

    return Column(
      children: interactions.map((i) {
        IconData icon;
        switch (i['type']) {
          case 'Call':
            icon = Icons.phone;
            break;
          case 'Email':
            icon = Icons.email;
            break;
          default:
            icon = Icons.people;
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).primaryColor),
            title: Text('${i['type']} with ${i['with']}'),
            subtitle: Text('Time: ${i['time']}'),
          ),
        );
      }).toList(),
    );
  }
}
