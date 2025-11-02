import 'package:flutter/material.dart';
import '../data/supabase_service.dart';
import 'project_create_screen.dart';

class ActiveProjectsScreen extends StatefulWidget {
  const ActiveProjectsScreen({super.key});
  @override
  State<ActiveProjectsScreen> createState() => _ActiveProjectsScreenState();
}

class _ActiveProjectsScreenState extends State<ActiveProjectsScreen> {
  static const Color mainBlue = Color.fromARGB(255, 12, 28, 58);

  bool _loading = true;
  String? _error;

  List<_Person> _managers = [];
  List<_Person> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mRows = await SupabaseService.activeProjectsManagers();
      final eRows = await SupabaseService.activeProjectsEmployees();

      _managers = mRows
          .map(
            (r) => _Person(
              (r['display_name'] ?? r['email'] ?? 'Unknown').toString(),
              ((r['count'] as num?) ?? 0).toInt(),
            ),
          )
          .toList();

      _employees = eRows
          .map(
            (r) => _Person(
              (r['display_name'] ?? r['email'] ?? 'Unknown').toString(),
              ((r['count'] as num?) ?? 0).toInt(),
            ),
          )
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _totalActive =>
      _managers.fold<int>(0, (s, p) => s + p.count) +
      _employees.fold<int>(0, (s, p) => s + p.count);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Projects'),
          backgroundColor: const Color.fromARGB(255, 2, 18, 50),
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Managers'),
              Tab(text: 'Employees'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    // KPIs
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _kpi(
                            Icons.folder_open,
                            'Total Active',
                            '$_totalActive',
                          ),
                          _kpi(
                            Icons.supervisor_account_outlined,
                            'Managers',
                            '${_managers.length}',
                          ),
                          _kpi(
                            Icons.badge_outlined,
                            'Employees',
                            '${_employees.length}',
                          ),
                        ],
                      ),
                    ),
                    // Tabs
                    Expanded(
                      child: TabBarView(
                        children: [
                          _PeopleList(
                            people: _managers,
                            emptyText: 'No manager activity.',
                          ),
                          _PeopleList(
                            people: _employees,
                            emptyText: 'No employee activity.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        // Two FABs: New Project + Refresh
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab-new',
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProjectCreateScreen(),
                  ),
                );
                if (created != null) {
                  _load();
                }
              },
              backgroundColor: const Color.fromARGB(255, 239, 240, 240),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'fab-refresh',
              onPressed: _load,
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 14, 20, 56),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // KPI chip
  static Widget _kpi(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
        boxShadow: kElevationToShadow[1],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeopleList extends StatefulWidget {
  const _PeopleList({required this.people, required this.emptyText});
  final List<_Person> people;
  final String emptyText;

  @override
  State<_PeopleList> createState() => _PeopleListState();
}

class _PeopleListState extends State<_PeopleList> {
  String query = '';
  _Sort sort = _Sort.mostActive;

  @override
  Widget build(BuildContext context) {
    final filtered = _apply(widget.people);
    if (filtered.isEmpty) {
      return Column(
        children: [
          _controls(),
          Expanded(child: Center(child: Text(widget.emptyText))),
        ],
      );
    }
    return Column(
      children: [
        _controls(),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = filtered[i];
              final color = p.count == 0
                  ? Colors.grey
                  : (p.count > 5 ? Colors.green : Colors.orange);
              return ListTile(
                leading: CircleAvatar(child: Text(_initials(p.name))),
                title: Text(p.name),
                subtitle: Text(
                  '${p.count} active project${p.count == 1 ? '' : 's'}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.5)),
                  ),
                  child: Text(
                    '${p.count}',
                    style: TextStyle(
                      color: color.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () {
                  // (Optional) Navigate to a detail list of this person's projects
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Open ${p.name}')));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search names…',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<_Sort>(
            value: sort,
            items: const [
              DropdownMenuItem(
                value: _Sort.mostActive,
                child: Text('Most Active'),
              ),
              DropdownMenuItem(value: _Sort.aToZ, child: Text('A → Z')),
              DropdownMenuItem(value: _Sort.zToA, child: Text('Z → A')),
            ],
            onChanged: (v) => setState(() => sort = v ?? _Sort.mostActive),
          ),
        ],
      ),
    );
  }

  List<_Person> _apply(List<_Person> list) {
    var it = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    switch (sort) {
      case _Sort.mostActive:
        it.sort((a, b) => b.count.compareTo(a.count));
        break;
      case _Sort.aToZ:
        it.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _Sort.zToA:
        it.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return it;
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Person {
  final String name;
  final int count;
  _Person(this.name, this.count);
}

enum _Sort { mostActive, aToZ, zToA }
