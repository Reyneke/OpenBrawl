import 'package:flutter/material.dart';
import 'package:open_brawl/objects/ub_player.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_team_editor.dart';
import 'package:open_brawl/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: Scaffold(
        body: const Center(
          child: ScreenTeamEditor(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<ProviderTeam>().addPlayer(
              UbPlayer(
                key: 1,
                name: 'Ghost',
                body: 1,
                agility: 1,
                reaction: 1,
                strength: 1,
                willpower: 1,
                logic: 1,
                intuition: 1,
                charisma: 1,
                edge: 1,
              ),
            );
          },
          child: const Icon((Icons.add)),
        ),
      ),
    );
  }
}
