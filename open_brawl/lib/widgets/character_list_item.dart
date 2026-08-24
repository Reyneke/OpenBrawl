import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_character_overview.dart';
import 'package:provider/provider.dart';

class CharacterListItem extends StatelessWidget {
  const CharacterListItem({
    super.key,
    required this.currentTeam,
    required this.listItem,
  });
  final ObjectTeam currentTeam;
  final ObjectPlayer listItem;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      child: Card(
        child: ListTile(
          title: Text(listItem.name),
          trailing: DropdownMenu(
            //initialSelection: Text(menuEntries.first.label),
            dropdownMenuEntries: TeamPositions.values.map((charPosition) {
              return DropdownMenuEntry<TeamPositions>(
                value: charPosition, // Wert ist vom Typ CharacterClass
                label: charPosition.displayName,
              );
            }).toList(),
            onSelected: (TeamPositions? value) async {
              listItem.position = (value ?? TeamPositions.inactive);
              await context.read<ProviderTeam>().modifyCharacterInTeam(
                currentTeam,
                listItem,
              );
            },
          ),
        ),
      ),
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ScreenCharacterOverview(
              currentCharacter: listItem,
              currentTeam: currentTeam,
            ),
          ),
        );
      },
    );
  }
}
