import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_referee.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_battle_map.dart';
import 'package:open_brawl/screens/screen_character_market.dart';
import 'package:open_brawl/widgets/character_list_item.dart';
import 'package:open_brawl/widgets/widget_image_select.dart';
import 'package:provider/provider.dart';

// Feature implemented: Image picker uploads teamLogo to Supabase Storage bucket "teambanners"
// under a folder named after the team (sanitized). See WidgetImageSelect._uploadTeamLogoToSupabase().
// Images are displayed via createSignedUrl() to work with Supabase policies requiring authentication.

class ScreenTeamEditor extends StatefulWidget {
  final ObjectTeam selectedTeam;
  const ScreenTeamEditor({super.key, required this.selectedTeam});

  @override
  State<ScreenTeamEditor> createState() => _ScreenTeamEditorState();
}

class _ScreenTeamEditorState extends State<ScreenTeamEditor> {
  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<ProviderTeam>();
    final teamIndex = teamProvider.getTeamPosition(widget.selectedTeam);
    ObjectTeam currentTeam = teamProvider.teams.elementAt(teamIndex);

    final isNoPlayersAvailable = currentTeam.players.isEmpty;
    final readyForBattle = currentTeam.isTeamValid && currentTeam.hasCaptain;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
            child: Text("Team: ${currentTeam.name}"),
            onTap: () {
              showChangeNameDialog(context, currentTeam);
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ScreenBattleMap(activeTeam: currentTeam),
                ),
              );
            },
            icon: const Icon(Icons.desktop_mac_outlined),
          )
          ],
        ),
      ),
      body: isNoPlayersAvailable
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
                        //TODO clicking on the widget to upload an image crashes the App. Why?
                        titleText: currentTeam.name,
                        rootObject: currentTeam,
                      ),
                      Text(currentTeam.name),
                    ],
                  ),
                ),
                // Team-Statistik (Gesamtqualität nach 3-1-0-Schema)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      'Siege: ${currentTeam.record.won} · '
                      'Niederlagen: ${currentTeam.record.lost} · '
                      'Draws: ${currentTeam.record.drawn} · '
                      'Qualität: ${currentTeam.record.quality}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: ListView.builder(
                    itemCount: widget.selectedTeam.players.length,
                    itemBuilder: (context, index) {
                      var listItem = widget.selectedTeam.players[index];

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
                    onPressed: () async {
                      if (!readyForBattle) return;
                      final server = context.read<ProviderServer>();
                      final teamProvider = context.read<ProviderTeam>();
                      final referee = ObjectReferee(server, teamProvider);
                      await referee.setTeamReadyForBattle(currentTeam);
                      if (context.mounted) {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                ScreenBattleMap(activeTeam: currentTeam),
                          ),
                        );
                      }
                    },
                    child: readyForBattle
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
    newTeamName.text = currentTeam.name;
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
            onPressed: () async {
              setState(() {
                currentTeam.name = newTeamName.text.trim();
              });
              Navigator.pop(context, true);
              // Persist team name change to the database
              await context.read<ProviderTeam>().updateTeamInDatabase(
                currentTeam,
              );
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
