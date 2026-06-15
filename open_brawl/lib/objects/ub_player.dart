import 'package:open_brawl/objects/equipment_manager.dart';
import 'package:open_brawl/objects/magic_resonance.dart';
import 'package:open_brawl/objects/skll_manager.dart';

enum PlayerRace {
  mensch,
  elf,
  zwerg,
  ork,
  troll,
}

class UbPlayer {
  int key;
  String name;
  String image;

  int body;
  int agility;
  int reaction;
  int strength;
  int willpower;
  int logic;
  int intuition;
  int charisma;
  double essence;
  int edge;
  int initative;
  int conSave;
  int menSave;
  int bodyDamage;
  int mentalDamage;
  int movementPointsWalk;
  int movementPointsRun;
  int armor;
  PlayerRace playerRace;
  SkillManager skillManager = SkillManager();
  late EquipmentManager equipmentManager;
  late MagicResonanceManager magicResonanceManager;

  UbPlayer({
    required this.key,
    required this.name,
    this.image = "",
    required this.body,
    required this.agility,
    required this.reaction,
    required this.strength,
    required this.willpower,
    required this.logic,
    required this.intuition,
    required this.charisma,
    this.essence = 6.0,
    required this.edge,
    this.initative = 0,
    this.conSave = 0,
    this.menSave = 0,
    this.bodyDamage = 0,
    this.mentalDamage = 0,
    this.movementPointsWalk = 0,
    this.movementPointsRun = 0,
    this.armor = 0,
    this.playerRace = PlayerRace.mensch,
  }) {
    equipmentManager = EquipmentManager(this);
    magicResonanceManager = MagicResonanceManager();
  }

