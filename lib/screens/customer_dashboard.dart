import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/customer_messages_screen.dart';
import 'package:powerlink_crm/screens/customer_profile_screen.dart';
import 'package:powerlink_crm/screens/customer_support_screen.dart';
import 'package:powerlink_crm/screens/customer_settings_screen.dart'; // Import the new settings screen

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  // Add the new CustomerSettingsScreen to the list of pages
  final List<Widget> _pages = const [
    _HomePage(),
    CustomerMessagesScreen(),
    CustomerSupportScreen(),
    CustomerProfileScreen(),
    CustomerSettingsScreen(), // New settings page
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
        elevation: 0,
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures labels are always visible
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          // Add the new settings icon to the nav bar
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ------------------------ HOME PAGE ------------------------
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final products = [
      {'name': 'Premium Package', 'description': 'Access to premium tools and reports', 'price': 'R499/month'},
      {'name': 'Standard Package', 'description': 'Basic analytics and insights', 'price': 'R299/month'},
      {'name': 'Consultation Session', 'description': '1-on-1 with an expert', 'price': 'R199/session'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.shopping_bag,
            title: 'My Orders',
            description: 'View and track your past and ongoing orders.',
          ),
          _buildActionCard(
            context,
            icon: Icons.store,
            title: 'Browse Products',
            description: 'Explore more products and services available.',
          ),
          _buildActionCard(
            context,
            icon: Icons.support_agent,
            title: 'Contact Employee',
            description: 'Reach out to an employee for direct assistance.',
          ),
          const SizedBox(height: 25),
          Text(
            'Available Products',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
          const SizedBox(height: 10),
          ...products.map((p) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p['description']!),
                trailing: Text(
                  p['price']!,
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          child: Icon(Icons.person, size: 30),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning, Alex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            Text(
              'Welcome back!',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
        onTap: () {},
      ),
    );
  }
}
