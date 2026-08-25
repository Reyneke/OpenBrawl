import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/utils/id_utils.dart';

/*
Teamdatabase structure

create table public.teams (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  teamname text null,
  banner_url text null,
  players jsonb[] null,
  stats jsonb null,
  ready_for_battle boolean null default false,
  user_id uuid null default auth.uid (),
  constraint teams_pkey primary key (id)
) TABLESPACE pg_default;
 */

class ProviderTeam extends ChangeNotifier {
  final List<ObjectTeam> _teams = [];
  List<ObjectTeam> get teams => _teams;
  final ProviderServer _server;

  ProviderTeam(this._server);

  /// Serializes a list of ObjectPlayer into a JSON-encoded list for database storage.
  List<String> _serializePlayers(List<ObjectPlayer> players) {
    return players.map((player) => jsonEncode(player.toJson())).toList();
  }

  /// DB-Zeilen-Payload für Insert/Update (Spaltennamen siehe Schema oben).
  Map<String, dynamic> _teamRowPayload(ObjectTeam team) {
    return {
      'teamname': team.name,
      'banner_url': team.logo,
      'players': _serializePlayers(team.players),
      'stats': {
        'nuyen': team.nuyen,
        'player_count': team.players.length,
        'won': team.record.won,
        'lost': team.record.lost,
        'drawn': team.record.drawn,
        'captain_id': team.captainId,
      },
    };
  }

  int getTeamPosition(ObjectTeam teamItem) {
    return _teams.indexWhere((team) => team.id == teamItem.id);
  }

  /// Updates an existing team in the database.
  Future<void> updateTeamInDatabase(ObjectTeam team) async {
    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;
      final dbId = team.dbId;
      if (dbId == null) return;

      await _server.client
          .from('teams')
          .update(_teamRowPayload(team))
          .eq('id', dbId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Failed to update team in database: $e');
    }
  }

