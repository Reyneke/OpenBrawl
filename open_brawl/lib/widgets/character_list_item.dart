import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/screens/screen_character_owerview.dart';
import 'package:open_brawl/widgets/widget_utility.dart';
import 'package:provider/provider.dart';

class CharacterListItem extends StatelessWidget {
  CharacterListItem({
    super.key,
    required this.currentTeam,
    required this.listItem,
  });
  final ObjectTeam currentTeam;
  ObjectPlayer listItem;

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuEntry<TeamPositions>> menuEntries = TeamPositions.values
        .map((TeamPositions option) {
          return DropdownMenuEntry<TeamPositions>(
            value: option,
            label: WidgetUtility().capitalize(
              option.name,
            ), // "BLUE", "GREEN", "RED"
          );
        })
        .toList();

    return GestureDetector(
      child: Card(
        child: ListTile(
          title: Text(listItem.name),
          trailing: DropdownMenu(
            //initialSelection: Text(menuEntries.first.label),
            dropdownMenuEntries: TeamPositions.values.map((charPosition) {
              return DropdownMenuEntry<TeamPositions>(
                value: charPosition, // Wert ist vom Typ CharacterClass
                label: WidgetUtility().capitalize(charPosition.name),
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
            builder: (context) =>
                ScreenCharacterOwerview(currentCharacter: listItem),
          ),
        );
      },
    );
  }
}
