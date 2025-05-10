import 'package:flutter/material.dart';

import '../widgets/game_options.dart';
import 'package:tomas_tigerpet/utils/constants.dart';

class StartUpPage extends StatelessWidget {
  const StartUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  gameTitle,
                  style: TextStyle(fontSize: 24, color: Colors.black),
                ),
                GameOptions(),
              ]),
        ),
      ),
    );
  }
}
