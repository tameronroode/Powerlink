import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../models/employee.dart';
import '../models/manager.dart';

class AuthService {
  AuthService._();
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;

  SupabaseClient get _supa => Supabase.instance.client;

  // ---------------------------
  // Public Sign Up Entrypoints
  // ---------------------------

  Future<Customer?> signUpCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _signUpAndInsert<Customer>(
      email: email,
      password: password,
      role: 'Customer',
      table: 'customers',
      rowBuilder: (uid, emailL) => {
        // if you have this column; otherwise remove this line:
        'auth_user_id': uid,
        'first_name': firstName,
        'last_name': lastName,
        'email': emailL, // lowercase
        'phone': phone ?? '',
        'role': 'Customer',
      },
      fromJson: Customer.fromJson,
      onConflictColumn: 'email', // lowercase, matches UNIQUE on email
    );
  }

  Future<Employee?> signUpEmployee({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String role = 'Employee',
    String? phone,
  }) async {
    return _signUpAndInsert<Employee>(
      email: email,
      password: password,
      role: role, // 'Employee' or 'Manager'
      table: 'employees',
      rowBuilder: (uid, emailL) => {
        'auth_user_id': uid,
        'first_name': firstName,
        'last_name': lastName,
        'email': emailL,
        'phone': phone ?? '',
        'role': role,
      },
      fromJson: Employee.fromJson,
      onConflictColumn: 'email',
    );
  }

  Future<Manager?> signUpManager({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String department = '',
  }) async {
    return _signUpAndInsert<Manager>(
      email: email,
      password: password,
      role: 'Manager',
      table: 'managers',
      rowBuilder: (uid, emailL) => {
        'auth_user_id': uid,
        'first_name': firstName,
        'last_name': lastName,
        'email': emailL,
        'phone': phone ?? '',
        'department': department,
        'role': 'Manager',
      },
      fromJson: Manager.fromJson,
      onConflictColumn: 'email',
    );
  }

  // ---------------------------
  // Sign In / Out
  // ---------------------------

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supa.auth.signInWithPassword(
      email: email.trim().toLowerCase(), // normalize
      password: password,
    );
  }

  Future<void> signOut() => _supa.auth.signOut();

  // ---------------------------
  // Helper
  // ---------------------------

  Future<T?> _signUpAndInsert<T>({
    required String email,
    required String password,
    required String role,
    required String table,
    required Map<String, dynamic> Function(
      String? authUserId,
      String emailLower,
    )
    rowBuilder,
    required T Function(Map<String, dynamic>) fromJson,
    required String onConflictColumn, // must match a UNIQUE/PK column
  }) async {
    final emailLower = email.trim().toLowerCase();

    // 1) Create auth user with metadata
    final authRes = await _supa.auth.signUp(
      email: emailLower,
      password: password,
      data: {'role': role, 'email': emailLower},
    );

    final uid = authRes.user?.id; // can be null if email confirmation is on

    // 2) Upsert profile row
    final payload = rowBuilder(uid, emailLower);

    final inserted = await _supa
        .from(table)
        .upsert(payload, onConflict: onConflictColumn)
        .select()
        .limit(1);

    if (inserted.isEmpty) return null;

    return fromJson(inserted.first);
  }
}
