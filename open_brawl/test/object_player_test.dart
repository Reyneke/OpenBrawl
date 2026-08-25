import 'package:flutter_test/flutter_test.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/utils/id_utils.dart';

void main() {
  group('IdUtils', () {
    test('stableIdFromString ist deterministisch', () {
      expect(
        IdUtils.stableIdFromString('Rex'),
        IdUtils.stableIdFromString('Rex'),
      );
      expect(
        IdUtils.stableIdFromString('Rex'),
        isNot(IdUtils.stableIdFromString('Rexx')),
      );
    });

    test('uniqueId erzeugt auch bei gleichem Seed unterschiedliche IDs', () {
      expect(
        IdUtils.uniqueId('Marktspieler'),
        isNot(IdUtils.uniqueId('Marktspieler')),
      );
    });
  });

  group('ObjectPlayer.create', () {
    test('verteilt exakt 26 Punkte auf sieben Attribute (je 1..6)', () {
      for (var i = 0; i < 20; i++) {
        final player = ObjectPlayer.create('Testspieler $i', 'pic.png');
        final sum = player.baseAttributes.values.fold(0, (a, b) => a + b);
        expect(sum, 26);
        for (final value in player.baseAttributes.values) {
          expect(value, inInclusiveRange(1, 6));
        }
      }
    });

    test('setzt Rasse, Enneagramm, Tracker und Ruhm auf Startwerte', () {
      final player = ObjectPlayer.create('Tester', 'pic.png');
      expect(PlayerRace.values, contains(player.race));
      expect(EnneagramPersonality.values, contains(player.personality));
      expect(player.matchRecord.gamesPlayed, 0);
      expect(player.specialPlayFame, 0);
      expect(player.fame, 0);
      expect(player.id, isA<int>());
    });
  });

  group('ObjectPlayer Attribute & Marktwert', () {
    test('Default-Attribute (je 3) ergeben Marktwert 3 (Preis 3000)', () {
      final player = ObjectPlayer(id: 1, name: 'Default');
      for (final attr in PlayerAttribute.values) {
        expect(player.baseAttributes[attr], 3);
      }
      expect(player.marketValue, 3);
      expect(player.price, 3000);
    });

    test('Rassenmodifikatoren wirken auf den Endwert (Minimum 1, kein Maximum)', () {
      // Elf: +2 Agilität, −1 Widerstand
      final elf = ObjectPlayer(
        id: 1,
        name: 'Elfe',
        race: PlayerRace.elf,
        baseAttributes: const {
          PlayerAttribute.agility: 5,
          PlayerAttribute.resistance: 1,
        },
      );
      expect(elf.agility, 7);
      expect(elf.resistance, 1); // 1−1 → min 1

      // Troll: +1 Angriff, −1 Moral
      final troll = ObjectPlayer(
        id: 2,
        name: 'Troll',
        race: PlayerRace.troll,
        baseAttributes: const {
          PlayerAttribute.attack: 6,
          PlayerAttribute.morale: 1,
        },
      );
      expect(troll.attack, 7); // 6+1
      expect(troll.morale, 1); // 1−1 → min 1
    });

    test('Attributendwerte: Boni sind nach oben ungekappet (Minimum 1)', () {
      final player = ObjectPlayer(
        id: 1,
        name: 'Max',
        race: PlayerRace.troll,
        baseAttributes: const {
          PlayerAttribute.attack: 6,
          PlayerAttribute.resistance: 6,
        },
      );
      expect(player.attack, 7);
      expect(player.resistance, 8);
      expect(player.baseAttributes[PlayerAttribute.attack], 6);
    });

    test('Rassenmodifikator verschiebt auch das Maximum des Attributs', () {
      // Elf: +2 Agilität → Maximum 6+2 = 8 statt 6
      final elf = ObjectPlayer(
        id: 1,
        name: 'Elf',
        race: PlayerRace.elf,
        baseAttributes: const {PlayerAttribute.agility: 6},
      );
      expect(elf.agility, 8);

      // Zwerg: −1 Agilität → Maximum 6−1 = 5 (Basis 6 ergibt 5)
      final dwarf = ObjectPlayer(
        id: 2,
        name: 'Zwerg',
        race: PlayerRace.zwerg,
        baseAttributes: const {PlayerAttribute.agility: 6},
      );
      expect(dwarf.agility, 5);

      // Troll: −1 Aufmerksamkeit → Maximum 6−1 = 5
      final troll = ObjectPlayer(
        id: 3,
        name: 'Troll',
        race: PlayerRace.troll,
        baseAttributes: const {PlayerAttribute.attention: 6},
      );
      expect(troll.attention, 5);

      // Mensch: +1 Moral → Maximum 7
      final human = ObjectPlayer(
        id: 4,
        name: 'Mensch',
        race: PlayerRace.mensch,
        baseAttributes: const {PlayerAttribute.morale: 6},
      );
      expect(human.morale, 7);
    });
  });

  group('Match-Tracker & Ruhm', () {
    test('recordWin/Loss/Draw zählt hoch', () {
      final record = PlayerMatchRecord()
        ..recordWin()
        ..recordWin()
        ..recordLoss()
        ..recordDraw();
      expect(record.won, 2);
      expect(record.lost, 1);
      expect(record.drawn, 1);
      expect(record.gamesPlayed, 4);
      expect(record.score, 1);
    });

    test('Ruhm = Differenz Siege-Niederlagen + besondere Spielzüge', () {
      final player = ObjectPlayer(
        id: 1,
        name: 'Star',
        matchRecord: PlayerMatchRecord()
          ..won = 5
          ..lost = 2,
        specialPlayFame: 3,
      );
      expect(player.fame, 6); // (5−2) + 3
    });
  });

  group('Serialisierung', () {
    test('toJson/fromJson-Round-Trip erhält alle Felder inkl. neuer', () {
      final original = ObjectPlayer(
        id: 42,
        name: 'Rex',
        image: 'rex.png',
        position: TeamPositions.sani,
        status: CharacterStatus.injured,
        race: PlayerRace.elf,
        personality: EnneagramPersonality.seven,
        baseAttributes: const {
          PlayerAttribute.attack: 4,
          PlayerAttribute.agility: 6,
          PlayerAttribute.defense: 3,
          PlayerAttribute.resistance: 2,
          PlayerAttribute.attention: 4,
          PlayerAttribute.morale: 3,
          PlayerAttribute.edge: 4, // Summe 26
        },
        matchRecord: PlayerMatchRecord()
          ..won = 3
          ..lost = 1,
        specialPlayFame: 2,
      );

      final restored = ObjectPlayer.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.image, original.image);
      expect(restored.position, original.position);
      expect(restored.status, original.status);
      expect(restored.race, original.race);
      expect(restored.personality, original.personality);
      expect(restored.baseAttributes, original.baseAttributes);
      expect(restored.matchRecord.won, original.matchRecord.won);
      expect(restored.matchRecord.lost, original.matchRecord.lost);
      expect(restored.specialPlayFame, original.specialPlayFame);
      expect(restored.marketValue, original.marketValue);
      expect(restored.price, original.price);
    });

    test('fromJson toleriert fehlende optionale Felder (Legacy)', () {
      final player = ObjectPlayer.fromJson({
        'id': 7.0, // Supabase liefert ggf. num statt int
        'name': 'Altspieler',
        'position': 'medico', // Legacy-Name
        'status': 'unbekannt',
      });

      expect(player.id, 7);
      expect(player.image, ObjectPlayer.defaultImage);
      expect(player.position, TeamPositions.sani);
      expect(player.status, CharacterStatus.fine);
      expect(player.race, PlayerRace.mensch);
      expect(player.personality, EnneagramPersonality.one);
      expect(player.baseAttributes[PlayerAttribute.attack], 3);
      expect(player.matchRecord.gamesPlayed, 0);
    });
  });

  group('copyWith', () {
    test('ändert nur angegebene Felder und entkoppelt die Attribut-Map', () {
      final original = ObjectPlayer(
        id: 1,
        name: 'Rex',
        baseAttributes: {for (final a in PlayerAttribute.values) a: 3},
      );
      final copy = original.copyWith(status: CharacterStatus.dying);

      expect(copy.status, CharacterStatus.dying);
      expect(copy.name, original.name);

      // Die Attribut-Map ist entkoppelt: Änderungen an der Kopie wirken nicht
      // auf das Original zurück.
      copy.setBaseAttribute(PlayerAttribute.attack, 6);
      expect(copy.baseAttributes[PlayerAttribute.attack], 6);
      expect(original.baseAttributes[PlayerAttribute.attack], 3);
    });
  });

  group('TeamPositions', () {
    test('fromName erkennt aktuelle und alte Namen', () {
      expect(TeamPositions.fromName('sani'), TeamPositions.sani);
      expect(TeamPositions.fromName('medico'), TeamPositions.sani); // Legacy
      expect(TeamPositions.fromName(null), TeamPositions.inactive);
      expect(TeamPositions.fromName('gibtsnicht'), TeamPositions.inactive);
    });

    test('displayName enthält Umlaute für die UI', () {
      expect(TeamPositions.jaeger.displayName, 'Jäger');
      expect(TeamPositions.schuetze.displayName, 'Schütze');
    });
  });

  group('CharacterStatus', () {
    test('isAlive folgt dem Schweregrad', () {
      expect(CharacterStatus.dying.isAlive, isTrue);
      expect(CharacterStatus.dead.isAlive, isFalse);
      expect(CharacterStatus.overkilled.isAlive, isFalse);
    });

    test('fromName mit Fallback auf fine', () {
      expect(CharacterStatus.fromName('injured'), CharacterStatus.injured);
      expect(CharacterStatus.fromName(null), CharacterStatus.fine);
      expect(CharacterStatus.fromName('quatsch'), CharacterStatus.fine);
    });
  });
}