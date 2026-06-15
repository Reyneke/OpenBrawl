import 'package:flutter/material.dart';
import 'package:open_brawl/objects/ub_player.dart';

class ProviderTeam extends ChangeNotifier {
  final List<UbPlayer> _players = [];
  List<UbPlayer> get players => _players;

  void addPlayer(UbPlayer newPlayer) {
    newPlayer.calculateBaseValues();
    _players.add(newPlayer);
    notifyListeners();
  }

  void removePlayer(UbPlayer oldPlayer) {
    _players.removeAt(_players.indexOf(oldPlayer));
  }
}
