import 'package:flutter/material.dart';
import 'package:nfc_app/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext contect) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custome Splash Demo',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const SplashScreen()
    );
  }
}