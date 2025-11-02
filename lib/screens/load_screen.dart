import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key});

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted) return;
    if (user == null) {
      
      Navigator.pushReplacementNamed(context, '/sign_in');
    } else {
      Navigator.pushReplacementNamed(context, '/sign_in');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
