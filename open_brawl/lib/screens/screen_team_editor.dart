import 'package:flutter/material.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:provider/provider.dart';

class ScreenTeamEditor extends StatefulWidget {
  const ScreenTeamEditor({super.key});

  @override
  State<ScreenTeamEditor> createState() => _ScreenTeamEditorState();
}

class _ScreenTeamEditorState extends State<ScreenTeamEditor> {
  @override
  Widget build(BuildContext context) {
    var playerManager = context.watch<ProviderTeam>();
    return ListView.builder(
      itemCount: context.read<ProviderTeam>().players.length,
      itemBuilder: (context, index) {
        var listItem = playerManager.players[index];

        return Card(
          child: ListTile(
            title: Text(listItem.name),
          ),
        );
      },
    );
  }
}
