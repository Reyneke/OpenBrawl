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

  int getTeamPosition(ObjectTeam teamItem) {
    return _teams.indexWhere((team) => team.teamId == teamItem.teamId);
  }

  /// Updates an existing team in the database.
  Future<void> updateTeamInDatabase(ObjectTeam team) async {
    try {
      final userId = _server.currentUser?.id;
      if (userId == null) return;
      final dbId = team.dbId;
      if (dbId == null) return;

      final playersJson = _serializePlayers(team.teamPlayers);

      await _server.client
          .from('teams')
          .update({
            'teamname': team.teamName,
            'banner_url': team.teamLogo,
            'players': playersJson,
            'stats': {
              'nuyen': team.teamNuyen,
              'player_count': team.teamPlayers.length,
            },
          })
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

      final playersJson = _serializePlayers(newTeam.teamPlayers);

      final response = await _server.client.from('teams').insert({
        'teamname': newTeam.teamName,
        'banner_url': newTeam.teamLogo,
        'players': playersJson,
        'stats': {
          'nuyen': newTeam.teamNuyen,
          'player_count': newTeam.teamPlayers.length,
        },
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
    _teams[getTeamPosition(teamItem)].teamPlayers.add(newPlayer);
    notifyListeners();

    await updateTeamInDatabase(teamItem);
  }

  ObjectTeam? getCharacterInTeam(ObjectPlayer player) {
    for (var team in _teams) {
      if (team.teamPlayers.indexWhere(
            ((element) => element.id == player.id),
          ) >=
          0) {
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
    int position = getListPosition(teamItem, newPlayer);
    removeCharacterFromTeam(teamItem, newPlayer);
    _teams[getTeamPosition(teamItem)].teamPlayers.insert(
      position,
      newPlayer,
    );

    notifyListeners();

    await updateTeamInDatabase(teamItem);
  }

  int getListPosition(ObjectTeam teamItem, ObjectPlayer characterItem) {
    return _teams[getTeamPosition(teamItem)].teamPlayers.indexWhere(
      (character) => character.id == characterItem.id,
    );
  }

  /// Removes a character from a team and updates the database.
  Future<void> removeCharacterFromTeam(
    ObjectTeam teamItem,
    ObjectPlayer oldPlayer,
  ) async {
    int position = getListPosition(teamItem, oldPlayer);
    if (position >= 0) {
      _teams[getTeamPosition(teamItem)].teamPlayers.removeAt(position);
      notifyListeners();

      await updateTeamInDatabase(teamItem);
    }
  }

  /// Adjusts team money and updates the database.
  Future<void> adjustMoney(ObjectTeam teamItem, int deductible) async {
    _teams[getTeamPosition(teamItem)].teamNuyen += deductible;
    notifyListeners();

    await updateTeamInDatabase(teamItem);
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
        final team = ObjectTeam(
          teamId: IdUtils.stableIdFromString(row['id'] as String),
          teamName: row['teamname'] ?? '',
          teamLogo: row['banner_url'] ?? '',
          teamNuyen: row['stats']?['nuyen'] ?? 1000,
          dbId: row['id'] as String?,
        );

        // Parse players JSON array
        final playersJson = row['players'] as List<dynamic>?;
        if (playersJson != null) {
          for (final playerJson in playersJson) {
            team.teamPlayers.add(
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
