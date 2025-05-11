import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/game_options.dart';
import 'package:tomas_tigerpet/screens/home.dart';

class StartUpPage extends StatefulWidget {
  const StartUpPage({super.key});

  @override
  State<StartUpPage> createState() => _StartUpPageState();
}

class _StartUpPageState extends State<StartUpPage> {
  @override
  void initState() {
    super.initState();
    _reduceEnergy();
  }

  void _reduceEnergy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('pets').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final currentEnergy = docSnapshot['energy'] ?? 0;
      final newEnergy = (currentEnergy - 10).clamp(0, 100); // prevent negative

      await docRef.update({'energy': newEnergy});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/games/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Home button at top-left
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 100),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
              tooltip: 'Back to Home',
            ),
          ),

          // Foreground content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/games/memorynobg.png',
                    width: 600,
                    height: 430,
                    fit: BoxFit.contain,
                  ),
                  const GameOptions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
