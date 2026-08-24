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
  String? dbId; // UUID from Supabase

  ObjectTeam({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.teamNuyen,
    this.dbId,
  });

  factory ObjectTeam.create(String teamName, String teamLogo) {
    final bytes = utf8.encode(DateTime.now().microsecondsSinceEpoch.toString());
    final digest = sha256.convert(bytes);

    return ObjectTeam(
      teamId: digest.hashCode,
      teamName: teamName,
      teamLogo: teamLogo,
      teamNuyen: 1000,
    );
  }

  bool get isTeamValid {
    if (teamPlayers.isEmpty) return false;

    int countScout = 0, countBanger = 0, countHeavy = 0;
    int countBlaster = 0, countOutrider = 0, countMedico = 0;

    for (final player in teamPlayers) {
      switch (player.position) {
        case TeamPositions.scout:    countScout++;
        case TeamPositions.banger:   countBanger++;
        case TeamPositions.heavy:    countHeavy++;
        case TeamPositions.blaster:  countBlaster++;
        case TeamPositions.outrider: countOutrider++;
        case TeamPositions.medico:   countMedico++;
        case TeamPositions.inactive: break;
      }
    }

    return countScout == 4 &&
        countBanger == 4 &&
        countHeavy == 2 &&
        countBlaster == 1 &&
        countOutrider == 1 &&
        countMedico == 1;
  }
}
