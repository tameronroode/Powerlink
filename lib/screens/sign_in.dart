import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:powerlink_crm/services/authentication.dart';
import 'package:powerlink_crm/screens/employee_dashboard.dart';
import 'package:powerlink_crm/screens/customer_dashboard.dart';
import 'package:powerlink_crm/screens/manager_dashboard.dart';
import 'forgotten_password_screen.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final emailLower = emailController.text.trim().toLowerCase();

      // === 1) Auth (direct Supabase) ===
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: emailLower,
        password: passwordController.text,
      );

      // Log basic auth facts
      debugPrint('AUTH userId=${res.user?.id}');
      debugPrint('AUTH session=${res.session != null}');
      debugPrint(
        'AUTH accessToken len=${res.session?.accessToken.length ?? 0}',
      );

      // (Optional) peek at role claim
      final token = res.session?.accessToken;
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          String pad(String s) =>
              s.padRight(s.length + ((4 - s.length % 4) % 4), '=');
          final payload = String.fromCharCodes(base64Url.decode(pad(parts[1])));
          debugPrint(
            'JWT payload: $payload',
          ); // look for "email" and any "role"/"app_metadata"
        }
      }

      if (!mounted) return;

      final client = Supabase.instance.client;

      final s = client.auth.currentSession;
      debugPrint(
        '[auth] hasSession=${s != null} email=${s?.user.email} '
        'jwt=${(s?.accessToken ?? "").substring(0, 20)}...',
      );


      final user = res.user ?? client.auth.currentUser;

      if (user == null) {
        _showSnack('Sign-in failed. Check your email & password.');
        return;
      }

      // === 2) Role from metadata (fast path) ===
      final metaRole = (user.userMetadata?['role'] as String?)?.toLowerCase();
      if (metaRole != null && metaRole.isNotEmpty) {
        _routeByRole(metaRole);
        return;
      }

      // === 3) DB fallback by Email (case-sensitive schema) ===
      final role = await _resolveRoleByEmail(emailLower);
      if (role != null) {
        _routeByRole(role);
        return;
      }

      // === 4) Unknown ===
      _showSnack('Unknown user type. Ask support to check your profile.');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } on PostgrestException catch (e) {
      _showSnack('Database error: ${e.message}');
    } catch (e) {
      _showSnack('Sign-in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  Future<String?> _resolveRoleByEmail(String emailLower) async {
    final supa = Supabase.instance.client;

    final mgr = await supa
        .from('managers')
        .select('role')
        .eq('email', emailLower)
        .limit(1);

    if (mgr.isNotEmpty) return 'manager';

    final empRows = await supa
        .from('employees')
        .select('role')
        .eq('email', emailLower)
        .limit(1);

    if (empRows.isNotEmpty) {
      final r = (empRows.first['role'] as String?)?.toLowerCase();
      return (r == null || r.isEmpty) ? 'employee' : r;
    }

    final custRows = await supa
        .from('customers')
        .select('email')
        .eq('email', emailLower)
        .limit(1);

    if (custRows.isNotEmpty) return 'customer';

    return null;
  }

  void _routeByRole(String roleLower) {
    switch (roleLower) {
      case 'manager':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ManagerDashboard()),
          (route) => false,
        );
        break;
      case 'employee':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
          (route) => false,
        );
        break;
      case 'customer':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
          (route) => false,
        );
        break;
      default:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
          (route) => false,
        );
        break;
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                const SizedBox(height: 50),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/welcome_illustration.png',
                    height: 200,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Sign In To PowerLink",
                  style: textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 23),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgottenPassword(),
                      ),
                    );
                  },
                  child: const Text("Forgot Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
