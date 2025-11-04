// lib/screens/manager_dashboard.dart
import 'package:flutter/material.dart';

// Tabs / screens
import 'manager_profile_screen.dart';
import 'manage_users_screen.dart';
import 'customer_requests_screen.dart';
import 'messages_screen.dart';

// KPI drill-ins
import 'active_projects.dart';
import 'team_performance.dart';
import 'customer_satisfaction.dart';
import 'new_leads.dart';
import 'meetings_screen.dart';

// Data
import '../data/supabase_service.dart' as svc;

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  static const Color mainBlue = Color(0xFF182D53);

  final List<Widget> _pages = const [
    _ManagerHomePage(),
    MessagesScreen(),
    ManageUsersScreen(),
    CustomerRequestScreen(),
    ManagerProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: mainBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Manage'),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Manager Home (uniform KPI cards + recent activity)
// -----------------------------------------------------------------------------
class _ManagerHomePage extends StatelessWidget {
  const _ManagerHomePage();
  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    const fallbackActiveProjects = '12';
    const fallbackTeamPerf = 'Excellent';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 16),

          // KPI grid — medium, uniform sizing
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25, // helps keep a consistent visual shape
            children: [
              _buildKpiCard(
                context,
                title: 'Active Projects',
                icon: Icons.folder,
                valueWidget: const Text(
                  fallbackActiveProjects,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ActiveProjectsScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'Customer Satisfaction',
                icon: Icons.sentiment_satisfied,
                valueWidget: const _CustomerSatisfactionValue(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerSatisfactionScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'Team Performance',
                icon: Icons.star,
                valueWidget: const Text(
                  fallbackTeamPerf,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TeamPerformanceScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'New Leads',
                icon: Icons.show_chart,
                valueWidget: const _LeadsCountValue(),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ManagerLeadsDashboard())),
              ),
              _buildKpiCard(
                context,
                title: 'Meetings',
                icon: Icons.event_note,
                valueWidget: const Text(
                  'Plan & Log',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MeetingsScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            'New service request from "TechCorp" was assigned to Jane Doe.',
          ),
          _buildActivityItem(
            'Employee "John Smith" completed a task for "Innovate LLC".',
          ),
          _buildActivityItem(
            'A new customer "Global Solutions" was successfully onboarded.',
          ),
        ],
      ),
    );
  }

  // Uniform KPI card with fixed medium height
  static Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? valueWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 140, //fixed, medium size for all KPI cards
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 30, color: mainBlue),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              valueWidget ??
                  const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mainBlue,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildActivityItem(String activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.history, color: mainBlue),
        title: Text(activity, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KPI value widgets
// -----------------------------------------------------------------------------

/// Avg company rating as "X.Y★" using SupabaseService.companyRatingsSummaryAggregate()
class _CustomerSatisfactionValue extends StatelessWidget {
  const _CustomerSatisfactionValue();
  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: svc.SupabaseService.companyRatingsSummaryAggregate(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: LinearProgressIndicator(minHeight: 4),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return const Text(
            '—',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          );
        }
        final overall = (snap.data!['overall'] as Map<String, dynamic>?);
        final avg = (overall?['avg'] as num?)?.toDouble() ?? 0.0;
        return Text(
          '${avg.toStringAsFixed(1)}★',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: mainBlue,
          ),
        );
        // If you later want last-30-days, add another method and display here.
      },
    );
  }
}

/// Total leads count (uses your existing getLeads() service)
class _LeadsCountValue extends StatelessWidget {
  const _LeadsCountValue();
  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: svc.SupabaseService.getLeads(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: LinearProgressIndicator(minHeight: 4),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return const Text(
            '—',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          );
        }
        final count = snap.data!.length;
        return Text(
          '$count',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: mainBlue,
          ),
        );
      },
    );
  }
}
