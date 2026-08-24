import 'dart:math';

import 'package:open_brawl/utils/id_utils.dart';

/// Parst einen serialisierten Enum-Namen (neu oder alt) in einen Enum-Wert.
///
/// Gemeinsame Hilfsfunktion für alle Enums dieser Datei, damit die
/// Fallback-Logik nur einmal gepflegt werden muss:
/// 1. Exakter Treffer auf einen der aktuellen Namen ([values]).
/// 2. Treffer in [legacyNames] (Alt-Bezeichner bereits persistierter Daten).
/// 3. Sonst [fallback].
T _enumFromName<T extends Enum>(
  List<T> values,
  String? name,
  T fallback, {
  Map<String, T> legacyNames = const {},
}) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return legacyNames[name] ?? fallback;
}

/// Rollennamen gemäß Doku (`doc/plan/spielablauf/spielablauf.md`),
/// Umlaute für Code/Serialisierung ersetzt (ä→ae, ü→ue).
enum TeamPositions {
  inactive,
  scout,
  jaeger,
  brecher,
  schuetze,
  stuermer,
  sani;

  /// Deutscher Anzeigename (mit Umlauten), z. B. für Dropdowns und Labels.
  String get displayName => switch (this) {
        TeamPositions.inactive => 'Ersatz',
        TeamPositions.scout => 'Scout',
        TeamPositions.jaeger => 'Jäger',
        TeamPositions.brecher => 'Brecher',
        TeamPositions.schuetze => 'Schütze',
        TeamPositions.stuermer => 'Stürmer',
        TeamPositions.sani => 'Sani',
      };

  /// Lookup-Tabelle der aktuellen Namen (O(1) statt linearem Scan).
  static final Map<String, TeamPositions> _valuesByName = {
    for (final value in TeamPositions.values) value.name: value,
  };

  /// Alt-Bezeichner aus dem Code vor der Vereinheitlichung, damit bereits
  /// in Supabase persistierte Werte beim Parsen korrekt zugeordnet werden.
  static final Map<String, TeamPositions> _legacyNames = {
    'banger': TeamPositions.jaeger,
    'heavy': TeamPositions.brecher,
    'blaster': TeamPositions.schuetze,
    'outrider': TeamPositions.stuermer,
    'medico': TeamPositions.sani,
  };

  /// Parst einen serialisierten Rollennamen (neu oder alt) in einen Enum-Wert.
  static TeamPositions fromName(String? name) {
    if (name == null) return TeamPositions.inactive;
    return _valuesByName[name] ?? _legacyNames[name] ?? TeamPositions.inactive;
  }
}

/// Verletzungszustand eines Spielers. Die Deklarationsreihenfolge entspricht
/// dem Schweregrad (siehe `doc/plan/spielerwerte/spielerwerte.md` und das
/// Zustandsmonitor-Konzept aus "Blut & Spiele").
enum CharacterStatus {
  fine,
  reeling,
  hurt,
  afraid,
  injured,
  dying,
  dead,
  overkilled;

  /// Deutscher Anzeigename, z. B. für Status-Chips in der UI.
  String get displayName => switch (this) {
        CharacterStatus.fine => 'Unverletzt',
        CharacterStatus.reeling => 'Benommen',
        CharacterStatus.hurt => 'Verletzt',
        CharacterStatus.afraid => 'Verängstigt',
        CharacterStatus.injured => 'Schwer verletzt',
        CharacterStatus.dying => 'Sterbend',
        CharacterStatus.dead => 'Tot',
        CharacterStatus.overkilled => 'Übertötet',
      };

  /// Ob der Spieler noch am Leben ist (`dead`/`overkilled` sind endgültig).
  bool get isAlive => index < CharacterStatus.dead.index;

  /// Ob der Spieler einsatzbereit auf dem Feld stehen kann.
  bool get isFitToPlay => this == CharacterStatus.fine;

  /// Parst einen serialisierten Statusnamen; unbekannte Werte → [fine].
  static CharacterStatus fromName(String? name) =>
      _enumFromName(values, name, CharacterStatus.fine);
}

/// Die sieben direkt beeinflussbaren Attribute eines Spielers (aus
/// `doc/plan/spielerwerte/spielerwerte.md`).
enum PlayerAttribute {
  attack,
  agility,
  defense,
  resistance,
  attention,
  morale,
  edge;

  String get displayName => switch (this) {
        PlayerAttribute.attack => 'Angriff',
        PlayerAttribute.agility => 'Agilität',
        PlayerAttribute.defense => 'Verteidigung',
        PlayerAttribute.resistance => 'Widerstand',
        PlayerAttribute.attention => 'Aufmerksamkeit',
        PlayerAttribute.morale => 'Moral',
        PlayerAttribute.edge => 'Edge',
      };
}

