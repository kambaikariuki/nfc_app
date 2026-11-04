import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nfc_app/screens/auth/sign_up.dart';
import 'package:nfc_app/services/auth_service.dart';
import 'package:nfc_app/screens/operator_home.dart';
import 'package:nfc_app/screens/passenger_home.dart';
import 'package:nfc_app/screens/splash_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Passenger';
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _fieldsFade;
  late Animation<double> _buttonFade;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.45, curve: Curves.easeIn),
    );

    _fieldsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
    );

    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    );

    _footerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.login(
        role: _selectedRole,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (_selectedRole == 'Passenger') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PassengerHome()),
        );
      } else if (_selectedRole == 'Operator') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OperatorHome()),
        );
      } else {
        throw Exception('Invalid user role');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Shared input decoration with white-tinted styling for dark background
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          },
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/nganya_3.jpg', fit: BoxFit.cover),

          // Solid dark overlay
          Container(color: Colors.black.withOpacity(0.55)),

          // Scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: const Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Fields: role dropdown + email + password
                    FadeTransition(
                      opacity: _fieldsFade,
                      child: Column(
                        children: [
                          // Role dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            dropdownColor: const Color(0xFF1C1C1C),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Account type'),
                            items: const [
                              DropdownMenuItem(
                                value: 'Passenger',
                                child: Text('Passenger'),
                              ),
                              DropdownMenuItem(
                                value: 'Operator',
                                child: Text('Operator'),
                              ),
                            ],
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _selectedRole = value);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextField(
                            controller: _usernameController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Email'),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Password'),
                            onSubmitted: (_) {
                              if (!_isLoading) _login();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login button
                    FadeTransition(
                      opacity: _buttonFade,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer: forgot password + sign up
                    FadeTransition(
                      opacity: _footerFade,
                      child: Column(
                        children: [
                          // const Text(
                          //   'Forgot Password?',
                          //   style: TextStyle(
                          //     fontSize: 14,
                          //     color: Colors.white60,
                          //   ),
                          // ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign Up here',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