  /// Adds a new team to the local list and the database.
  Future<void> addTeam(ObjectTeam newTeam) async {
    _teams.add(newTeam);
    notifyListeners();

    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;

      final response = await _server.client.from('teams').insert({
        ..._teamRowPayload(newTeam),
        'ready_for_battle': newTeam.isTeamValid,
        'user_id': userId,
      }).select();

      // Capture the database-generated UUID
      final List<dynamic> insertedData = response as List<dynamic>;
      if (insertedData.isNotEmpty) {
        newTeam.dbId = insertedData.first['id'] as String?;
      }
    } catch (e) {
      debugPrint('Failed to add team to database: $e');
    }
  }

  /// Removes a team from the local list and the database.
  Future<void> removeTeam(ObjectTeam oldTeam) async {
    final teamPosition = getTeamPosition(oldTeam);

    if (teamPosition >= 0) {
      _teams.removeAt(teamPosition);
      notifyListeners();

      try {
        final userId = _server.currentUser?.id;
        if (userId == null) return;
        final dbId = oldTeam.dbId;
        if (dbId == null) return;

        await _server.client
            .from('teams')
            .delete()
            .eq('id', dbId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('Failed to remove team from database: $e');
      }
    }
  }

  /// Adds a character to a team and updates the database.
  Future<void> addCharacterToTeam(
    ObjectTeam teamItem,
    ObjectPlayer newPlayer,
  ) async {
    final added = _teams[getTeamPosition(teamItem)].addPlayer(newPlayer);
    if (!added) {
      debugPrint(
        'Could not add player to team "${teamItem.name}" '
        '(roster full or duplicate id).',
      );
      return;
    }
    notifyListeners();

    await updateTeamInDatabase(teamItem);
    await _syncReadyForBattle(teamItem);
  }

  ObjectTeam? getCharacterInTeam(ObjectPlayer player) {
    for (var team in _teams) {
      if (team.hasPlayer(player)) {
        return team;
      }
    }

    return null;
  }

  /// Modifies a character in a team and updates the database.
  Future<void> modifyCharacterInTeam(
    ObjectTeam teamItem,
    ObjectPlayer newPlayer,
  ) async {
    _teams[getTeamPosition(teamItem)].updatePlayer(newPlayer);

    notifyListeners();

    await updateTeamInDatabase(teamItem);
    await _syncReadyForBattle(teamItem);
  }

  int getListPosition(ObjectTeam teamItem, ObjectPlayer characterItem) {
    return _teams[getTeamPosition(teamItem)].indexOfPlayer(characterItem);
  }

  /// Removes a character from a team and updates the database.
  Future<void> removeCharacterFromTeam(
    ObjectTeam teamItem,
    ObjectPlayer oldPlayer,
  ) async {
    final removed = _teams[getTeamPosition(teamItem)].removePlayer(oldPlayer);
    if (removed) {
      notifyListeners();

      await updateTeamInDatabase(teamItem);
      await _syncReadyForBattle(teamItem);
    }
  }

  /// Adjusts team money and updates the database.
  Future<void> adjustMoney(ObjectTeam teamItem, int deductible) async {
    _teams[getTeamPosition(teamItem)].nuyen += deductible;
    notifyListeners();

    await updateTeamInDatabase(teamItem);
  }

  /// Berechnet nach einer Kaderänderung ready_for_battle neu und persistiert es.
  Future<void> _syncReadyForBattle(ObjectTeam team) async {
    await setTeamReadyForBattle(team, team.isTeamValid);
  }

  /// Setzt oder entfernt den Teamkapitän und aktualisiert die Datenbank.
  Future<void> setTeamCaptain(
    ObjectTeam teamItem,
    ObjectPlayer? captain,
  ) async {
    if (!_teams[getTeamPosition(teamItem)].setCaptain(captain)) {
      debugPrint('Could not appoint captain: player not in roster.');
      return;
    }
    notifyListeners();

    await updateTeamInDatabase(teamItem);
  }

  /// Trägt das Match-Ergebnis in die Statistiken beider Teams ein und
  /// persistiert sie (Grundlage der Gesamtqualität nach dem 3-1-0-Schema).
  Future<void> recordMatchResult({
    required ObjectTeam winner,
    required ObjectTeam loser,
  }) async {
    winner.record.recordWin();
    loser.record.recordLoss();
    notifyListeners();

    await updateTeamInDatabase(winner);
    await updateTeamInDatabase(loser);
  }

  /// Updates the ready_for_battle status in the database for a given team.
  Future<void> setTeamReadyForBattle(ObjectTeam team, bool isReady) async {
    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;
      final dbId = team.dbId;
      if (dbId == null) return;

      await _server.client
          .from('teams')
          .update({'ready_for_battle': isReady})
          .eq('id', dbId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Failed to set team ready for battle: $e');
    }
  }

  /// Loads all teams for the current user from Supabase.
  Future<void> loadTeamsFromDatabase() async {
    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;

      final response = await _server.client
          .from('teams')
          .select()
          .eq('user_id', userId);

      final List<dynamic> data = response as List<dynamic>;
      _teams.clear();

      for (final row in data) {
        final rowData = row as Map<String, dynamic>;
        final createdRaw = rowData['created_at'] as String?;
        final stats = rowData['stats'] as Map<String, dynamic>?;
        final team = ObjectTeam(
          id: IdUtils.stableIdFromString(rowData['id'] as String),
          name: rowData['teamname'] as String? ?? '',
          logo: rowData['banner_url'] as String? ?? '',
          nuyen: (stats?['nuyen'] as num?)?.toInt() ?? ObjectTeam.defaultNuyen,
          dbId: rowData['id'] as String?,
          timeCreated: DateTime.tryParse(createdRaw ?? ''),
          record: TeamMatchRecord.fromJson(stats),
          captainId: (stats?['captain_id'] as num?)?.toInt(),
        );

        // Parse players JSON array
        final playersJson = rowData['players'] as List<dynamic>?;
        if (playersJson != null) {
          for (final playerJson in playersJson) {
            team.addPlayer(
              ObjectPlayer.fromJson(
                jsonDecode(playerJson as String) as Map<String, dynamic>,
              ),
            );
          }
        }

        _teams.add(team);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load teams from database: $e');
    }
  }
}
