import 'package:flutter/material.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_team_editor.dart';
import 'package:provider/provider.dart';

class ScreenTeamSelect extends StatefulWidget {
  const ScreenTeamSelect({super.key});

  @override
  State<ScreenTeamSelect> createState() => _ScreenTeamSelectState();
}

class _ScreenTeamSelectState extends State<ScreenTeamSelect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderTeam>().loadTeamsFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    var teamManager = context.watch<ProviderTeam>().teams;
    if (teamManager.isEmpty) {
      return Card(
        child: ListTile(
          title: Text("No team yet"),
        ),
      );
    }
    return ListView.builder(
      itemCount: teamManager.length,
      itemBuilder: (context, index) {
        var listItem = teamManager[index];

        return GestureDetector(
          child: Card(
            child: ListTile(
              title: Text(listItem.name),
            ),
          ),
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ScreenTeamEditor(selectedTeam: listItem),
              ),
            );
          },
        );
      },
    );
  }
}
