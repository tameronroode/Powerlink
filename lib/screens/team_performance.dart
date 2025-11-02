import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';

class TeamPerformanceScreen extends StatefulWidget {
  const TeamPerformanceScreen({super.key});

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  bool _loading = true;
  String? _error;
  String _query = '';
  _Sort _sort = _Sort.bestFirst;

  // Aggregated rows
  List<_EmployeeAgg> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    Supabase.instance.client
        .channel('public:performance_records')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'performance_records',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SupabaseService.performanceRecords(limit: 1000);
      // group by employee_id
      final Map<int, _EmployeeAgg> byEmp = {};
      for (final r in rows) {
        final id = (r['employee_id'] ?? 0) as int;
        final name =
            '${(r['employees']?['first_name'] ?? '')} ${(r['employees']?['last_name'] ?? '')}'
                .trim();
        final tasks = (r['task_completed'] ?? 0) as int;
        final rating = (r['customer_satisfaction_score'] ?? 0) as num;

        byEmp.putIfAbsent(id, () => _EmployeeAgg(id: id, name: name));
        final agg = byEmp[id]!;
        agg.taskTotal += tasks;
        if (rating > 0) {
          agg.ratingSum += rating.toDouble();
          agg.ratingCnt += 1;
        }
      }
      setState(() => _rows = byEmp.values.toList());
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // search + sort
    var list = _rows
        .where((r) => r.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    switch (_sort) {
      case _Sort.bestFirst:
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case _Sort.mostTasks:
        list.sort((a, b) => b.taskTotal.compareTo(a.taskTotal));
        break;
      case _Sort.aToZ:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    // team KPIs
    final teamTasks = list.fold<int>(0, (s, r) => s + r.taskTotal);
    final teamCountWithRatings = list.where((r) => r.ratingCnt > 0).length;
    final teamAvg = teamCountWithRatings == 0
        ? 0.0
        : list
                  .where((r) => r.ratingCnt > 0)
                  .fold<double>(0.0, (s, r) => s + r.avgRating) /
              teamCountWithRatings;
    final badge = _badge(teamAvg);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Performance'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search + sort
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search teammate',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<_Sort>(
                      value: _sort,
                      items: const [
                        DropdownMenuItem(
                          value: _Sort.bestFirst,
                          child: Text('Best first'),
                        ),
                        DropdownMenuItem(
                          value: _Sort.mostTasks,
                          child: Text('Most tasks'),
                        ),
                        DropdownMenuItem(
                          value: _Sort.aToZ,
                          child: Text('A → Z'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _sort = v ?? _Sort.bestFirst),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Team KPIs
                Card(
                  child: ListTile(
                    leading: Text(
                      badge.$2,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      'Team avg rating: ${teamAvg.toStringAsFixed(2)}/5',
                    ),
                    subtitle: Text(
                      'Total tasks: $teamTasks • Members rated: $teamCountWithRatings',
                    ),
                    trailing: Text(
                      badge.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (list.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('No data yet.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final b = _badge(r.avgRating);
                      return ListTile(
                        leading: CircleAvatar(child: Text(r.initials)),
                        title: Text(r.name),
                        subtitle: Text(
                          'Tasks: ${r.taskTotal} • Avg: ${r.avgRating.toStringAsFixed(2)}/5',
                        ),
                        trailing: Text(
                          b.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  // simple badge rule
  (String, String) _badge(double avg) {
    if (avg >= 4.5) return ('Great', '😄');
    if (avg >= 3.5) return ('Good', '🙂');
    if (avg > 0) return ('Needs work', '😕');
    return ('No ratings', '—');
  }
}

enum _Sort { bestFirst, mostTasks, aToZ }

// tiny agg model
class _EmployeeAgg {
  final int id;
  final String name;
  int taskTotal = 0;
  double ratingSum = 0;
  int ratingCnt = 0;

  _EmployeeAgg({required this.id, required this.name});

  double get avgRating => ratingCnt == 0 ? 0.0 : ratingSum / ratingCnt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1)
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    return (parts.first.isEmpty ? '' : parts.first[0]) +
        (parts.last.isEmpty ? '' : parts.last[0]).toUpperCase();
  }
}
