import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/widgets/widget_map_loader.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScreenBattleMap extends StatefulWidget {
  final ObjectTeam activeTeam;

  const ScreenBattleMap({super.key, required this.activeTeam});

  @override
  State<ScreenBattleMap> createState() => _ScreenBattleMapState();
}

class _ScreenBattleMapState extends State<ScreenBattleMap> {
  List<Map<String, dynamic>> _battleLog = [];
  ObjectTeam? _opponentTeam;
  bool _isInMatch = false;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final server = context.read<ProviderServer>();
      final teamProvider = context.read<ProviderTeam>();

      final currentDbId = widget.activeTeam.dbId;
      if (currentDbId == null) return;

      // Suche nach dem letzten Match für dieses Team
      // Lade die letzten 10 Matches und filtere client-seitig,
      // um Probleme mit PostgREST's JSON-Array-Operatoren zu vermeiden.
      final response = await server.client
          .from('matches')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      final allMatches = (response as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final matches = allMatches.where((m) {
        final t1 = ((m['team1'] as List<dynamic>?) ?? [])
            .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
            .toList();
        final t2 = ((m['team2'] as List<dynamic>?) ?? [])
            .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
            .toList();
        return t1.any((t) => t['id'] == currentDbId) ||
            t2.any((t) => t['id'] == currentDbId);
      }).toList();

      if (matches.isEmpty) {
        // Kein aktives Match -> Team-Aufstellung anzeigen
        return;
      }

      final match = matches.first as Map<String, dynamic>;
      final matchId = match['id'] as int;

      // Prüfen, ob das Team in team1 oder team2 ist
      final team1List = match['team1'] as List<dynamic>? ?? [];
      final team2List = match['team2'] as List<dynamic>? ?? [];

      // Battle-Log laden
      final logList = match['battle_log'] as List<dynamic>? ?? [];
      setState(() {
        _battleLog = logList
            .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
            .toList();
        _isInMatch = true;
      });

      // Gegnerisches Team ermitteln
      final team1Data = team1List.isNotEmpty
          ? jsonDecode(team1List.first as String) as Map<String, dynamic>
          : null;
      final team2Data = team2List.isNotEmpty
          ? jsonDecode(team2List.first as String) as Map<String, dynamic>
          : null;

      if (team1Data?['id'] == currentDbId && team2Data != null) {
        _opponentTeam = _jsonToTeam(team2Data);
      } else if (team2Data?['id'] == currentDbId && team1Data != null) {
        _opponentTeam = _jsonToTeam(team1Data);
      }

      // Realtime-Subscription für Battle-Log-Updates
      server.client
          .channel('match-${match['id']}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            table: 'matches',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: match['id'],
            ),
            callback: (payload) {
              final newData = payload.newRecord;
              final updatedLog =
                  newData['battle_log'] as List<dynamic>? ?? [];
              if (mounted) {
                setState(() {
                  _battleLog = updatedLog
                      .map(
                          (e) => jsonDecode(e as String) as Map<String, dynamic>)
                      .toList();
                });
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Failed to load match data: $e');
    }
  }

  ObjectTeam _jsonToTeam(Map<String, dynamic> json) {
    final team = ObjectTeam(
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String? ?? '',
      teamLogo: json['team_logo'] as String? ?? '',
      teamNuyen: json['team_nuyen'] as int? ?? 1000,
      dbId: json['id'] as String?,
    );

    final playersList = json['players'] as List<dynamic>? ?? [];
    for (final playerJson in playersList) {
      final playerMap = playerJson as Map<String, dynamic>;
      // ObjectPlayer reconstruction from JSON
      final player = ObjectPlayer(
        id: playerMap['id'] as int,
        name: playerMap['name'] as String? ?? '',
        image: playerMap['image'] as String? ?? '',
      );
      player.price = playerMap['price'] as int? ?? 3000;
      player.position = TeamPositions.values.firstWhere(
        (p) => p.name == playerMap['position'],
        orElse: () => TeamPositions.inactive,
      );
      player.status = CharacterStatus.values.firstWhere(
        (s) => s.name == playerMap['status'],
        orElse: () => CharacterStatus.fine,
      );
      team.teamPlayers.add(player);
    }

    return team;
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<ProviderTeam>();
    final teamIndex = teamProvider.teams.indexWhere(
      (t) => t.teamId == widget.activeTeam.teamId,
    );
    final team =
        teamIndex >= 0 ? teamProvider.teams[teamIndex] : widget.activeTeam;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isInMatch
              ? 'Match: ${team.teamName} vs ${_opponentTeam?.teamName ?? '?'}'
              : team.teamName,
        ),
      ),
      body: Row(
        children: [
          // Left sidebar: Current team member list
          _buildTeamSidebar(team, 'Dein Team'),
          const VerticalDivider(width: 1),
          // Main content area: Map + Battle Log
          Expanded(
            child: Column(
              children: [
                // Map area (scrollable and zoomable)
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: WidgetMapLoader(activeTeam: team),
                  ),
                ),
                const Divider(height: 1),
                // Battle Log (unten)
                _buildBattleLog(),
              ],
            ),
          ),
          // Right sidebar: Opponent team (nur wenn Match aktiv)
          if (_isInMatch && _opponentTeam != null) ...[
            const VerticalDivider(width: 1),
            _buildTeamSidebar(_opponentTeam!, 'Gegner'),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSidebar(ObjectTeam team, String title) {
    return SizedBox(
      width: 200,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: team.teamPlayers.length,
                itemBuilder: (context, index) {
                  final player = team.teamPlayers[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        player.name.isNotEmpty
                            ? player.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      player.position.name,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleLog() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(8),
      child: _battleLog.isEmpty
          ? Center(
              child: Text(
                _isInMatch
                    ? 'Warte auf Kampfaktionen...'
                    : 'Team-Aufstellung wird angezeigt',
                style: const TextStyle(fontSize: 12),
              ),
            )
          : ListView.builder(
              reverse: true, // Neueste Aktionen oben
              itemCount: _battleLog.length,
              itemBuilder: (context, index) {
                final entry = _battleLog[_battleLog.length - 1 - index];
                final timestamp = entry['timestamp'] as String? ?? '';
                final action = entry['action'] as String? ?? '';
                final playerName = entry['player_name'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: Text(
                    '[${_formatTime(timestamp)}] $playerName: $action',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
