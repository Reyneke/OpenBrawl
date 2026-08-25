import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/utils/id_utils.dart';

/// Team-Statistik über gewonnene, verlorene und unentschieden beendete
/// Matches. Daraus errechnet sich die Gesamtqualität des Teams nach dem
/// 3-1-0-Schema ([quality]: Sieg = 3, Unentschieden = 1, Niederlage = 0).
class TeamMatchRecord {
  /// Gewonnene Matches.
  int won = 0;

  /// Verlorene Matches.
  int lost = 0;

  /// Unentschieden beendete Matches.
  int drawn = 0;

  TeamMatchRecord({this.won = 0, this.lost = 0, this.drawn = 0});

  /// Gesamtzahl der gespielten Matches.
  int get gamesPlayed => won + lost + drawn;

  /// Gesamtqualität nach dem 3-1-0-Schema.
  int get quality => won * 3 + drawn;

  void recordWin() => won++;
  void recordLoss() => lost++;
  void recordDraw() => drawn++;

  Map<String, dynamic> toJson() => {'won': won, 'lost': lost, 'drawn': drawn};

  /// Tolerantes Parsen: fehlende Keys zählen als 0.
  factory TeamMatchRecord.fromJson(Map<String, dynamic>? json) {
    return TeamMatchRecord(
      won: ((json?['won'] as num?) ?? 0).toInt(),
      lost: ((json?['lost'] as num?) ?? 0).toInt(),
      drawn: ((json?['drawn'] as num?) ?? 0).toInt(),
    );
  }

  @override
  String toString() =>
      'TeamMatchRecord(won: $won, lost: $lost, drawn: $drawn, '
      'Qualität: $quality)';
}

/// Ein Team im Urban-Brawl-Universum: Kader aus [ObjectPlayer]n plus Geld
/// (Nuyen), Logo und Persistenz-Verweis auf Supabase.
///
/// Der Kader ist gekapselt ([players] liefert eine unveränderliche Ansicht);
/// Änderungen laufen über [addPlayer], [removePlayer] und [updatePlayer].
/// Die Kaderobergrenze [maxRosterSize] und die Pflichtrollen aus
/// [requiredRoster] werden damit im Modell durchgesetzt (siehe
/// `doc/plan/1_grundzuege/4_Object_Team.md`).
class ObjectTeam {
  /// Erforderliche Verteilung der aktiven Rollen (13 Feldspieler):
  /// 4 Scout, 4 Jäger, 2 Brecher, 1 Schütze, 1 Stürmer, 1 Sani.
  static const Map<TeamPositions, int> requiredRoster = {
    TeamPositions.scout: 4,
    TeamPositions.jaeger: 4,
    TeamPositions.brecher: 2,
    TeamPositions.schuetze: 1,
    TeamPositions.stuermer: 1,
    TeamPositions.sani: 1,
  };

  /// Maximale Kadergröße inklusive Ersatzspielern (`inactive`).
  static const int maxRosterSize = 20;

  /// Startkapital eines neuen Teams.
  static const int defaultNuyen = 1000;

  int id;
  String name;
  String logo;
  int nuyen;

  /// Kapitän des Teams (Spieler-ID) oder null, wenn noch keiner ernannt
  /// ist. Muss vor Matchbeginn gesetzt sein; wird er geprüft über
  /// [hasCaptain], der Spieler also tatsächlich noch im Kader geführt.
  int? captainId;

  /// Statistik über gewonnene, verlorene und unentschieden beendete
  /// Matches samt Gesamtqualität ([TeamMatchRecord.quality]).
  TeamMatchRecord record;

  /// Erstellungszeitpunkt: beim Anlegen `DateTime.now()`, beim Laden aus
  /// Supabase wird `created_at` übernommen.
  final DateTime timeCreated;

  String? dbId; // UUID from Supabase

  final List<ObjectPlayer> _players;

  /// Unveränderliche Ansicht auf den Kader.
  List<ObjectPlayer> get players => List.unmodifiable(_players);

  ObjectTeam({
    required this.id,
    required this.name,
    required this.logo,
    required this.nuyen,
    this.dbId,
    this.captainId,
    DateTime? timeCreated,
    List<ObjectPlayer>? players,
    TeamMatchRecord? record,
  })  : timeCreated = timeCreated ?? DateTime.now(),
        record = record ?? TeamMatchRecord(),
        _players = players ?? <ObjectPlayer>[];

  factory ObjectTeam.create(String name, String logo) {
    return ObjectTeam(
      id: IdUtils.uniqueId('team|$name'),
      name: name,
      logo: logo,
      nuyen: defaultNuyen,
    );
  }

  /// Ob ein Spieler mit dieser ID bereits im Kader steht.
  bool hasPlayer(ObjectPlayer player) =>
      _players.any((p) => p.id == player.id);

  /// Index des Spielers (per ID) im Kader oder -1.
  int indexOfPlayer(ObjectPlayer player) =>
      _players.indexWhere((p) => p.id == player.id);