  /// Konvertiert das UbPlayer-Objekt in einen Map, der in einer Datenbank
  /// (z.B. SQLite, Firebase) oder SharedPreferences gespeichert werden kann.
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'name': name,
      'image': image,
      'body': body,
      'agility': agility,
      'reaction': reaction,
      'strength': strength,
      'willpower': willpower,
      'logic': logic,
      'intuition': intuition,
      'charisma': charisma,
      'essence': essence,
      'edge': edge,
      'initative': initative,
      'conSave': conSave,
      'menSave': menSave,
      'bodyDamage': bodyDamage,
      'mentalDamage': mentalDamage,
      'movementPointsWalk': movementPointsWalk,
      'movementPointsRun': movementPointsRun,
      'armor': armor,
      'playerRace': playerRace.index, // Speichere den Index des Enums
      'skills': skillManager.toMapList(),
      'equipment': equipmentManager.toMap(),
      'magicResonance': magicResonanceManager.toMap(),
    };
  }

  /// Erstellt ein UbPlayer-Objekt aus einem Map (z.B. aus einer Datenbank).
  factory UbPlayer.fromMap(Map<String, dynamic> map) {
    final player = UbPlayer(
      key: map['key'] as int,
      name: map['name'] as String,
      image: map['image'] as String? ?? '',
      body: map['body'] as int,
      agility: map['agility'] as int,
      reaction: map['reaction'] as int,
      strength: map['strength'] as int,
      willpower: map['willpower'] as int,
      logic: map['logic'] as int,
      intuition: map['intuition'] as int,
      charisma: map['charisma'] as int,
      essence: map['essence'] as double? ?? 6.0,
      edge: map['edge'] as int,
      initative: map['initative'] as int? ?? 0,
      conSave: map['conSave'] as int? ?? 0,
      menSave: map['menSave'] as int? ?? 0,
      bodyDamage: map['bodyDamage'] as int? ?? 0,
      mentalDamage: map['mentalDamage'] as int? ?? 0,
      movementPointsWalk: map['movementPointsWalk'] as int? ?? 0,
      movementPointsRun: map['movementPointsRun'] as int? ?? 0,
      armor: map['armor'] as int? ?? 0,
      playerRace: PlayerRace.values[map['playerRace'] as int? ?? 0],
    );

    if (map['skills'] != null) {
      player.skillManager.fromMapList(
        List<Map<String, dynamic>>.from(map['skills']),
      );
    } else {
      player.skillManager.initializeDefaultSkills();
    }

    if (map['equipment'] != null) {
      player.equipmentManager.fromMap(map['equipment']);
    }

    if (map['magicResonance'] != null) {
      player.magicResonanceManager.fromMap(map['magicResonance']);
    }

    return player;
  }

  /// Optional: Für bessere Debug-Ausgaben
  @override
  String toString() {
    return 'UbPlayer(key: $key, name: $name, body: $body, agility: $agility, playerRace: $playerRace)';
  }

  /// Erstellt eine Kopie dieses UbPlayers mit geänderten Werten.
  ///
  /// Alle Parameter sind optional. Wird ein Parameter nicht übergeben,
  /// bleibt der Wert aus dem Original erhalten.
  UbPlayer copyWith({
    int? key,
    String? name,
    String? image,
    int? body,
    int? agility,
    int? reaction,
    int? strength,
    int? willpower,
    int? logic,
    int? intuition,
    int? charisma,
    double? essence,
    int? edge,
    int? initative,
    int? conSave,
    int? menSave,
    int? bodyDamage,
    int? mentalDamage,
    int? movementPointsWalk,
    int? movementPointsRun,
    int? armor,
    PlayerRace? playerRace,
  }) {
    return UbPlayer(
      key: key ?? this.key,
      name: name ?? this.name,
      image: image ?? this.image,
      body: body ?? this.body,
      agility: agility ?? this.agility,
      reaction: reaction ?? this.reaction,
      strength: strength ?? this.strength,
      willpower: willpower ?? this.willpower,
      logic: logic ?? this.logic,
      intuition: intuition ?? this.intuition,
      charisma: charisma ?? this.charisma,
      essence: essence ?? this.essence,
      edge: edge ?? this.edge,
      initative: initative ?? this.initative,
      conSave: conSave ?? this.conSave,
      menSave: menSave ?? this.menSave,
      bodyDamage: bodyDamage ?? this.bodyDamage,
      mentalDamage: mentalDamage ?? this.mentalDamage,
      movementPointsWalk: movementPointsWalk ?? this.movementPointsWalk,
      movementPointsRun: movementPointsRun ?? this.movementPointsRun,
      armor: armor ?? this.armor,
      playerRace: playerRace ?? this.playerRace,
    );
  }

  /// Berechnet die maximale Anzahl an körperlichen Schadenskästchen
  int get maxPhysicalDamage {
    return 8 + (body ~/ 2); // ~/ ist Ganzzahl-Division (abgerundet)
  }

  /// Berechnet die maximale Anzahl an geistigen Schadenskästchen
  int get maxMentalDamage {
    return 8 + (willpower ~/ 2);
  }

  /// Prüft, ob der Charakter bewusstlos ist (körperlich oder geistig überfüllt)
  bool get isUnconscious {
    return bodyDamage >= maxPhysicalDamage || mentalDamage >= maxMentalDamage;
  }

  /// Prüft, ob der Charakter tot ist (nur bei körperlichem Schaden)
  bool get isDead {
    // Tod tritt ein, wenn der körperliche Schadensmonitor VOLL überfüllt ist
    // Also mehr Schaden als maxPhysicalDamage (die Regel sagt: > maxPhysicalDamage)
    return bodyDamage > maxPhysicalDamage;
  }

  /// Prüft, ob der Charakter noch handlungsfähig ist
  bool get isConscious {
    return !isUnconscious;
  }

  /// Berechnet den aktuellen Wundmalus (Wound Penalty)
  /// Bei jedem angefangenen Drittel des Schadensmonitors gibt es -1 auf alle Würfe
  int get woundPenalty {
    if (bodyDamage <= 0) return 0;

    final oneThird = maxPhysicalDamage / 3;
    if (bodyDamage > oneThird * 2) return 3;
    if (bodyDamage > oneThird) return 2;
    return 1;
  }

  /// Gibt eine lesbare Status-Beschreibung zurück
  String get statusDescription {
    if (isDead) return "Tot 💀";
    if (isUnconscious) return "Bewusstlos 😵";

    final penalty = woundPenalty;
    if (penalty > 0) return "Verletzt (-$penalty) 🤕";
    return "Gesund ✅";
  }

  /// Gibt eine detaillierte Übersicht der Schadensmonitore zurück
  String get damageMonitorReport {
    return """
    ┌─────────────────────────────┐
    │ Status: $statusDescription
    ├─────────────────────────────┤
    │ Körperlich: $bodyDamage / $maxPhysicalDamage
    │ Geistig:    $mentalDamage / $maxMentalDamage
    │ Wundmalus:  -$woundPenalty
    └─────────────────────────────┘
    """;
  }

  /// Fügt körperlichen Schaden hinzu (automatisch limitiert)
  UbPlayer addPhysicalDamage(int amount) {
    final newDamage = bodyDamage + amount;
    final clamped = newDamage.clamp(0, maxPhysicalDamage + 1);
    return copyWith(bodyDamage: clamped);
  }

  /// Fügt geistigen Schaden hinzu (automatisch limitiert)
  UbPlayer addMentalDamage(int amount) {
    final newDamage = mentalDamage + amount;
    final clamped = newDamage.clamp(0, maxMentalDamage);
    return copyWith(mentalDamage: clamped);
  }

  /// Heilt körperlichen Schaden
  UbPlayer healPhysicalDamage(int amount) {
    final newDamage = (bodyDamage - amount).clamp(0, maxPhysicalDamage + 1);
    return copyWith(bodyDamage: newDamage);
  }

  /// Heilt geistigen Schaden
  UbPlayer healMentalDamage(int amount) {
    final newDamage = (mentalDamage - amount).clamp(0, maxMentalDamage);
    return copyWith(mentalDamage: newDamage);
  }

  /// Vollständige Heilung (nach einem Run)
  UbPlayer fullHeal() {
    return copyWith(
      bodyDamage: 0,
      mentalDamage: 0,
    );
  }

  void calculateBaseValues() {
    initative = intuition + reaction;
    conSave = body + willpower;
    menSave = logic + willpower;
    bodyDamage = 8 + (body ~/ 2);
    mentalDamage = 8 + (willpower ~/ 2);
    movementPointsWalk = agility * 2;
    movementPointsRun = agility * 4;
  }

  int calcSprint() {
    /*    Probe: Laufen + Stärke

    Effekt: Jeder Erfolg auf die Probe erhöht deine zurückgelegte Distanz in dieser Runde um zusätzliche 2 Meter (bei Zwergen und Trollen nur 1 Meter pro Erfolg).

    Beispiel: Dein Mensch mit Beweglichkeit 5 (Laufrate 20m) sprintet und erzielt 3 Erfolge. Er kann sich in dieser Runde insgesamt 20 + (3 x 2) = 26 Meter bewegen. */
    return 0;
  }
}

