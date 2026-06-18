import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:random_name_generator/random_name_generator.dart';
//import 'package:open_brawl/objects/ub_player.dart';

class ProviderTeam extends ChangeNotifier {
  final List<ObjectTeam> _teams = [];
  List<ObjectTeam> get teams => _teams;
  final randomNames = RandomNames(Zone.germany);

  int getTeamPosition(ObjectTeam teamIteam) {
    return _teams.indexWhere((team) => team.teamId == teamIteam.teamId);
  }

  void addTeam(ObjectTeam newTeam) {
    _teams.add(newTeam);
    notifyListeners();
  }

  void removeTeam(ObjectTeam oldTeam) {
    final teamPosition = getTeamPosition(oldTeam);

    if (teamPosition >= 0) {
      _teams.removeAt(teamPosition);
      notifyListeners();
    }
  }

  void addCharacterToTeam(ObjectTeam teamIteam, ObjectPlayer newPlayer) {
    _teams[getTeamPosition(teamIteam)].teamPlayers.add(newPlayer);
    notifyListeners();
  }

  void modifyCharacterInTeam(ObjectTeam teamIteam, ObjectPlayer newPlayer) {
    int position = getListPosition(teamIteam, newPlayer);
    removeCharacterfromTeam(teamIteam, newPlayer);
    _teams[getTeamPosition(teamIteam)].teamPlayers.insert(position, newPlayer);

    notifyListeners();
  }

  int getListPosition(ObjectTeam teamIteam, ObjectPlayer characterIteam) {
    return _teams[getTeamPosition(teamIteam)].teamPlayers.indexWhere(
      (character) => character.id == characterIteam.id,
    );
  }

  void removeCharacterfromTeam(ObjectTeam teamIteam, ObjectPlayer oldPlayer) {
    int position = getListPosition(teamIteam, oldPlayer);
    if (position >= 0) {
      _teams[getTeamPosition(teamIteam)].teamPlayers.removeAt(position);
      notifyListeners();
    }
  }

  void adjustMoney(ObjectTeam teamIteam, int deductable) {
    _teams[getTeamPosition(teamIteam)].teamNuyen += deductable;
  }
}
