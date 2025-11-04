// lib/screens/employee_dashboard.dart
import 'package:flutter/material.dart';

// 🔹 Local screen imports
import 'gamification.dart';
import 'messages_screen.dart';
import 'voice_ai_screen.dart';
import 'settings_screen.dart';
import 'employee_profile.dart';
// Home drill-ins:
import 'tasks_screen.dart';
import 'new_leads.dart';

// 🔹 Data and models
import '../data/supabase_service.dart' as svc; // ⬅️ alias the service
import '../models/employee.dart';
// import '../models/task.dart'; // ⬅️ optional: remove to avoid confusion

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  static const Color mainBlue = Color(0xFF182D53);

  int _selectedIndex = 0;

  bool loading = true;
  String? error;
  List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await svc.SupabaseService.employees(); // 
      employees = rows.map(Employee.fromRow).toList();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeOverview(
        onOpenTasks: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasksScreen()),
        ),
        onOpenLeads: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeLeadsScreen()),
        ),
      ),
      const EmployeeProfileScreen(),
      const MessagesScreen(),
      const VoiceAIScreen(),
      const GamificationScreen(),
      const SettingsScreen(),
    ];

    final titles = <String>[
      'Employee Dashboard',
      'Profile',
      'Messages',
      'Voice AI',
      'Gamify',
      'Settings',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: mainBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            label: 'Voice AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Gamify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeOverview extends StatefulWidget {
  const _HomeOverview({required this.onOpenTasks, required this.onOpenLeads});
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenLeads;

  @override
  State<_HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<_HomeOverview> {
  static const Color mainBlue = Color(0xFF182D53);

  // ⬇️ Use the service Task type
  late Future<List<svc.Task>> _tasksFuture;
  late Future<List<Map<String, dynamic>>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = svc.SupabaseService.myTasks(); // 
    _leadsFuture = svc.SupabaseService.getLeads(); // 
  }

  Color _dynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark ? Colors.blueAccent : mainBlue;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _dynamicColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Assigned Tasks',
            color: accent,
            onSeeAll: widget.onOpenTasks,
          ),
          FutureBuilder<List<svc.Task>>(
            
            future: _tasksFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snap.hasError) {
                return _InlineError(
                  message: snap.error.toString(),
                  onRetry: () => setState(
                    () => _tasksFuture = svc.SupabaseService.myTasks(),
                  ),
                );
              }
              final items = snap.data ?? const <svc.Task>[];
              if (items.isEmpty) {
                return _EmptyCard(
                  icon: Icons.checklist_outlined,
                  text: 'No tasks assigned yet',
                  onTap: widget.onOpenTasks,
                );
              }
              final preview = items.take(3).toList();
              return Column(
                children: preview.map((t) {
                  final due = t.dueDate != null
                      ? ' • Due ${_fmtDate(t.dueDate!)}'
                      : '';
                  return ListTile(
                    leading: Icon(Icons.checklist_outlined, color: accent),
                    title: Text(t.title),
                    subtitle: Text('${t.status}$due'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onOpenTasks,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          _SectionHeader(
            title: 'Customer Leads',
            color: accent,
            onSeeAll: widget.onOpenLeads,
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _leadsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snap.hasError) {
                return _InlineError(
                  message: snap.error.toString(),
                  onRetry: () => setState(
                    () => _leadsFuture = svc.SupabaseService.getLeads(),
                  ),
                );
              }
              final items = snap.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty) {
                return _EmptyCard(
                  icon: Icons.person_add_alt_1_outlined,
                  text: 'No leads yet — tap to view/create',
                  onTap: widget.onOpenLeads,
                );
              }
              final preview = items.take(3).toList();
              return Column(
                children: preview.map((m) {
                  final source =
                      (m['source'] ?? m['lead_source'] ?? m['leadSource'])
                          ?.toString();
                  final leadStatus =
                      (m['lead_status'] ?? m['leadStatus'] ?? m['status'])
                          ?.toString();
                  final created =
                      m['date_created'] ?? m['created_at'] ?? m['dateCreated'];
                  return ListTile(
                    leading: Icon(
                      Icons.person_add_alt_1_outlined,
                      color: accent,
                    ),
                    title: Text(source ?? 'Lead'),
                    subtitle: Text(
                      '${leadStatus ?? 'New'} • ${_fmtDateDynamic(created)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onOpenLeads,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Recent Interactions', color: accent),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const ListTile(
              leading: Icon(Icons.history),
              title: Text(
                'This area is ready for your call/email/meeting feed.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDateDynamic(dynamic d) {
    if (d == null) return '';
    final dt = d is DateTime ? d : DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return _fmtDate(dt);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.color,
    this.onSeeAll,
  });

  final String title;
  final Color color;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error: $message',
            style: TextStyle(color: errorColor),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: accent),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
