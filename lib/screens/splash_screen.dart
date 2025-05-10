import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay
    User? user = FirebaseAuth.instance.currentUser;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? const Home() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF388E3C), Color(0xFF81C784)], // Jungle green shades
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title text with overflow handling
              FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  '🐾 Tomas the Virtual Pet',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontFamily: 'Poppins', // Nature-inspired font
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Let’s take care of your furry friend!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                  fontFamily: 'Poppins', // Nature-inspired font
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}