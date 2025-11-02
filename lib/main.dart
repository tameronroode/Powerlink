import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/start_screen.dart';
import 'screens/sign_in.dart';
import 'screens/sign_up.dart';
import 'screens/load_screen.dart';
import 'screens/employee_dashboard.dart';
import 'screens/manager_dashboard.dart';
import 'screens/manage_users_screen.dart';
import 'screens/customer_dashboard.dart';
import 'screens/add_customer_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase before runApp
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SB_URL',
      defaultValue: 'https://pqtkuyspjbnijmcdnipf.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SB_ANON',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxdGt1eXNwamJuaWptY2RuaXBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NDE3MDAsImV4cCI6MjA3NjExNzcwMH0.7Vs_aPGCfkp26r_FHH4FJ7qL3WCZYQbEfhsBAD6K8uk',
    ),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerLink CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF182D53),
      ),

      // Start app on StartScreen (splash → sign in)
      initialRoute: '/start',

      // ✅ Register all routes
      routes: {
        '/start': (_) => const StartScreen(),
        '/login': (_) => const SignIn(),
        '/signup': (_) => const SignUp(),
        '/load': (_) => const LoadScreen(),
        '/employee_dashboard': (_) => const EmployeeDashboard(),
        '/manager_dashboard': (_) => const ManagerDashboard(),
        '/manage_users': (_) => const ManageUsersScreen(),
        '/customers': (_) => const CustomerDashboard(),
        '/add_customer': (_) => const AddCustomerScreen(),
      },
    );
  }
}
