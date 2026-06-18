import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:open_brawl/objects/object_player.dart';

class ObjectTeam {
  int teamId;
  String teamName;
  String teamLogo;
  int teamNuyen;
  List<ObjectPlayer> teamPlayers = [];
  DateTime timeCreated = DateTime.now();

  ObjectTeam({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.teamNuyen,
  });

  factory ObjectTeam.createTeam(String teamName, String teamLogo) {
    final bytes = utf8.encode(DateTime.now().microsecondsSinceEpoch.toString());
    final digest = sha256.convert(bytes);

    return ObjectTeam(
      teamId: digest.hashCode,
      teamName: teamName,
      teamLogo: teamLogo,
      teamNuyen: 1000,
    );
  }

  bool getIsTeamValid() {
    if (teamPlayers.isNotEmpty) {
      final int countScout = teamPlayers
          .where((player) => player.position == TeamPositions.scout)
          .length;
      final int countBanger = teamPlayers
          .where((player) => player.position == TeamPositions.banger)
          .length;
      final int countHeavies = teamPlayers
          .where((player) => player.position == TeamPositions.heavy)
          .length;
      final int countBlaster = teamPlayers
          .where((player) => player.position == TeamPositions.blaster)
          .length;
      final int countOutrider = teamPlayers
          .where((player) => player.position == TeamPositions.outrider)
          .length;
      final int countMedico = teamPlayers
          .where((player) => player.position == TeamPositions.medico)
          .length;

      if ((countScout == 4) &&
          (countBanger == 4) &&
          (countHeavies == 2) &&
          (countBlaster == 1) &&
          (countOutrider == 1) &&
          (countMedico == 1)) {
        return true;
      }
    }

    return false;
  }
}
