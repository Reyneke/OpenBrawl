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
    final isCaptain = currentTeam.captainId == listItem.id;

    return GestureDetector(
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              // Kapitän-Checkbox: genau ein Kapitän pro Team
              Tooltip(
                message: 'Zum Teamkapitän ernennen',
                child: Checkbox(
                  value: isCaptain,
                  onChanged: (checked) {
                    final provider = context.read<ProviderTeam>();
                    provider.setTeamCaptain(
                      currentTeam,
                      checked == true ? listItem : null,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(listItem.name),
              ),
              // Primärrolle – zählt allein für „Ready for Battle“
              Expanded(
                flex: 3,
                child: _roleDropdown(
                  context,
                  label: 'Primär',
                  value: listItem.position,
                  onChanged: (value) async {
                    listItem.position = value ?? TeamPositions.inactive;
                    final provider = context.read<ProviderTeam>();
                    await provider.modifyCharacterInTeam(
                      currentTeam,
                      listItem,
                    );
                  },
                ),
              ),
              // Sekundärrolle – im Match wechselbar, sofern die Rolle frei ist
              Expanded(
                flex: 3,
                child: _roleDropdown(
                  context,
                  label: 'Sekundär',
                  value: listItem.secondaryPosition,
                  onChanged: (value) async {
                    listItem.secondaryPosition =
                        value ?? TeamPositions.inactive;
                    final provider = context.read<ProviderTeam>();
                    await provider.modifyCharacterInTeam(
                      currentTeam,
                      listItem,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown(
    BuildContext context, {
    required String label,
    required TeamPositions value,
    required ValueChanged<TeamPositions?> onChanged,
  }) {
    return DropdownMenu<TeamPositions>(
      initialSelection: value,
      expandedInsets: const EdgeInsets.symmetric(horizontal: 4),
      dropdownMenuEntries: TeamPositions.values.map((role) {
        return DropdownMenuEntry<TeamPositions>(
          value: role,
          label: '${role.displayName} ($label)',
        );
      }).toList(),
      onSelected: onChanged,
    );
  }
}
