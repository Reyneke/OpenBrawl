import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/screens/screen_character_market.dart';

class ScreenTeamEditor extends StatefulWidget {
  final ObjectTeam currentTeam;
  const ScreenTeamEditor({super.key, required this.currentTeam});

  @override
  State<ScreenTeamEditor> createState() => _ScreenTeamEditorState();
}

class _ScreenTeamEditorState extends State<ScreenTeamEditor> {
  @override
  Widget build(BuildContext context) {
    final isNoPlayersAvailible = widget.currentTeam.teamPlayers.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text("Team Editor"),
      ),
      body: isNoPlayersAvailible
          ? Card(
              child: ListTile(
                title: Text("No players yet"),
              ),
            )
          : ListView.builder(
              itemCount: widget.currentTeam.teamPlayers.length,
              itemBuilder: (context, index) {
                var listItem = widget.currentTeam.teamPlayers[index];

                return Card(
                  child: ListTile(
                    title: Text(listItem.name),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  ScreenCharacterMarket(currentTeam: widget.currentTeam),
            ),
          );
        },
        child: const Icon((Icons.insert_chart_outlined_sharp)),
      ),
    );
  }
}
