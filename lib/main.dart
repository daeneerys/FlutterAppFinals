import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/splash_screen.dart'; // <- Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TomasPetApp());
}

class TomasPetApp extends StatelessWidget {
  const TomasPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tomas the Virtual Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        useMaterial3: true,
      ),
      home: const SplashScreen(), //Splash
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const Home(),
      },
    );
  }
}