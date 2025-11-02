import 'package:flutter/material.dart';
import 'package:powerlink_crm/services/authentication.dart';
import 'sign_in.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final departmentController = TextEditingController(); // only for Manager

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final List<String> _roles = const ['Customer', 'Employee', 'Manager'];
  String _selectedRole = 'Customer';

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  String? _required(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email';
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signUp() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _isLoading = true);

    final auth = AuthService();
    dynamic result;

    try {
      final emailLower = emailController.text.trim().toLowerCase();

      if (_selectedRole == 'Customer') {
        result = await auth.signUpCustomer(
          firstName: firstNameController.text.trim(), 
          lastName: lastNameController.text.trim(), 
          email: emailLower, 
          password: passwordController.text,
          phone: phoneController.text.trim(),
        );
      } else if (_selectedRole == 'Employee') {
        result = await auth.signUpEmployee(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailLower,
          password: passwordController.text,
          phone: phoneController.text.trim(),
          role: 'Employee', // keep title-case string to mirror DB Role
        );
      } else {
        // Manager
        result = await auth.signUpManager(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailLower,
          password: passwordController.text,
          phone: phoneController.text.trim(),
          department: departmentController.text.trim(),
        );
      }
    } catch (e) {
      result = null;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (result != null) {
      // Success → route by role
      switch (_selectedRole) {
        case 'Customer':
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/customers', (r) => false);
          break;
        case 'Employee':
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/employee_dashboard', (r) => false);
          break;
        case 'Manager':
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/manager_dashboard', (r) => false);
          break;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up failed. The email may already be in use.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryCol = Color(0xFF182D53);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              const SizedBox(height: 50),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/signup_illustration.png',
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Create Your Account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primaryCol,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _pad(
                      TextFormField(
                        controller: firstNameController,
                        decoration: _decoration(
                          'First Name',
                          Icons.person_outline,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(v, label: 'First name'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _pad(
                      TextFormField(
                        controller: lastNameController,
                        decoration: _decoration(
                          'Last Name',
                          Icons.person_outline,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(v, label: 'Last name'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _pad(
                      TextFormField(
                        controller: emailController,
                        decoration: _decoration(
                          'Email Address',
                          Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _pad(
                      TextFormField(
                        controller: phoneController,
                        decoration: _decoration(
                          'Phone Number (Optional)',
                          Icons.phone_outlined,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _pad(
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: _decoration('Password', Icons.lock_outline)
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                        textInputAction: TextInputAction.next,
                        validator: _validatePassword,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _pad(
                      TextFormField(
                        controller: confirmController,
                        obscureText: _obscureConfirm,
                        decoration:
                            _decoration(
                              'Confirm Password',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                        textInputAction: TextInputAction.done,
                        validator: _validateConfirm,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Select Role',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRole = v ?? 'Customer'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Department (only if Manager)
                    if (_selectedRole == 'Manager')
                      _pad(
                        TextFormField(
                          controller: departmentController,
                          decoration: _decoration(
                            'Department (Optional)',
                            Icons.apartment_outlined,
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ),

                    const SizedBox(height: 24),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C426A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SignIn()),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: "Sign In",
                        style: TextStyle(
                          color: Color(0xFF3C7BED),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon),
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
  );

  Padding _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: child,
  );
}
