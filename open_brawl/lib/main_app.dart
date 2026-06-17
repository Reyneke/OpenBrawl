import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
//import 'package:open_brawl/objects/ub_player.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_team_select.dart';
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
        appBar: AppBar(
          title: Text("Team Select"),
        ),
        body: const Center(
          child: ScreenTeamSelect(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<ProviderTeam>().addTeam(
              ObjectTeam.createTeam("New Team", ""),
            );
          },
          child: const Icon((Icons.add)),
        ),
      ),
    );
  }
}