/// Rassen mit ihren Attribut-Modifikatoren (Doku "Object Player").
enum PlayerRace {
  mensch('Mensch', {
    PlayerAttribute.morale: 1,
    PlayerAttribute.edge: 1,
  }),
  elf('Elf', {
    PlayerAttribute.agility: 2,
    PlayerAttribute.resistance: -1,
    PlayerAttribute.morale: 1,
  }),
  ork('Ork', {
    PlayerAttribute.attack: 1,
    PlayerAttribute.resistance: 1,
  }),
  troll('Troll', {
    PlayerAttribute.attack: 1,
    PlayerAttribute.defense: 1,
    PlayerAttribute.resistance: 2,
    PlayerAttribute.attention: -1,
    PlayerAttribute.morale: -1,
  }),
  zwerg('Zwerg', {
    PlayerAttribute.agility: -1,
    PlayerAttribute.defense: 1,
    PlayerAttribute.resistance: 1,
  });

  final String displayName;
  final Map<PlayerAttribute, int> modifiers;

  const PlayerRace(this.displayName, this.modifiers);

  /// Modifikator für ein Attribut (0, wenn die Rasse keins besitzt).
  int modifierFor(PlayerAttribute attr) => modifiers[attr] ?? 0;

  static PlayerRace fromName(String? name) =>
      _enumFromName(PlayerRace.values, name, PlayerRace.mensch);
}

/// Persönlichkeit nach dem Enneagramm der Persönlichkeit (Typen 1–9,
/// Quelle: https://en.wikipedia.org/wiki/Enneagram_of_Personality).
enum EnneagramPersonality {
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine;

  String get displayName => switch (this) {
        EnneagramPersonality.one => 'Reformer',
        EnneagramPersonality.two => 'Helfer',
        EnneagramPersonality.three => 'Erfolgstyp',
        EnneagramPersonality.four => 'Individualist',
        EnneagramPersonality.five => 'Forscher',
        EnneagramPersonality.six => 'Loyalist',
        EnneagramPersonality.seven => 'Enthusiast',
        EnneagramPersonality.eight => 'Herausforderer',
        EnneagramPersonality.nine => 'Vermittler',
      };

  static EnneagramPersonality fromName(String? name) =>
      _enumFromName(values, name, EnneagramPersonality.one);
}

/// Match-Tracker eines Spielers über seine Karriere.
class PlayerMatchRecord {
  /// Siege, bei denen der Spieler dabei war.
  int won = 0;

  /// Niederlagen, bei denen der Spieler dabei war.
  int lost = 0;

  /// Spiele, die in einem Draw endeten.
  int drawn = 0;

  int get gamesPlayed => won + lost + drawn;

  /// Differenz Siege − Niederlagen (Basis für [ObjectPlayer.fame]).
  int get score => won - lost;

  void recordWin() => won++;
  void recordLoss() => lost++;
  void recordDraw() => drawn++;

  Map<String, dynamic> toJson() => {'won': won, 'lost': lost, 'drawn': drawn};

  PlayerMatchRecord({this.won = 0, this.lost = 0, this.drawn = 0});

  factory PlayerMatchRecord.fromJson(Map<String, dynamic>? json) {
    return PlayerMatchRecord(
      won: ((json?['won'] as num?) ?? 0).toInt(),
      lost: ((json?['lost'] as num?) ?? 0).toInt(),
      drawn: ((json?['drawn'] as num?) ?? 0).toInt(),
    );
  }
}

/// Repräsentiert einen einzelnen Spieler (Charakter) eines Teams.
///
/// Instanzen sind bewusst mutabel (z. B. Rollenwechsel über die UI,
/// Statusänderungen im Match). Serialisierung erfolgt über [toJson]/
/// [fromJson] nach Supabase bzw. Match-JSON.
///
/// Attribute: Die Basiswerte (1..6) werden bei `create()` zufällig verteilt
/// (26 Punkte auf 7 Attribute, Minimum je 1, Maximum je 6 – siehe
/// `doc/plan/1_grundzuege/3_Object_Player.md`). Rassenmodifikatoren ([race])
/// schieben den Endwert Richtung Obergrenze 9 (Cyber/Bio).
class ObjectPlayer {
  /// Standardbild, wenn kein eigenes Bild hinterlegt ist.
  static const String defaultImage = 'urbanbrawl_frame_leer.png';

  /// Skaliert den durchschnittlichen Attributwert auf den Marktpreis (Nuyen).
  static const int pricePerMarketValuePoint = 1000;

  /// Legacy-Default für nicht vorhandene Attribute (ergibt Marktwert 3 →
  /// Preis 3000, passend zum früheren [defaultPrice]).
  static const int defaultAttributePoint = 3;

  /// Früherer Standardpreis – nur noch als Kompatibilitätshinweis genutzt.
  static const int defaultPrice = 3000;

