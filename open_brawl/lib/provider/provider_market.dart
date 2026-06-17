import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:random_name_generator/random_name_generator.dart';

class ProviderMarket extends ChangeNotifier {
  final List<ObjectPlayer> _availiblePlayers = [];
  List<ObjectPlayer> get availiblePlayers => _availiblePlayers;
  final randomNames = RandomNames(Zone.germany);

  int getListPosition(ObjectPlayer characterIteam) {
    return _availiblePlayers.indexWhere(
      (character) => character.id == characterIteam.id,
    );
  }

  void createDummyCharacters() {
    final maxNumOfCharacters = 40 - _availiblePlayers.length;

    for (int i = 0; i < maxNumOfCharacters; ++i) {
      _availiblePlayers.add(ObjectPlayer.newPlayer(randomNames.name(), ""));
    }
  }

  void removeCharacter(ObjectPlayer oldPlayer) {
    int position = getListPosition(oldPlayer);
    if (position >= 0) {
      _availiblePlayers.removeAt(position);
    }
  }

  void addCharacter(ObjectPlayer newPlayer) {
    _availiblePlayers.add(newPlayer);
  }
}
