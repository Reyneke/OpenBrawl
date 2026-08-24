import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/widgets/widget_image_select.dart';
import 'package:provider/provider.dart';

/// Zeigt alle Details eines Spielers: Bild, Name, Rasse, Persönlichkeit,
/// Status, Marktwert/Preis/Ruhm, Attribute (editierbar) und den
/// Match-Tracker (gewonnen/verloren/unentschieden).
class ScreenCharacterOverview extends StatefulWidget {
  final ObjectPlayer currentCharacter;

  /// Team, in dem der Spieler steht. Nur mit Team sind Änderungen
  /// (Attribute, Rasse, Persönlichkeit) persistierbar; ohne Team ist die
  /// Ansicht read-only (z. B. Markt-Spieler).
  final ObjectTeam? currentTeam;

  const ScreenCharacterOverview({
    super.key,
    required this.currentCharacter,
    this.currentTeam,
  });

  @override
  State<ScreenCharacterOverview> createState() =>
      _ScreenCharacterOverviewState();
}

class _ScreenCharacterOverviewState extends State<ScreenCharacterOverview> {
  ObjectPlayer get player => widget.currentCharacter;

  bool get _canEdit => widget.currentTeam != null;

  Future<void> _persist() async {
    final team = widget.currentTeam;
    if (team == null) return;
    await context.read<ProviderTeam>().modifyCharacterInTeam(team, player);
  }

  void _changeBaseAttribute(PlayerAttribute attr, int delta) {
    final current = player.baseAttributes[attr]!;
    final next = (current + delta)
        .clamp(ObjectPlayer.minAttribute, ObjectPlayer.maxBaseAttribute)
        .toInt();
    if (next == current) return;

    setState(() {
      player.setBaseAttribute(attr, next);
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Overview: ${player.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          _buildValuesCard(theme),
          const SizedBox(height: 12),
          _buildAttributeCard(theme),
          const SizedBox(height: 12),
          _buildMatchRecordCard(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Header
  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetImageSelect(
          titleText: player.name,
          rootObject: player,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(player.race.displayName),
                    avatar: const Icon(Icons.people_outline, size: 18),
                  ),
                  Chip(
                    label: Text(player.personality.displayName),
                    avatar: const Icon(Icons.psychology_outlined, size: 18),
                  ),
                  Chip(
                    label: Text(player.status.displayName),
                    avatar: Icon(
                      player.status.isAlive
                          ? Icons.favorite_outline
                          : Icons.favorite_border,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- Values
  Widget _buildValuesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Werte', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _valuesRow(theme, 'Marktwert', '${player.marketValue}'),
            _valuesRow(theme, 'Preis', '${player.price} Nuy'),
            _valuesRow(theme, 'Ruhm', '${player.fame}'),
            const Divider(),
            _dropdownRow(
              theme,
              'Rasse',
              DropdownMenu<PlayerRace>(
                initialSelection: player.race,
                dropdownMenuEntries: PlayerRace.values
                    .map((r) => DropdownMenuEntry<PlayerRace>(
                          value: r,
                          label: r.displayName,
                        ))
                    .toList(),
                onSelected: (PlayerRace? value) {
                  if (value == null) return;
                  setState(() {
                    player.race = value;
                  });
                  _persist();
                },
              ),
            ),
            _dropdownRow(
              theme,
              'Persönlichkeit',
              DropdownMenu<EnneagramPersonality>(
                initialSelection: player.personality,
                dropdownMenuEntries: EnneagramPersonality.values
                    .map((p) => DropdownMenuEntry<EnneagramPersonality>(
                          value: p,
                          label: p.displayName,
                        ))
                    .toList(),
                onSelected: (EnneagramPersonality? value) {
                  if (value == null) return;
                  setState(() {
                    player.personality = value;
                  });
                  _persist();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [ATTR-CARD]
  Widget _buildAttributeCard(ThemeData theme) {
    final total = PlayerAttribute.values.fold<int>(
      0,
      (sum, attr) => sum + player.baseAttributes[attr]!,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attribute', style: theme.textTheme.titleMedium),
                Text(
                  'Summe Basis: $total',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final attr in PlayerAttribute.values)
              _attributeRow(theme, attr),
          ],
        ),
      ),
    );
  }

  // [ATTR-ROW]
  Widget _attributeRow(ThemeData theme, PlayerAttribute attr) {
    final base = player.baseAttributes[attr]!;
    final mod = player.race.modifierFor(attr);
    final effective = player.value(attr);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(attr.displayName, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(width: 8),
          Text(
            'Basis $base  ·  ${mod >= 0 ? '+' : ''}$mod  →  $effective',
            style: theme.textTheme.bodyMedium,
          ),
          if (_canEdit) ...[
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _changeBaseAttribute(attr, -1),
              tooltip: 'Basis −1',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _changeBaseAttribute(attr, 1),
              tooltip: 'Basis +1',
            ),
          ],
        ],
      ),
    );
  }

  // [RECORD-CARD]
  Widget _buildMatchRecordCard(ThemeData theme) {
    final r = player.matchRecord;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match-Tracker', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _recordCell(
                  theme,
                  Icons.emoji_events,
                  Colors.green.shade400,
                  '${r.won}',
                  'Siege',
                ),
                _recordCell(
                  theme,
                  Icons.close,
                  Colors.red.shade400,
                  '${r.lost}',
                  'Niederlagen',
                ),
                _recordCell(
                  theme,
                  Icons.horizontal_rule,
                  Colors.blueGrey.shade400,
                  '${r.drawn}',
                  'Draws',
                ),
                _recordCell(
                  theme,
                  Icons.sports,
                  theme.colorScheme.primary,
                  '${r.gamesPlayed}',
                  'Spiele',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score (Siege − Niederlagen): ${r.score}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // [HELPERS]
  Widget _valuesRow(ThemeData theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _dropdownRow(
    ThemeData theme,
    String title,
    Widget dropdown,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: theme.textTheme.bodyLarge),
          ),
          Expanded(
            child: _canEdit
                ? dropdown
                : Text(
                    title == 'Rasse'
                        ? player.race.displayName
                        : player.personality.displayName,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _recordCell(
    ThemeData theme,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}