  /// Punktebudget für die Attributverteilung bei Spielererstellung.
  static const int creationPoints = 26;

  /// Minimum jedes Basisattributs.
  static const int minAttribute = 1;

  /// Maximum jedes Attributs ohne Cyber-/Bioware-Modifikatoren.
  static const int maxBaseAttribute = 6;

  /// Hard-Cap des Attributendwerts (Basis + Modifikatoren). Doku: "mit
  /// Cyber/Bioware 9".
  static const int augmentedAttributeCap = 9;

  /// Deterministische, namensbasierte Referenz-ID (für Legacy-Workflows).
  static int stableIdFromName(String name) => IdUtils.stableIdFromString(name);

  /// Eindeutige (aus dem Namen abgeleitete) ID des Spielers.
  int id;

  /// Anzeigename des Spielers.
  String name;

  /// Dateiname des Spielerbildes (Assets-Ordner `assets/images/`).
  String image;

  /// Zugewiesene Teamrolle.
  TeamPositions position;

  /// Aktueller Verletzungszustand.
  CharacterStatus status;

  /// Volksgruppe; liefert über [PlayerRace.modifiers] Rassenmodifikatoren.
  PlayerRace race;

  /// Enneagramm-Persönlichkeit laut Doku.
  EnneagramPersonality personality;

  /// Basisattribute (1..6, ohne Rassen-/Augment-Mods). Lesen über
  /// [baseAttributes], Ändern über [setBaseAttribute].
  Map<PlayerAttribute, int> _baseAttributes;

  /// Gewonnen/verloren/unentschieden-Spiele (Karriere-Tracker).
  PlayerMatchRecord matchRecord;

  /// Ruhm aus besonderen Spielzügen (Bonus zu [fame]).
  int specialPlayFame;

  ObjectPlayer({
    required this.id,
    required this.name,
    String? image,
    this.position = TeamPositions.inactive,
    this.status = CharacterStatus.fine,
    this.race = PlayerRace.mensch,
    this.personality = EnneagramPersonality.one,
    Map<PlayerAttribute, int>? baseAttributes,
    PlayerMatchRecord? matchRecord,
    this.specialPlayFame = 0,
  })  : image = image ?? defaultImage,
        _baseAttributes = Map.of(
          baseAttributes ?? _defaultBaseAttributes(),
        ),
        matchRecord = matchRecord ?? PlayerMatchRecord() {
    // Normalisierung: fehlende Attribut-Keys auf Default setzen.
    for (final attr in PlayerAttribute.values) {
      _baseAttributes.putIfAbsent(attr, () => defaultAttributePoint);
    }
  }

  /// Unveränderliche Sicht auf die Basisattribute.
  Map<PlayerAttribute, int> get baseAttributes =>
      Map.unmodifiable(_baseAttributes);

  /// Setzt ein Basisattribut (Wert wird auf 1..6 begrenzt).
  void setBaseAttribute(PlayerAttribute attr, int value) {
    _baseAttributes[attr] = value.clamp(minAttribute, maxBaseAttribute).toInt();
  }

  /// Attributendwert inkl. Rassenmodifikator.
  ///
  /// Wichtig: Der Rassenmodifikator verschiebt nicht nur den Attributwert,
  /// sondern auch das **Maximum** des Attributs mit (siehe
  /// `doc/plan/1_grundzuege/3_Object_Player.md`). Beispiel:
  /// Elf-Agilität (Mod +2) hat ohne Cyber/Bioware ein Maximum von
  /// `6 + 2 = 8`, Troll-Aufmerksamkeit (Mod −1) von `6 − 1 = 5`.
  /// Das absolute Maximum von 9 (Cyber/Bioware) bleibt bestehen; das
  /// absolute Minimum ist weiterhin 1.
  int value(PlayerAttribute attr) {
    final mod = race.modifierFor(attr);
    final effectiveMax =
        (maxBaseAttribute + mod).clamp(minAttribute, augmentedAttributeCap);
    return (_baseAttributes[attr]! + mod)
        .clamp(minAttribute, effectiveMax)
        .toInt();
  }

  int get attack => value(PlayerAttribute.attack);
  int get agility => value(PlayerAttribute.agility);
  int get defense => value(PlayerAttribute.defense);
  int get resistance => value(PlayerAttribute.resistance);
  int get attention => value(PlayerAttribute.attention);
  int get morale => value(PlayerAttribute.morale);
  int get edge => value(PlayerAttribute.edge);

  /// Summe aller Attributsendwerte (inkl. Modifier).
  int get totalAttributeValue => PlayerAttribute.values.fold(
        0,
        (sum, attr) => sum + value(attr),
      );

