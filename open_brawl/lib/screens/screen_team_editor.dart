import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_character_market.dart';
import 'package:open_brawl/widgets/character_list_item.dart';
import 'package:open_brawl/widgets/widget_image_select.dart';
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
          : Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      WidgetImageSelect(
                        titleText: currentTeam.teamName,
                        rootObject: currentTeam as Widget,
                      ),
                      Text(currentTeam.teamName),
                    ],
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: ListView.builder(
                    itemCount: widget.selectedTeam.teamPlayers.length,
                    itemBuilder: (context, index) {
                      var listItem = widget.selectedTeam.teamPlayers[index];

                      return CharacterListItem(
                        currentTeam: currentTeam,
                        listItem: listItem,
                      );
                    },
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!currentTeam.getIsTeamValid()) {
                        null;
                      }
                    },
                    child: currentTeam.getIsTeamValid()
                        ? Text("Enter Battle")
                        : Text("Team not ready yet"),
                  ),
                ),
              ],
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
