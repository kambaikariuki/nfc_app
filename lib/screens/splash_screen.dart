import 'package:flutter/material.dart';

import 'package:nfc_app/screens/auth/log_in.dart';
import 'package:nfc_app/screens/auth/sign_up.dart';
import 'package:nfc_app/services/auth_service.dart';
import 'package:nfc_app/screens/passenger/passenger_home.dart';
import 'package:nfc_app/screens/operator/operator_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _imageFade;
  late Animation<double> _buttonsFade;

  bool _isCheckingSession = true;

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

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
    );

    _imageFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
    );

    _buttonsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // Restore saved token
      await AuthService.loadToken();

      if (!mounted) return;

      // No saved session: show splash screen normally
      if (AuthService.accessToken == null) {
        setState(() {
          _isCheckingSession = false;
        });

        _controller.forward();
        return;
      }

      // Validate saved token with backend
      final user = await AuthService.getCurrentUser();

      if (!mounted) return;

      // Navigate according to authenticated role
      if (user['role'] == 'passenger') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PassengerHome(),
          ),
        );
      } else if (user['role'] == 'operator') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OperatorHome(),
          ),
        );
      } else {
        await AuthService.logout();

        if (!mounted) return;

        setState(() {
          _isCheckingSession = false;
        });

        _controller.forward();
      }
    } catch (e) {
      // Invalid session or network error
      await AuthService.logout();

      if (!mounted) return;

      setState(() {
        _isCheckingSession = false;
      });

      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/nganya.jpg', fit: BoxFit.cover),

          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),

          if (_isCheckingSession)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Column(
                        children: [
                          FadeTransition(
                            opacity: _titleFade,
                            child: const Text(
                              'MatPay',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          FadeTransition(
                            opacity: _taglineFade,
                            child: const Text(
                              'Just Tap. Fast. Convenient.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    FadeTransition(
                      opacity: _imageFade,
                      child: Image.asset(
                        'assets/nfc.png',
                        width: 200,
                        height: 200,
                      ),
                    ),

                    FadeTransition(
                      opacity: _buttonsFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 48.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => LoginPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => SignUpPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
        ],
      ),
    );
  }
}