import 'package:flutter/material.dart';
import '../widgets/web/game_board.dart';
import '../widgets/mobile/game_board_mobile.dart';

class MemoryMatchPage extends StatelessWidget {
  const MemoryMatchPage({
    required this.gameLevel,
    super.key,
  });

  final int gameLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Shared background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/games/background.png', // same as StartUpPage
              fit: BoxFit.cover,
            ),
          ),

          // Foreground game content
          SafeArea(
            child: LayoutBuilder(
              builder: ((context, constraints) {
                if (constraints.maxWidth > 720) {
                  return GameBoard(gameLevel: gameLevel);
                } else {
                  return GameBoardMobile(gameLevel: gameLevel);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}
