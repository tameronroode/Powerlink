import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';

/// ------------------------------------------------------------
/// LEADS (Employee create-only + Manager view/assign)
/// ------------------------------------------------------------
/// Aligns with SupabaseService helper:
/// - visibleLeads(): returns id, customer_id, assigned_employee_id, source, lead_status, date_created
/// - createLead(...)
/// - assignLeadToEmployee(...)
///
/// Tables:
/// - customers(customer_id int, first_name text, last_name text)
/// - employees(employee_id int, first_name text, last_name text)
/// - leads(id int, customer_id int, assigned_employee_id int?, source text, lead_status text, date_created timestamptz)
/// ------------------------------------------------------------

/* ========================= EMPLOYEE ========================= */

class EmployeeLeadsScreen extends StatefulWidget {
  const EmployeeLeadsScreen({super.key});
  @override
  State<EmployeeLeadsScreen> createState() => _EmployeeLeadsScreenState();
}

class _EmployeeLeadsScreenState extends State<EmployeeLeadsScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lead'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: const _EmployeeBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Lead', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const _AddLeadSheet(),
          );
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Lead created')));
          }
        },
      ),
    );
  }
}

class _EmployeeBody extends StatelessWidget {
  const _EmployeeBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Tap the 'Add Lead' button to create a new lead.\n"
          "Employees don’t see the full lead list.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Bottom sheet used by employees to create a lead
class _AddLeadSheet extends StatefulWidget {
  const _AddLeadSheet();
  @override
  State<_AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends State<_AddLeadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sourceCtrl = TextEditingController(text: 'Manual');
  String _status = 'New';
  CustomerRow? _selectedCustomer;
  late Future<List<CustomerRow>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _fetchCustomers();
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add Lead',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sourceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a source'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'New', child: Text('New')),
                      DropdownMenuItem(
                        value: 'Contacted',
                        child: Text('Contacted'),
                      ),
                      DropdownMenuItem(
                        value: 'Qualified',
                        child: Text('Qualified'),
                      ),
                      DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'New'),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<CustomerRow>>(
                    future: _customersFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const _FieldSkeleton(label: 'Customer');
                      }
                      if (snap.hasError) {
                        return _FieldError(
                          label: 'Customer',
                          message: snap.error.toString(),
                          onRetry: () => setState(
                            () => _customersFuture = _fetchCustomers(),
                          ),
                        );
                      }
                      final options = snap.data ?? const <CustomerRow>[];
                      if (options.isEmpty) {
                        return const Text(
                          'No customers found. Create a customer first.',
                          style: TextStyle(color: Colors.redAccent),
                        );
                      }
                      return DropdownButtonFormField<CustomerRow>(
                        value: _selectedCustomer,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          border: OutlineInputBorder(),
                        ),
                        items: options
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.fullName),
                              ),
                            )
                            .toList(),
                        validator: (v) =>
                            v == null ? 'Select a customer' : null,
                        onChanged: (v) => setState(() => _selectedCustomer = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Create Lead'),
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = _selectedCustomer!;

    try {
      // verify FK target exists
      final exists = await Supabase.instance.client
          .from('customers')
          .select('customer_id')
          .eq('customer_id', customer.id)
          .maybeSingle();
      if (exists == null) {
        throw Exception('Selected customer does not exist');
      }

      await SupabaseService.createLead(
        source: _sourceCtrl.text.trim(),
        leadStatus: _status,
        customerId: customer.id,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create lead: $e')));
    }
  }

  Future<List<CustomerRow>> _fetchCustomers() async {
    final res = await Supabase.instance.client
        .from('customers')
        .select('customer_id, first_name, last_name')
        .order('first_name', ascending: true);
    return (res as List<dynamic>).map((m) {
      final map = Map<String, dynamic>.from(m as Map);
      return CustomerRow(
        id: map['customer_id'] as int,
        firstName: map['first_name'] as String?,
        lastName: map['last_name'] as String?,
      );
    }).toList();
  }
}

class CustomerRow {
  CustomerRow({required this.id, this.firstName, this.lastName});
  final int id;
  final String? firstName;
  final String? lastName;

