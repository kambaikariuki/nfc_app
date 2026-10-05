import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key:key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
      super.initState();
      
      // Delay before navigating to next screen 
      Timer(const Duration(seconds: 3), () {
          Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
    }
    @override
    Widget build(BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('MatPay', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
                Image.asset(
                  'assets/card.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                const Text('Just Tap. Fast.'),
                const Text('Convenient.')
              ],
            ),
          ),
        );
      }
}
