import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';

/// Der Schiedsrichter ist dafür zuständig, dass die Regeln eingehalten werden
/// und dass die Teams fair gegeneinander antreten. Er überwacht den Kampf und
/// protokolliert alle Aktionen der Spieler und Teams in der Datenbank.
class ObjectReferee {
  final ProviderServer _server;
  final ProviderTeam _teamProvider;

  ObjectReferee(this._server, this._teamProvider);

  /// Prüft, ob ein Team die Mindestanforderungen erfüllt und setzt es
  /// anschließend auf "ready_for_battle" = true. Wenn bereits ein anderes
  /// Team bereit ist, wird ein Match gestartet.
  Future<void> setTeamReadyForBattle(ObjectTeam team) async {
    if (!team.getIsTeamValid()) {
      debugPrint('Team ${team.teamName} is not valid for battle.');
      return;
    }

    // Team in der Datenbank auf ready_for_battle = true setzen
    await _teamProvider.setTeamReadyForBattle(team, true);
    debugPrint('Team ${team.teamName} is ready for battle.');

    // Prüfen, ob es ein anderes Team gibt, das ebenfalls ready_for_battle = true ist
    await _checkAndStartMatch(team);
  }

  /// Durchsucht die Datenbank nach einem anderen Team, das ebenfalls
  /// ready_for_battle = true ist. Wenn gefunden, wird ein Match gestartet.
  Future<void> _checkAndStartMatch(ObjectTeam currentTeam) async {
    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;
      final currentDbId = currentTeam.dbId;
      if (currentDbId == null) return;

      // Suche nach einem anderen Team (nicht das aktuelle) mit ready_for_battle = true
      final response = await _server.client
          .from('teams')
          .select()
          .eq('ready_for_battle', true)
          .neq('id', currentDbId)
          .limit(1);

      final List<dynamic> otherTeams = response as List<dynamic>;
      if (otherTeams.isEmpty) {
        debugPrint('No other team ready for battle yet. Waiting...');
        return;
      }

      // Ein anderes bereites Team gefunden -> Match starten
      final otherTeamData = otherTeams.first as Map<String, dynamic>;
      final otherTeamDbId = otherTeamData['id'] as String;

      // Beide Teams aus der lokalen Liste holen
      ObjectTeam? otherTeam;
      for (final t in _teamProvider.teams) {
        if (t.dbId == otherTeamDbId) {
          otherTeam = t;
          break;
        }
      }

      if (otherTeam == null) {
        debugPrint('Other team not found in local list.');
        return;
      }

      await _createMatch(currentTeam, otherTeam);
    } catch (e) {
      debugPrint('Failed to check for other ready teams: $e');
    }
  }

  /// Erstellt einen neuen Match-Eintrag in der Datenbanktabelle "matches"
  /// und setzt beide Teams zurück auf ready_for_battle = false.
  Future<void> _createMatch(ObjectTeam team1, ObjectTeam team2) async {
    try {
      final team1Json = _teamToJson(team1);
      final team2Json = _teamToJson(team2);

      await _server.client.from('matches').insert({
        'team1': [jsonEncode(team1Json)],
        'team2': [jsonEncode(team2Json)],
        'battle_log': [],
      });

      debugPrint(
        'Match started between ${team1.teamName} and ${team2.teamName}',
      );

      // Beide Teams zurücksetzen auf ready_for_battle = false
      await _teamProvider.setTeamReadyForBattle(team1, false);
      await _teamProvider.setTeamReadyForBattle(team2, false);
    } catch (e) {
      debugPrint('Failed to create match: $e');
    }
  }

  /// Fügt eine Aktion zur battle_log eines Matches hinzu.
  Future<void> logBattleAction({
    required int matchId,
    required String teamId,
    required String playerName,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Aktuelle battle_log abrufen
      final response = await _server.client
          .from('matches')
          .select('battle_log')
          .eq('id', matchId)
          .single();

      final matchData = response as Map<String, dynamic>;
      final List<dynamic> currentLog =
          (matchData['battle_log'] as List<dynamic>?) ?? [];

      // Neue Aktion hinzufügen
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'team_id': teamId,
        'player_name': playerName,
        'action': action,
        'details': details ?? {},
      };
      currentLog.add(jsonEncode(logEntry));

      // Aktualisierte battle_log zurückschreiben
      await _server.client
          .from('matches')
          .update({'battle_log': currentLog})
          .eq('id', matchId);
    } catch (e) {
      debugPrint('Failed to log battle action: $e');
    }
  }

  /// Beendet ein Match, speichert das Ergebnis und setzt die Teams zurück.
  Future<void> endMatch({
    required int matchId,
    required ObjectTeam winner,
    required ObjectTeam loser,
  }) async {
    try {
      // Ergebnis als JSON im Bucket "team_matches" speichern
      final resultJson = jsonEncode({
        'match_id': matchId,
        'winner': _teamToJson(winner),
        'loser': _teamToJson(loser),
        'ended_at': DateTime.now().toIso8601String(),
      });

      await _server.client.storage
          .from('team_matches')
          .uploadBinary('${winner.dbId}/$matchId.json', utf8.encode(resultJson));

      debugPrint(
        'Match $matchId ended. Winner: ${winner.teamName}, Loser: ${loser.teamName}',
      );
    } catch (e) {
      debugPrint('Failed to end match: $e');
    }
  }

  /// Hilfsmethode: Konvertiert ein ObjectTeam in ein JSON-freundliches Map.
  Map<String, dynamic> _teamToJson(ObjectTeam team) {
    return {
      'id': team.dbId,
      'team_id': team.teamId,
      'team_name': team.teamName,
      'team_logo': team.teamLogo,
      'team_nuyen': team.teamNuyen,
      'players': team.teamPlayers
          .map((player) => {
                'id': player.id,
                'name': player.name,
                'image': player.image,
                'price': player.price,
                'position': player.position.name,
                'status': player.status.name,
              })
          .toList(),
    };
  }
}