  /// Marktwert = Durchschnitt über alle Attribute (berechneter Wert).
  int get marketValue =>
      (totalAttributeValue / PlayerAttribute.values.length).round();

  /// Marktwert skalierter Marktpreis (Influencer: Marktwert).
  int get price => marketValue * pricePerMarketValuePoint;

  /// Ruhm = (Siege − Niederlagen) + Ruhm aus besonderen Spielzügen.
  int get fame => matchRecord.score + specialPlayFame;

  /// Erstellt einen neuen Spieler mit zufälliger Rasse, zufälliger
  /// Persönlichkeit und zufällig verteilten Basisattributen (26 Punkte).
  factory ObjectPlayer.create(String name, String image) {
    final random = Random();
    return ObjectPlayer(
      id: IdUtils.uniqueId(name),
      name: name,
      image: image,
      race: PlayerRace.values[random.nextInt(PlayerRace.values.length)],
      personality: ([...EnneagramPersonality.values]..shuffle(random)).first,
      baseAttributes: _randomBaseAttributes(random),
    );
  }

  /// Erstellt eine geänderte Kopie (nützlich für Provider-Updates und Tests).
  ObjectPlayer copyWith({
    int? id,
    String? name,
    String? image,
    TeamPositions? position,
    CharacterStatus? status,
    PlayerRace? race,
    EnneagramPersonality? personality,
    Map<PlayerAttribute, int>? baseAttributes,
    PlayerMatchRecord? matchRecord,
    int? specialPlayFame,
  }) =>
      ObjectPlayer(
        id: id ?? this.id,
        name: name ?? this.name,
        image: image ?? this.image,
        position: position ?? this.position,
        status: status ?? this.status,
        race: race ?? this.race,
        personality: personality ?? this.personality,
        baseAttributes: baseAttributes ?? Map.of(_baseAttributes),
        matchRecord: matchRecord ?? _copyMatchRecord(),
        specialPlayFame: specialPlayFame ?? this.specialPlayFame,
      );

  PlayerMatchRecord _copyMatchRecord() => PlayerMatchRecord()
    ..won = matchRecord.won
    ..lost = matchRecord.lost
    ..drawn = matchRecord.drawn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'position': position.name,
        'status': status.name,
        'race': race.name,
        'personality': personality.name,
        'attributes': {
          for (final attr in PlayerAttribute.values) attr.name: _baseAttributes[attr]!,
        },
        'record': matchRecord.toJson(),
        'specialPlayFame': specialPlayFame,
        'marketValue': marketValue,
        'price': price,
        'fame': fame,
      };

  /// Tolerantes Parsen: fehlende optionale Felder erhalten ihre Defaults,
  /// numerische Werte werden über [num] geparst (Supabase liefert teils
  /// `num` statt `int`). `price`/`marketValue`/`fame` werden berechnet und
  /// daher nicht eingelesen.
  factory ObjectPlayer.fromJson(Map<String, dynamic> json) {
    final player = ObjectPlayer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      image: json['image'] as String?,
      position: TeamPositions.fromName(json['position'] as String?),
      status: CharacterStatus.fromName(json['status'] as String?),
      race: PlayerRace.fromName(json['race'] as String?),
      personality:
          EnneagramPersonality.fromName(json['personality'] as String?),
      matchRecord: PlayerMatchRecord.fromJson(
        json['record'] as Map<String, dynamic>?,
      ),
      specialPlayFame: ((json['specialPlayFame'] as num?) ?? 0).toInt(),
    );
    final attributes = json['attributes'] as Map<String, dynamic>?;
    if (attributes != null) {
      for (final attr in PlayerAttribute.values) {
        final raw = attributes[attr.name];
        final value = (raw as num?)?.toInt();
        if (value != null) player.setBaseAttribute(attr, value);
      }
    }
    return player;
  }

  /// Start-Basisattribute (1..6), Summe exakt [creationPoints].
  static Map<PlayerAttribute, int> _randomBaseAttributes(Random rng) {
    final points = <PlayerAttribute, int>{
      for (final attr in PlayerAttribute.values) attr: minAttribute,
    };
    var remaining =
        creationPoints - PlayerAttribute.values.length * minAttribute;
    while (remaining > 0) {
      final attr =
          PlayerAttribute.values[rng.nextInt(PlayerAttribute.values.length)];
      if (points[attr]! < maxBaseAttribute) {
        points[attr] = points[attr]! + 1;
        --remaining;
      }
    }
    return points;
  }

  static Map<PlayerAttribute, int> _defaultBaseAttributes() =>
      {for (final attr in PlayerAttribute.values) attr: defaultAttributePoint};

  @override
  String toString() =>
      'ObjectPlayer(id: $id, name: $name, position: ${position.name}, '
      '${race.name}, Marktwert: $marketValue, Preis: $price, Ruhm: $fame)';
}
