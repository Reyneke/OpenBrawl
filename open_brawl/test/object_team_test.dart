import 'package:flutter_test/flutter_test.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';

ObjectPlayer _player(int id, TeamPositions position) =>
    ObjectPlayer(id: id, name: 'P$id', position: position);

/// Baut einen gültigen 13er-Kader laut [ObjectTeam.requiredRoster].
List<ObjectPlayer> _validRoster() {
  final players = <ObjectPlayer>[];
  var id = 1;
  for (final entry in ObjectTeam.requiredRoster.entries) {
    for (var i = 0; i < entry.value; i++) {
      players.add(_player(id++, entry.key));
    }
  }
  return players;
}

ObjectTeam _filledTeam() {
  final team = ObjectTeam.create('Testteam', '');
  for (final player in _validRoster()) {
    team.addPlayer(player);
  }
  return team;
}

void main() {
  group('Konstanten & Factory', () {
    test('create setzt Startwerte aus den Konstanten', () {
      final team = ObjectTeam.create('Neues Team', 'logo.png');
      expect(team.nuyen, ObjectTeam.defaultNuyen);
      expect(team.name, 'Neues Team');
      expect(team.logo, 'logo.png');
      expect(team.players, isEmpty);
      expect(team.timeCreated, isNotNull);
    });
  });

  group('isTeamValid', () {
    test('leeres Team ist ungültig', () {
      expect(ObjectTeam.create('T', '').isTeamValid, isFalse);
    });

    test('exakter Pflichtkader ist gültig', () {
      expect(_filledTeam().isTeamValid, isTrue);
    });

    test('fehlende Rolle macht das Team ungültig', () {
      final team = _filledTeam();
      final scout = team.players.firstWhere(
        (p) => p.position == TeamPositions.scout,
      );
      team.removePlayer(scout);
      expect(team.isTeamValid, isFalse);
    });

    test('zu viele Spieler einer Rolle macht das Team ungültig', () {
      final roster = _validRoster();
      roster.removeAt(0); // ein Scout weg
      roster.add(_player(100, TeamPositions.jaeger)); // dafür ein Jäger zu viel
      final team = ObjectTeam(id: 1, name: 'T', logo: '', nuyen: 0);
      roster.forEach(team.addPlayer);
      expect(team.isTeamValid, isFalse);
    });

    test('inactive-Ersatzspieler ändern die Gültigkeit nicht', () {
      final team = _filledTeam();
      for (var i = 0; i < 7; i++) {
        expect(
          team.addPlayer(_player(50 + i, TeamPositions.inactive)),
          isTrue,
        );
      }
      expect(team.players.length, ObjectTeam.maxRosterSize);
      expect(team.isTeamValid, isTrue);
    });
  });

  group('Kapselung', () {
    test('Kaderobergrenze wird durchgesetzt', () {
      final team = _filledTeam();
      while (team.players.length < ObjectTeam.maxRosterSize) {
        expect(
          team.addPlayer(
            _player(100 + team.players.length, TeamPositions.inactive),
          ),
          isTrue,
        );
      }
      expect(
        team.addPlayer(_player(999, TeamPositions.inactive)),
        isFalse,
        reason: 'der 21. Spieler darf nicht hinzugefügt werden',
      );
    });

    test('doppelte IDs werden abgelehnt', () {
      final team = ObjectTeam.create('T', '');
      expect(team.addPlayer(_player(7, TeamPositions.scout)), isTrue);
      expect(team.hasPlayer(_player(7, TeamPositions.inactive)), isTrue);
      expect(team.addPlayer(_player(7, TeamPositions.sani)), isFalse);
      expect(team.players.length, 1);
    });

    test('removePlayer entfernt per ID und liefert false bei Unbekannten', () {
      final team = _filledTeam();
      final countBefore = team.players.length;
      expect(team.removePlayer(_player(999, TeamPositions.inactive)), isFalse);
      expect(team.players.length, countBefore);
      expect(team.removePlayer(team.players.first), isTrue);
      expect(team.players.length, countBefore - 1);
    });

    test('updatePlayer ersetzt an gleicher Position', () {
      final team = _filledTeam();
      final first = team.players.first;
      final replacement =
          ObjectPlayer(id: first.id, name: 'Update', position: first.position);

      expect(team.updatePlayer(replacement), isTrue);
      expect(team.players.first.name, 'Update');
      expect(team.players.length, 13);
      expect(team.indexOfPlayer(replacement), 0);
    });
  });

  group('Serialisierung', () {
    test('toJson/fromJson-Roundtrip erhält alle Felder', () {
      final original = _filledTeam()
        ..dbId = '6f2c9a52-1111-2222-3333-444455556666';

      final restored = ObjectTeam.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.dbId, original.dbId);
      expect(restored.name, original.name);
      expect(restored.logo, original.logo);
      expect(restored.nuyen, original.nuyen);
      expect(restored.timeCreated.toIso8601String(),
          original.timeCreated.toIso8601String());
      expect(restored.players.length, original.players.length);
      expect(
        restored.players.map((p) => p.id),
        original.players.map((p) => p.id),
      );
      expect(restored.isTeamValid, isTrue);
    });

    test('Legacy-Match-JSON (alte Schlüssel) wird tolerant geparst', () {
      const legacyUuid = 'aaaa-bbbb-cccc-dddd';
      final legacy = {
        'id': legacyUuid, // enthielt früher die DB-UUID
        'team_id': 42,
        'team_name': 'Altes Team',
        'team_logo': 'altes_logo.png',
        'team_nuyen': 2500,
        'players': [
          ObjectPlayer(id: 1, name: 'Alt', position: TeamPositions.sani)
              .toJson(),
        ],
      };

      final team = ObjectTeam.fromJson(legacy);

      expect(team.dbId, legacyUuid);
      expect(team.id, 42);
      expect(team.name, 'Altes Team');
      expect(team.logo, 'altes_logo.png');
      expect(team.nuyen, 2500);
      expect(team.players.single.id, 1);
      expect(team.players.single.position, TeamPositions.sani);
    });
  });

  group('Team-Statistik', () {
    test('Qualität nach dem 3-1-0-Schema', () {
      final team = ObjectTeam.create('T', '');
      team.record.recordWin();
      team.record.recordWin();
      team.record.recordDraw();
      team.record.recordLoss();

      expect(team.record.won, 2);
      expect(team.record.drawn, 1);
      expect(team.record.lost, 1);
      expect(team.record.gamesPlayed, 4);
      expect(team.record.quality, 7); // 2×3 + 1
    });

    test('Record-Roundtrip und tolerantes Parsen', () {
      final record = TeamMatchRecord()..recordWin();
      expect(TeamMatchRecord.fromJson(record.toJson()).quality, 3);
      expect(TeamMatchRecord.fromJson(null).quality, 0);
    });

    test('Team-Roundtrip erhält Statistik und Kapitän', () {
      final original = _filledTeam();
      original.dbId = 'uuid-team';
      original.setCaptain(original.players.first);
      original.record.recordWin();
      original.record.recordDraw();

      final restored = ObjectTeam.fromJson(original.toJson());

      expect(restored.captainId, original.captainId);
      expect(restored.hasCaptain, isTrue);
      expect(restored.captain!.id, original.captainId);
      expect(restored.record.quality, 4); // 3 + 1
    });
  });

  group('Kapitän', () {
    test('setCaptain akzeptiert nur Kadermitglieder', () {
      final team = _filledTeam();
      expect(team.setCaptain(_player(999, TeamPositions.inactive)), isFalse);
      expect(team.hasCaptain, isFalse);

      final first = team.players.first;
      expect(team.setCaptain(first), isTrue);
      expect(team.captainId, first.id);
      expect(team.captain!.id, first.id);

      // Abmelden
      expect(team.setCaptain(null), isTrue);
      expect(team.hasCaptain, isFalse);
    });

    test('hasCaptain wird false, wenn der Kapitän den Kader verlässt', () {
      final team = _filledTeam();
      final first = team.players.first;
      team.setCaptain(first);
      expect(team.hasCaptain, isTrue);

      team.removePlayer(first);
      expect(team.hasCaptain, isFalse);
    });
  });

  group('Rollenwechsel-Vorbereitung', () {
    test('isRoleFree zählt Belegung gegen requiredRoster', () {
      final team = _filledTeam(); // Scout ×4 belegt (IDs 1–4)
      expect(team.isRoleFree(TeamPositions.scout), isFalse);
      expect(
        team.isRoleFree(TeamPositions.scout, exceptPlayerId: 1),
        isTrue,
        reason: 'ohne den wechselnden Spieler ist ein Scout-Slot frei',
      );

      team.removePlayer(_player(1, TeamPositions.scout));
      expect(team.isRoleFree(TeamPositions.scout), isTrue);
    });
  });

  group('Sekundärrolle & Rollenbonus (ObjectPlayer)', () {
    test('Sekundärrolle wird serialisiert und normalisiert', () {
      final player = ObjectPlayer(
        id: 5,
        name: 'S',
        position: TeamPositions.stuermer,
        secondaryPosition: TeamPositions.scout,
      );
      final restored = ObjectPlayer.fromJson(player.toJson());
      expect(restored.secondaryPosition, TeamPositions.scout);

      // Sekundär == Primär wird auf inactive normalisiert
      final invalid = ObjectPlayer(
        id: 6,
        name: 'X',
        position: TeamPositions.sani,
        secondaryPosition: TeamPositions.sani,
      );
      expect(invalid.secondaryPosition, TeamPositions.inactive);
    });

    test('Stürmer-Bonus wirkt nur solange aktiv und ist oben ungekappet', () {
      final striker = ObjectPlayer(
        id: 7,
        name: 'St',
        position: TeamPositions.stuermer,
        baseAttributes: {PlayerAttribute.agility: 6},
      );
      // value(): nur Basis + Rasse (Mensch ohne Agilitätsmod)
      expect(striker.value(PlayerAttribute.agility), 6);
      // aktiv als Stürmer: 6 + 2 = 8, Maximum ebenfalls 8
      expect(striker.effectiveValue(PlayerAttribute.agility), 8);

      // Elf (+2 Rasse) als Stürmer (+2 Rolle): 6 + 4 = 10 – ohne obere Kappung
      final boosted = ObjectPlayer(
        id: 8,
        name: 'C',
        position: TeamPositions.stuermer,
        race: PlayerRace.elf,
        baseAttributes: {PlayerAttribute.agility: 6},
      );
      expect(boosted.value(PlayerAttribute.agility), 8); // nur Rasse
      expect(boosted.effectiveValue(PlayerAttribute.agility), 10); // ungekappet
    });

    test('Sani-Bonus auf Widerstand; ohne aktive Rolle kein Bonus', () {
      final medic = ObjectPlayer(
        id: 9,
        name: 'M',
        position: TeamPositions.sani,
        baseAttributes: {PlayerAttribute.resistance: 5},
      );
      expect(medic.effectiveValue(PlayerAttribute.resistance), 7);
      expect(
        medic.effectiveValue(
          PlayerAttribute.resistance,
          activeRole: TeamPositions.inactive,
        ),
        5,
      );
    });

    test('Rollenprofil entspricht der Doku-Tabelle', () {
      expect(TeamPositions.sani.attackBonus, 0);
      expect(TeamPositions.schuetze.attackBonus, 3);
      expect(TeamPositions.brecher.equipmentOptions.length, 3);
      expect(TeamPositions.stuermer.armor, ArmorClass.medium);
      expect(TeamPositions.sani.armor, ArmorClass.heavy);
      expect(
        TeamPositions.stuermer.modifierFor(PlayerAttribute.agility),
        2,
      );
      expect(
        TeamPositions.sani.modifierFor(PlayerAttribute.resistance),
        2,
      );
      expect(TeamPositions.scout.modifierFor(PlayerAttribute.agility), 0);
    });
  });
}