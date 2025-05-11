import 'package:flutter/material.dart';
import '../widgets/game_options.dart';
import 'package:tomas_tigerpet/screens/home.dart';

class StartUpPage extends StatelessWidget {
  const StartUpPage({super.key});

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