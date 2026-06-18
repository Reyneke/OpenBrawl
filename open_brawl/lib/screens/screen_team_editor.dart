import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_character_market.dart';
import 'package:open_brawl/screens/screen_character_owerview.dart';
import 'package:provider/provider.dart';

class ScreenTeamEditor extends StatefulWidget {
  final ObjectTeam selectedTeam;
  const ScreenTeamEditor({super.key, required this.selectedTeam});

  @override
  State<ScreenTeamEditor> createState() => _ScreenTeamEditorState();
}

class _ScreenTeamEditorState extends State<ScreenTeamEditor> {
  @override
  Widget build(BuildContext context) {
    ObjectTeam currentTeam = context.watch<ProviderTeam>().teams.elementAt(
      context.watch<ProviderTeam>().getTeamPosition(widget.selectedTeam),
    );

    final isNoPlayersAvailible = currentTeam.teamPlayers.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          child: Text("Team: ${currentTeam.teamName}"),
          onTap: () {
            showChangeNameDialog(context, currentTeam);
          },
        ),
      ),
      body: isNoPlayersAvailible
          ? Card(
              child: ListTile(
                title: Text("No players yet"),
              ),
            )
          : ListView.builder(
              itemCount: widget.selectedTeam.teamPlayers.length,
              itemBuilder: (context, index) {
                var listItem = widget.selectedTeam.teamPlayers[index];

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
                        builder: (context) =>
                            ScreenCharacterOwerview(currentCharacter: listItem),
                      ),
                    );
                  },
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  ScreenCharacterMarket(currentTeam: widget.selectedTeam),
            ),
          );
        },
        child: const Icon((Icons.insert_chart_outlined_sharp)),
      ),
    );
  }

  Future<void> showChangeNameDialog(
    BuildContext context,
    ObjectTeam currentTeam,
  ) {
    TextEditingController newTeamName = TextEditingController();
    newTeamName.text = currentTeam.teamName;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // verhindert Schließen durch Tippen außerhalb
      builder: (context) => AlertDialog(
        title: const Text('New team name?'),
        content: TextFormField(
          controller: newTeamName,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                currentTeam.teamName = newTeamName.text.trim();
              });
              Navigator.pop(context, true);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
