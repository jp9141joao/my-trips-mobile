import 'dart:async';
import 'package:flutter/material.dart';
import 'Home.dart';

/// SplashScreen widget displays a full-screen logo for a fixed duration
/// before automatically navigating to the Home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a 5-second timer. Once the duration completes and this widget is still mounted,
    // replace the current route with the Home screen.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is a full-screen container with a solid background color
      body: Container(
        color: const Color(0xff0066cc), // Blue background color
        padding: const EdgeInsets.all(60), // Uniform padding around the content
        child: Center(
          // Center the logo image inside the container
          child: Image.asset("images/logo.png"),
        ),
      ),
    );
  }
}