/*
// Original-Spieler
final player = UbPlayer(
  key: 1,
  name: 'Ghost',
  body: 4,
  agility: 5,
  reaction: 3,
  strength: 3,
  willpower: 4,
  logic: 5,
  intuition: 4,
  charisma: 2,
  edge: 3,
);

// 1. Schaden verarbeiten (z.B. 2 Kästchen körperlichen Schaden)
final damagedPlayer = player.copyWith(
  bodyDamage: player.bodyDamage + 2,
);

// 2. Temporären Attributsbonus durch Magie oder Drogen
final boostedPlayer = player.copyWith(
  agility: player.agility + 2,
  reaction: player.reaction + 1,
  edge: player.edge - 1, // Drogen kosten Edge-Punkte
);

// 3. Charakterentwicklung nach einem Run (Karma ausgegeben)
final leveledPlayer = player.copyWith(
  body: player.body + 1,
  willpower: player.willpower + 1,
  edge: player.edge + 1,
  key: 1, // key bleibt gleich, das ist ja derselbe Charakter
);

// 4. Nur ein Feld ändern (z.B. Rüstung anziehen)
final armoredPlayer = player.copyWith(armor: 12);

// 5. Nach dem Heilen (Schadensmonitor leeren)
final healedPlayer = player.copyWith(
  bodyDamage: 0,
  mentalDamage: 0,
);

// 6. Komplexe Änderungen auf einmal (z.B. Initiative für Kampfrunde berechnen)
final combatReadyPlayer = player.copyWith(
  initative: player.intuition + player.reaction,
  movementPointsWalk: player.agility * 2,
  movementPointsRun: player.agility * 4,
);

class UbPlayer {
  // ... bestehende Felder

  /// Fügt körperlichen Schaden hinzu (gekappt bei Maximalwerten)
  UbPlayer addPhysicalDamage(int amount) {
    final maxDamage = 8 + (body ~/ 2); // Siehe deine vorherige Frage!
    final newDamage = (bodyDamage + amount).clamp(0, maxDamage);
    return copyWith(bodyDamage: newDamage);
  }

  /// Heilt körperlichen Schaden
  UbPlayer healPhysicalDamage(int amount) {
    return copyWith(bodyDamage: (bodyDamage - amount).clamp(0, 999));
  }

  /// Berechnet Initiative neu (für Kampfbeginn)
  UbPlayer refreshInitiative() {
    return copyWith(
      initative: intuition + reaction,
    );
  }

  /// Berechnet Bewegungsreichweiten neu (nach Attributsänderung)
  UbPlayer refreshMovement() {
    return copyWith(
      movementPointsWalk: agility * 2,
      movementPointsRun: agility * 4,
    );
  }
}

// Verwendung:
player = player
    .addPhysicalDamage(5)
    .refreshInitiative()
    .copyWith(armor: 8);
 */
