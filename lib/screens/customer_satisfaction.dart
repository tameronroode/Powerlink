// lib/screens/customer_satisfaction.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart' as svc;

class CustomerSatisfactionScreen extends StatefulWidget {
  const CustomerSatisfactionScreen({super.key});

  @override
  State<CustomerSatisfactionScreen> createState() =>
      _CustomerSatisfactionScreenState();
}

class _CustomerSatisfactionScreenState
    extends State<CustomerSatisfactionScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  bool _loading = true;
  String? _error;
  String _query = '';

  // ratings flat list (from company_ratings)
  List<Map<String, dynamic>> _ratings = [];
  Map<String, dynamic> _summary = {
    'overall': {'avg': 0.0, 'count': 0},
  };

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    // Subscribe to company_ratings for live updates
    _channel = Supabase.instance.client
        .channel('public:company_ratings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'company_ratings',
          callback: (_) => _loadAll(),
        )
        .subscribe();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Summary (avg/count)
      
      final sum = await svc.SupabaseService.companyRatingsSummaryAggregate();

      // Recent list
      final list = await svc.SupabaseService.recentCompanyRatings(
        limit: 200,
      );

      setState(() {
        _summary = sum;
        _ratings = list;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_ratings, _query);

    final count = filtered.length;
    final avg = count == 0
        ? 0.0
        : filtered.fold<num>(0, (s, r) => s + (r['stars'] as num)).toDouble() /
              count;
    final high = filtered.where((r) => (r['stars'] as num) >= 4).length;
    final low = filtered.where((r) => (r['stars'] as num) <= 2).length;
    final badge = _bucket(avg);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Satisfaction'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Global summary from DB (avg/count)
                _SummaryCard(
                  avg: (_summary['overall']?['avg'] as num?)?.toDouble() ?? 0.0,
                  count: (_summary['overall']?['count'] as num?)?.toInt() ?? 0,
                ),
                const SizedBox(height: 12),

                // Local filter
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search comment…',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),

                // Local stats for filtered view
                Card(
                  child: ListTile(
                    leading: Text(
                      badge.$2,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      'Average (filtered): ${avg.toStringAsFixed(2)}/5',
                    ),
                    subtitle: Text('Ratings: $count • ≥4: $high • ≤2: $low'),
                    trailing: Text(
                      badge.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('No ratings yet.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      final stars = (r['stars'] as num?)?.toInt() ?? 0;
                      final comment = (r['comment'] ?? '').toString();
                      final created =
                          ((r['created_at'] ?? '').toString()).isEmpty
                          ? ''
                          : (r['created_at'] as String).substring(0, 10);

                      return ListTile(
                        leading: _pill(stars),
                        title: Text('$stars★ • $created'),
                        subtitle: Text(
                          comment.isEmpty ? 'No comment' : comment,
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> rows,
    String q,
  ) {
    if (q.trim().isEmpty) return rows;
    final lower = q.toLowerCase();
    return rows
        .where(
          (r) => (r['comment'] ?? '').toString().toLowerCase().contains(lower),
        )
        .toList();
  }

  (String, String) _bucket(double avg) {
    if (avg >= 4.5) return ('Great', '😄');
    if (avg >= 3.5) return ('Good', '🙂');
    if (avg > 0) return ('Okay', '😐');
    return ('No data', '—');
  }

  Widget _pill(int r) {
    final color = r >= 4
        ? Colors.green
        : r >= 3
        ? Colors.orange
        : Colors.red;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(
        '$r',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.avg, required this.count});
  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sentiment_satisfied, color: Colors.amber),
        title: Text('Average: ${avg.toStringAsFixed(2)}★'),
        subtitle: Text('Total ratings: $count'),
      ),
    );
  }
}
