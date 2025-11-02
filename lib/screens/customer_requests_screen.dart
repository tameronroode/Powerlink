import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerRequestScreen extends StatefulWidget {
  const CustomerRequestScreen({super.key});

  @override
  State<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _CustomerRequestScreenState extends State<CustomerRequestScreen> {
  static const Color mainBlue = Color(0xFF182D53);
  final _sb = Supabase.instance.client;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _sb
        .channel('public:service_tickets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_tickets',
          callback: (_) => _loadTickets(),
        )
        .subscribe();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // With your FK cleanup, this simple embed works:
      final rows = await _sb
          .from('service_tickets')
          .select(r'''
            id, customer_id, employee_id, manager_id,
            issue_description, status, date_opened, date_closed,
            customers:customer_id ( first_name, last_name ),
            employees:employee_id ( first_name, last_name ),
            managers:manager_id ( first_name, last_name )
          ''')
          .order('date_opened', ascending: false);

      _tickets = List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    await _sb
        .from('service_tickets')
        .update({'status': newStatus})
        .eq('id', id);
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _subjectFromIssue(String? issue) {
    if (issue == null) return 'Request';
    final s = issue.indexOf('['), e = issue.indexOf(']');
    return (s >= 0 && e > s) ? issue.substring(s + 1, e) : 'Request';
  }

  String _messageFromIssue(String? issue) {
    if (issue == null) return '';
    final e = issue.indexOf(']');
    return (e >= 0 && e + 1 < issue.length)
        ? issue.substring(e + 1).trimLeft()
        : issue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Customer Requests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $_error', textAlign: TextAlign.center),
              ),
            )
          : _tickets.isEmpty
          ? const Center(child: Text('No requests yet'))
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _tickets.length,
                itemBuilder: (_, i) => _ticketCard(_tickets[i]),
              ),
            ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final subject = _subjectFromIssue(t['issue_description']);
    final message = _messageFromIssue(t['issue_description']);
    final opened = _formatDate(t['date_opened']);

    final customer = (t['customers'] ?? {}) as Map? ?? {};
    final employee = (t['employees'] ?? {}) as Map? ?? {};
    final manager = (t['managers'] ?? {}) as Map? ?? {};

    final customerName = customer.isNotEmpty
        ? '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'
              .trim()
        : 'Customer #${t['customer_id']}';

    final assignee = employee.isNotEmpty
        ? 'Employee: ${(employee['first_name'] ?? '')} ${(employee['last_name'] ?? '')}'
              .trim()
        : manager.isNotEmpty
        ? 'Manager: ${(manager['first_name'] ?? '')} ${(manager['last_name'] ?? '')}'
              .trim()
        : (t['employee_id'] != null
              ? 'Employee #${t['employee_id']}'
              : t['manager_id'] != null
              ? 'Manager #${t['manager_id']}'
              : 'Unassigned');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ticket #${t['id']} - $subject',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Opened: $opened',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message),
            const SizedBox(height: 8),
            Text(
              'Customer: $customerName',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(assignee, style: const TextStyle(color: Colors.black54)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${t['status']}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          _updateStatus(t['id'] as int, 'In Progress'),
                      child: const Text('In Progress'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _updateStatus(t['id'] as int, 'Resolved'),
                      child: const Text('Resolve'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
