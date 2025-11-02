// lib/screens/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';
import '../models/employee.dart';
import '../models/customer.dart';

enum UserType { employee, customer }

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const Color mainBlue = Color(0xFF182D53);

  // Loading / error
  bool _loading = true;
  String? _error;

  // Data
  List<Employee> _employees = [];
  List<Customer> _customers = [];

  // Create form controllers (used in bottom sheet)
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Employee-specific
  final _roleCtrl = TextEditingController(text: 'employee');

  // Customer-specific
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _customerTypeCtrl = TextEditingController(); // e.g. 'standard', 'vip'

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _customerTypeCtrl.dispose();
    super.dispose();
  }

  // ---------------- Load ----------------
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final empRows = await SupabaseService.employees();
      final custRows = await SupabaseService.customers();

      _employees = empRows.map(Employee.fromRow).toList();
      _customers = custRows.map(Customer.fromRow).toList();

      // Client-side sort by first name (case-insensitive)
      _employees.sort(
        (a, b) =>
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
      );
      _customers.sort(
        (a, b) =>
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
      );
    } on PostgrestException catch (e) {
      _error = '${e.message} (code: ${e.code})';
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  // ---------------- Create ----------------
  Future<void> _createEmployee() async {
    final payload = {
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim().toLowerCase(),
      'role': _roleCtrl.text.trim().isEmpty
          ? 'employee'
          : _roleCtrl.text.trim(),
    };

    if ((payload['first_name'] as String).isEmpty ||
        (payload['email'] as String).isEmpty) {
      _snack('First name and Email are required.');
      return;
    }

    try {
      await SupabaseService.createEmployee(payload);
      _clearCreateFields();
      await _loadAll();
      _snack('Employee created.');
    } on PostgrestException catch (e) {
      _snack('Create failed: ${e.message} (code: ${e.code})');
    } catch (e) {
      _snack('Create failed: $e');
    }
  }

  Future<void> _createCustomer() async {
    final payload = {
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim().toLowerCase(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_customerTypeCtrl.text.trim().isNotEmpty)
        'customer_type': _customerTypeCtrl.text.trim(),
    };

    if ((payload['first_name'] as String).isEmpty ||
        (payload['email'] as String).isEmpty) {
      _snack('First name and Email are required.');
      return;
    }

    try {
      await SupabaseService.createCustomer(payload);
      _clearCreateFields();
      await _loadAll();
      _snack('Customer created.');
    } on PostgrestException catch (e) {
      _snack('Create failed: ${e.message} (code: ${e.code})');
    } catch (e) {
      _snack('Create failed: $e');
    }
  }

  void _clearCreateFields() {
    _firstCtrl.clear();
    _lastCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _addressCtrl.clear();
    _customerTypeCtrl.clear();
    _roleCtrl.text = 'employee';
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: mainBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: mainBlue,
          tabs: const [
            Tab(text: 'Employees', icon: Icon(Icons.badge)),
            Tab(text: 'Customers', icon: Icon(Icons.supervisor_account)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _Error(message: _error!, onRetry: _loadAll)
          : TabBarView(
              controller: _tab,
              children: [
                _EmployeesList(items: _employees),
                _CustomersList(items: _customers),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _showCreateSheet() {
    final theme = Theme.of(context);
    // default selection: based on current tab
    UserType selectedType = _tab.index == 0
        ? UserType.employee
        : UserType.customer;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Widget chip(UserType t, String label, IconData icon) {
              final isSelected = selectedType == t;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : mainBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
                selected: isSelected,
                selectedColor: mainBlue,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : mainBlue,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setModalState(() => selectedType = t),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + type chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add User',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: mainBlue,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          chip(
                            UserType.employee,
                            'Employee',
                            Icons.badge_outlined,
                          ),
                          chip(
                            UserType.customer,
                            'Customer',
                            Icons.supervisor_account_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Common fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),

                  // Conditional fields
                  if (selectedType == UserType.employee) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _roleCtrl.text.isEmpty
                          ? 'employee'
                          : _roleCtrl.text,
                      items: const [
                        DropdownMenuItem(
                          value: 'employee',
                          child: Text('Employee'),
                        ),
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text('Manager'),
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Role'),
                      onChanged: (v) => _roleCtrl.text = (v ?? 'employee'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _phoneCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerTypeCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Customer Type (optional)',
                        hintText: 'e.g. standard, vip',
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: mainBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(
                        selectedType == UserType.employee
                            ? 'Create Employee'
                            : 'Create Customer',
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        if (selectedType == UserType.employee) {
                          await _createEmployee();
                        } else {
                          await _createCustomer();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =============== Lists ===============

class _EmployeesList extends StatelessWidget {
  const _EmployeesList({required this.items});
  final List<Employee> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No employees yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final e = items[i];
        final initial = (e.firstName.isEmpty ? '?' : e.firstName[0])
            .toUpperCase();
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF182D53),
            foregroundColor: Colors.white,
            child: Text(initial),
          ),
          title: Text(e.name),
          subtitle: Text('${e.role} • ${e.email}'),
        );
      },
    );
  }
}

class _CustomersList extends StatelessWidget {
  const _CustomersList({required this.items});
  final List<Customer> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No customers yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final c = items[i];
        final initial = (c.firstName.isEmpty ? '?' : c.firstName[0])
            .toUpperCase();
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF182D53),
            foregroundColor: Colors.white,
            child: Text(initial),
          ),
          title: Text(c.name),
          subtitle: Text(c.email),
        );
      },
    );
  }
}

// =============== Error Widget ===============

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
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF182D53),
              foregroundColor: Colors.white,
            ),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
