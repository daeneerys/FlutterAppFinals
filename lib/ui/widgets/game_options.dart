import 'package:flutter/material.dart';
import 'package:tomas_tigerpet/ui/pages/memory_match_page.dart';
import 'package:tomas_tigerpet/ui/widgets/game_button.dart';
import 'package:tomas_tigerpet/utils/constants.dart';

class GameOptions extends StatelessWidget {
  const GameOptions({
    super.key,
  });

  static Route<dynamic> _routeBuilder(BuildContext context, int gameLevel) {
    return MaterialPageRoute(
      builder: (_) {
        return MemoryMatchPage(gameLevel: gameLevel);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: gameLevels.map((level) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: GameButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                _routeBuilder(context, level['level']),
                (Route<dynamic> route) => false),
            title: level['title'],
            color: level['color']![700]!,
            width: 250,
          ),
        );
      }).toList(),
    );
  }
}