  String get fullName {
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    if (fn.isEmpty && ln.isEmpty) return id.toString();
    return [fn, ln].where((s) => s.isNotEmpty).join(' ');
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ],
  );
}

class _FieldError extends StatelessWidget {
  const _FieldError({
    required this.label,
    required this.message,
    required this.onRetry,
  });
  final String label;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ],
  );
}

/* ========================== MANAGER ========================== */

class ManagerLeadsDashboard extends StatefulWidget {
  const ManagerLeadsDashboard({super.key});
  @override
  State<ManagerLeadsDashboard> createState() => _ManagerLeadsDashboardState();
}

class _ManagerLeadsDashboardState extends State<ManagerLeadsDashboard> {
  static const Color mainBlue = Color(0xFF182D53);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseService.visibleLeads();
  }

  Future<void> _reload() async {
    setState(() => _future = SupabaseService.visibleLeads());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads (Manager)'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
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
                final leadId = m['id'] as int;
                final status = (m['lead_status'] ?? 'New').toString();
                final created = m['date_created'];
                final assigned = m['assigned_employee_id'] as int?;
                return ListTile(
                  leading: const Icon(Icons.tag_outlined),
                  title: Text(m['source']?.toString() ?? 'Lead'),
                  subtitle: Text('$status • ${_fmtDate(created)}'),
                  trailing: TextButton.icon(
                    onPressed: () => _openAssign(context, leadId, assigned),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(assigned == null ? 'Assign' : 'Reassign'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(dynamic d) {
    final dt = d is DateTime ? d : DateTime.tryParse('$d');
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openAssign(
    BuildContext context,
    int leadId,
    int? current,
  ) async {
    final chosen = await showDialog<EmployeeRow?>(
      context: context,
      builder: (_) => _AssignEmployeeDialog(currentEmployeeId: current),
    );
    if (chosen == null) return;
    try {
      await SupabaseService.assignLeadToEmployee(
        leadId: leadId,
        employeeId: chosen.employeeId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lead assigned')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Assign failed: $e')));
    }
  }
}

class _AssignEmployeeDialog extends StatefulWidget {
  const _AssignEmployeeDialog({required this.currentEmployeeId});
  final int? currentEmployeeId;
  @override
  State<_AssignEmployeeDialog> createState() => _AssignEmployeeDialogState();
}

class _AssignEmployeeDialogState extends State<_AssignEmployeeDialog> {
  late Future<List<EmployeeRow>> _emps;
  EmployeeRow? _selected;

  @override
  void initState() {
    super.initState();
    _emps = _fetchEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign to employee'),
      content: FutureBuilder<List<EmployeeRow>>(
        future: _emps,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Text('Failed to load employees: ${snap.error}');
          }
          final options = snap.data ?? const <EmployeeRow>[];
          if (options.isEmpty) return const Text('No employees found.');
          return DropdownButton<EmployeeRow>(
            value: _selected,
            isExpanded: true,
            items: options
                .map((e) => DropdownMenuItem(value: e, child: Text(e.fullName)))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop<EmployeeRow>(context, _selected),
          child: const Text('Assign'),
        ),
      ],
    );
  }

  Future<List<EmployeeRow>> _fetchEmployees() async {
    final res = await Supabase.instance.client
        .from('employees')
        .select('employee_id, first_name, last_name')
        .order('first_name');
    return (res as List<dynamic>).map((m) {
      final map = Map<String, dynamic>.from(m as Map);
      return EmployeeRow(
        employeeId: map['employee_id'] as int,
        firstName: map['first_name'] as String?,
        lastName: map['last_name'] as String?,
      );
    }).toList();
  }
}

class EmployeeRow {
  EmployeeRow({required this.employeeId, this.firstName, this.lastName});
  final int employeeId;
  final String? firstName;
  final String? lastName;

  String get fullName {
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    if (fn.isEmpty && ln.isEmpty) return employeeId.toString();
    return [fn, ln].where((s) => s.isNotEmpty).join(' ');
  }
}
