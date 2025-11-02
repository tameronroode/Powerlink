import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});
  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.getLeads(); // uses your service
  }

  Future<void> _reload() async {
    setState(() => _future = SupabaseService.getLeads());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Error(message: snap.error.toString(), onRetry: _reload);
          }

          final items = snap.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('No leads yet.'));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = items[i];
                final source =
                    (m['source'] ?? m['lead_source'] ?? m['leadSource'])
                        ?.toString();
                final leadStatus =
                    (m['lead_status'] ?? m['leadStatus'] ?? m['status'])
                        ?.toString();
                final created =
                    m['date_created'] ?? m['created_at'] ?? m['dateCreated'];

                return ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: Text(source ?? 'Lead'),
                  subtitle: Text(
                    '${leadStatus ?? 'New'} • ${_fmtDate(created)}',
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          try {
            await SupabaseService.createLead(
              source: 'Manual',
              leadStatus: 'New',
              customerId: 1, // TODO: replace with a real customer_id
              // assignedEmployeeId: <employee_id>, // optional
            );
            if (!mounted) return;
            await _reload();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Lead created')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create lead: $e')),
            );
          }
        },
      ),
    );
  }

  // ---------- helpers ----------
  static String _fmtDate(dynamic d) {
    if (d == null) return '';
    final dt = d is DateTime ? d : DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