  /// Fügt einen Spieler hinzu. Schlägt fehl, wenn der Kader voll ist
  /// ([maxRosterSize]) oder die ID bereits vergeben ist.
  bool addPlayer(ObjectPlayer player) {
    if (_players.length >= maxRosterSize) return false;
    if (hasPlayer(player)) return false;
    _players.add(player);
    return true;
  }

  /// Entfernt einen Spieler (per ID); `false`, wenn nicht gefunden.
  bool removePlayer(ObjectPlayer player) {
    final index = indexOfPlayer(player);
    if (index < 0) return false;
    _players.removeAt(index);
    return true;
  }

  /// Ersetzt den gespeicherten Spieler mit gleicher ID durch [player];
  /// die Position im Kader bleibt erhalten. `false`, wenn nicht gefunden.
  bool updatePlayer(ObjectPlayer player) {
    final index = indexOfPlayer(player);
    if (index < 0) return false;
    _players[index] = player;
    return true;
  }

  /// Der aktuell ernannte Kapitän oder null – auch dann null, wenn die
  /// hinterlegte ID nicht mehr im Kader steht.
  ObjectPlayer? get captain {
    final id = captainId;
    if (id == null) return null;
    for (final player in _players) {
      if (player.id == id) return player;
    }
    return null;
  }

  /// Ob ein gültiger Kapitän ernannt ist (ID im Kader vorhanden).
  bool get hasCaptain => captain != null;

  /// Ernnt [player] zum Kapitän (muss im Kader stehen) oder entfernt die
  /// Ernstennung ([player] = null). `false`, wenn [player] nicht im Kader ist.
  bool setCaptain(ObjectPlayer? player) {
    if (player == null) {
      captainId = null;
      return true;
    }
    if (!hasPlayer(player)) return false;
    captainId = player.id;
    return true;
  }

  /// Ob die Rolle [role] im Feld noch frei ist – also weniger aktive
  /// Spieler in dieser Rolle stehen, als [requiredRoster] vorsieht.
  /// Grundlage für den Rollenwechsel vor einem Spielzug; [exceptPlayerId]
  /// wird nicht mitgezählt (der wechselnde Spieler selbst).
  ///
  /// Es zählt jeweils die Primärrolle bzw. – während eines Matches – die
  /// vom Spielzug-System gesetzte aktive Rolle.
  bool isRoleFree(TeamPositions role, {int? exceptPlayerId}) {
    final required = requiredRoster[role] ?? 0;
    var count = 0;
    for (final player in _players) {
      if (player.id == exceptPlayerId) continue;
      if (player.position == role) count++;
    }
    return count < required;
  }

  /// Gültig, wenn exakt die in [requiredRoster] geforderten aktiven
  /// Spieler im Kader stehen. `inactive` zählt nicht mit; eine leere
  /// Liste ist ungültig.
  bool get isTeamValid {
    if (_players.isEmpty) return false;

    final counts = <TeamPositions, int>{};
    for (final player in _players) {
      if (player.position == TeamPositions.inactive) continue;
      counts[player.position] = (counts[player.position] ?? 0) + 1;
    }

    for (final entry in requiredRoster.entries) {
      if (counts[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Kanonische Serialisierung (inkl. Kader über [ObjectPlayer.toJson]).
  Map<String, dynamic> toJson() => {
        'id': id,
        'dbId': dbId,
        'name': name,
        'logo': logo,
        'nuyen': nuyen,
        'captainId': captainId,
        'created_at': timeCreated.toIso8601String(),
        'record': record.toJson(),
        'players': _players.map((player) => player.toJson()).toList(),
      };

  /// Tolerantes Parsen: akzeptiert das kanonische [toJson]-Format sowie das
  /// ältere Match-JSON (`id` enthielt dort die DB-UUID, die lokale Int-ID
  /// lag unter `team_id`; Namen unter `team_name` usw.).
  factory ObjectTeam.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final dbId = json['dbId'] as String? ?? (rawId is String ? rawId : null);
    final legacyTeamId = json['team_id'];
    final id = rawId is num
        ? rawId.toInt()
        : legacyTeamId is num
            ? legacyTeamId.toInt()
            : IdUtils.stableIdFromString(dbId ?? 'team');
    return ObjectTeam(
      id: id,
      dbId: dbId,
      name: (json['name'] ?? json['team_name']) as String? ?? '',
      logo: (json['logo'] ?? json['team_logo']) as String? ?? '',
      nuyen: ((json['nuyen'] ?? json['team_nuyen']) as num?)?.toInt() ??
          defaultNuyen,
      captainId: (json['captainId'] as num?)?.toInt(),
      timeCreated: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      record: TeamMatchRecord.fromJson(json['record'] as Map<String, dynamic>?),
      players: ((json['players'] as List<dynamic>?) ?? [])
          .map((e) => ObjectPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'ObjectTeam(id: $id, name: $name, '
      'Spieler: ${_players.length}, Nuyen: $nuyen)';
}
