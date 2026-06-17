import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:open_brawl/objects/object_player.dart';

class ObjectTeam {
  int teamId;
  String teamName;
  String teamLogo;
  int teamNuyen;
  List<ObjectPlayer> teamPlayers = [];

  ObjectTeam({
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
    required this.teamNuyen,
  });

  factory ObjectTeam.createTeam(String teamName, String teamLogo) {
    final bytes = utf8.encode(teamName);
    final digest = sha256.convert(bytes);

    return ObjectTeam(
      teamId: digest.hashCode,
      teamName: teamName,
      teamLogo: teamLogo,
      teamNuyen: 1000,
    );
  }
}
