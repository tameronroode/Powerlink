import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/customer_profile_screen.dart';
import 'package:powerlink_crm/screens/customer_support_screen.dart';
import 'package:powerlink_crm/screens/customer_settings_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomePage(),
    CustomerSupportScreen(),
    CustomerProfileScreen(),
    CustomerSettingsScreen(),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ------------------------ HOME PAGE ------------------------
class _HomePage extends StatelessWidget {
  const _HomePage();

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // In dark mode, use a brighter color like blueAccent for better contrast,
    // which is also used in the dark theme for elevated buttons.
    // In light mode, use the standard primary color.
    return isDarkMode ? Colors.blueAccent : theme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dynamicColor = _getDynamicColor(context); // Get the adaptive color

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, dynamicColor),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: dynamicColor),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.shopping_bag,
            title: 'My Orders',
            description: 'View and track your past and ongoing orders.',
            color: dynamicColor,
          ),
          _buildActionCard(
            context,
            icon: Icons.store,
            title: 'Browse Products',
            description: 'Explore more products and services available.',
            color: dynamicColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color dynamicColor) {
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
                color: dynamicColor, // Use the dynamic color
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
    required Color color, // Pass the dynamic color to the card
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30), // Use the dynamic color
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)), // Use the dynamic color
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
        onTap: () {},
      ),
    );
  }
}
