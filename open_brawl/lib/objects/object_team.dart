import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/utils/id_utils.dart';

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
    return ObjectTeam(
      teamId: IdUtils.uniqueId('team|$teamName'),
      teamName: teamName,
      teamLogo: teamLogo,
      teamNuyen: 1000,
    );
  }

  bool get isTeamValid {
    if (teamPlayers.isEmpty) return false;

    int countScout = 0, countJaeger = 0, countBrecher = 0;
    int countSchuetze = 0, countStuermer = 0, countSani = 0;

    for (final player in teamPlayers) {
      switch (player.position) {
        case TeamPositions.scout:   countScout++;
        case TeamPositions.jaeger:  countJaeger++;
        case TeamPositions.brecher: countBrecher++;
        case TeamPositions.schuetze: countSchuetze++;
        case TeamPositions.stuermer: countStuermer++;
        case TeamPositions.sani:    countSani++;
        case TeamPositions.inactive: break;
      }
    }

    return countScout == 4 &&
        countJaeger == 4 &&
        countBrecher == 2 &&
        countSchuetze == 1 &&
        countStuermer == 1 &&
        countSani == 1;
  }
}
