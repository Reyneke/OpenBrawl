# Object Team

Dieses Dokument beschreibt das Modell in `lib/objects/object_team.dart`, den aktuellen Stand und die notwendigen Änderungen, die eingebaut werden müssen. Es ergänzt die Bestandsaufnahme aus `1_theorie.md` und `2_Aktueller_Stand.md` und folgt der Struktur von `3_Object_Player.md`.

---

## Aktueller Stand

Das Team-Modell `ObjectTeam` (`lib/objects/object_team.dart`) bildet den Kader eines Spielers ab und wird über `ProviderTeam` mit Supabase synchronisiert (Tabelle `teams`). Stand nach Umsetzung der beschlossenen Änderungen (24.08.2026):

1. **Felder** – `id` (int), `name`, `logo`, `nuyen` (Geld), `timeCreated` (final; beim Erzeugen `DateTime.now()`, beim Laden aus Supabase `created_at`), `dbId` (String? – UUID aus Supabase).
2. **Factory** – `ObjectTeam.create(name, logo)`; vergibt `id = IdUtils.uniqueId('team|$name')` und startet `nuyen` bei `defaultNuyen` (= 1000).
3. **Konstanten** – `requiredRoster` (`Map<TeamPositions, int>`: 4 Scout, 4 Jäger, 2 Brecher, 1 Schütze, 1 Stürmer, 1 Sani = 13 aktive Spieler), `maxRosterSize` (= 20), `defaultNuyen` (= 1000).
4. **Validierung** – `isTeamValid` leitet sich generisch aus `requiredRoster` ab; `inactive`-Spieler werden ignoriert; leere Liste → `false`.
5. **Kapselung** – `players` liefert eine unveränderliche Ansicht; Änderungen laufen über `addPlayer()` / `removePlayer()` / `updatePlayer()` (Obergrenze `maxRosterSize`, keine doppelten IDs).
6. **Serialisierung** – `toJson()` / `fromJson()` liegen im Modell; `fromJson` parst tolerant auch das ältere Match-JSON (`team_id`/`team_name`/…). `ProviderTeam` mappt nur noch zentral auf die DB-Spalten (`_teamRowPayload`) und berechnet `ready_for_battle` nach jeder Kaderänderung neu (`_syncReadyForBattle`).
7. **Tests** – `test/object_team_test.dart` deckt Validierung, Kapselung und Serialisierung (inkl. Legacy-JSON) ab.

---

## Beschlossene Änderungen (Stand 24.08.2026)

> **✅ Umgesetzt am 24.08.2026** – inklusive Unit-Tests in `test/object_team_test.dart` (`flutter test` grün, `flutter analyze` ohne neue Findings).

| # | Problem | Lösung |
|---|---------|--------|
| 1 | Redundanter `team`-Präfix in den Feldnamen | Kürzen: `teamId` → `id`, `teamName` → `name`, `teamLogo` → `logo`, `teamNuyen` → `nuyen`, `teamPlayers` → `players`. |
| 2 | Magische Zahlen in `isTeamValid` (`4,4,2,1,1,1`, `1000`, Obergrenze) | Konstanten: `defaultNuyen`, `maxRosterSize (= 20)` und `Map<TeamPositions, int> requiredRoster`. `isTeamValid` generisch aus der Map ableiten. |
| 3 | `teamPlayers` öffentlich mutierbar | Kapselung über `addPlayer()` / `removePlayer()` / `updatePlayer()` / `hasPlayer()`; Kaderober-/Untergrenze und Doppelte im Modell prüfen. |
| 4 | Keine Serialisierung im Modell | `ObjectTeam.toJson()` / `fromJson()` analog `ObjectPlayer` eingeführt; duplizierte Mappings in `ObjectReferee._teamToJson` und `ScreenBattleMap._jsonToTeam` entfernt; `ProviderTeam` nutzt `_teamRowPayload` als einzige DB-Mapping-Stelle. |
| 5 | Änderungen am Kader aktualisieren den DB-Status nicht | `ready_for_battle` wird nach jeder Kaderänderung neu berechnet/persistiert (`_syncReadyForBattle` in `addCharacterToTeam`, `modifyCharacterInTeam`, `removeCharacterFromTeam`). |
| 6 | `timeCreated` ungenutzt | **Befüllen (beschlossen):** beim Erzeugen auf `DateTime.now()` gesetzt, beim Laden aus Supabase `created_at` übernommen. Feld bleibt erhalten. |
---

## Erweiterungen im Detail

### 1. Feldnamen vereinheitlichen
Wie bei `ObjectPlayer` gilt die Konvention „der Klassenname trägt den Kontext“. Da die Klasse bereits `ObjectTeam` heißt, sind `teamId`, `teamName`, `teamLogo`, `teamNuyen` und `teamPlayers` redundant. Der Umbau betrifft neben `object_team.dart` auch `ProviderTeam` und die Screens (`screen_team_editor.dart` u. a.).

### 2. Konstanten statt magischer Zahlen
`isTeamValid` codiert die Rollanforderungen derzeit hart (`4,4,2,1,1,1`):

```dart
static const Map<TeamPositions, int> requiredRoster = {
  TeamPositions.scout: 4,
  TeamPositions.jaeger: 4,
  TeamPositions.brecher: 2,
  TeamPositions.schuetze: 1,
  TeamPositions.stuermer: 1,
  TeamPositions.sani: 1,
};

static const int maxRosterSize = 20;
static const int defaultNuyen = 1000;
```

`isTeamValid` zählt dann über `teamPlayers` und vergleicht mit `requiredRoster` – erweiterbar ohne Code-Duplikat.

### 3. Kapselung des Kaders
Statt direkter `teamPlayers.add(...)` / `teamPlayers.removeAt(...)` in `ProviderTeam` soll `ObjectTeam` selbst über `addPlayer` / `removePlayer` verfügen. Dabei prüft das Modell u. a.:
- Obergrenze `maxRosterSize` (20) und die erforderliche Feldgröße,
- doppelte IDs,
- Spieler-Status (`isAlive` / `isFitToPlay`) gegen die Feldnutzung.

```dart
bool addPlayer(ObjectPlayer player) {
  if (_players.length >= maxRosterSize) return false;
  if (_players.any((p) => p.id == player.id)) return false;
  _players.add(player);
  return true;
}
```

### 4. Serialisierung ins Modell
`ObjectPlayer` bringt bereits `toJson`/`fromJson` mit; `ObjectTeam` tut das nicht. Die Persistenz-Anbindung (`teamname` / `banner_url` / `stats`) lebt ausschließlich in `ProviderTeam`. Ein `toJson()`/`fromJson()` auf `ObjectTeam` reduziert das Mapping auf eine Stelle und macht Nutzer gegen Schema-Änderungen unempfindlicher.

### 5. IDs: `teamId` (int) vs. `dbId` (UUID)
- `dbId` ist die echte, von Supabase generierte UUID (Tabelle `teams.id`).
- Beim Laden wird `teamId = IdUtils.stableIdFromString(row['id'])` gesetzt; lokale Int-IDs sind damit nur ein volatiler Index und können kollidieren.

**Empfehlung:** `dbId` langfristig zur primären, stabilen ID machen (vgl. offener Punkt „UUID“ in `3_Object_Player.md`); lokale Int-`teamId` nur als flüchtiger Listen-Cursor benutzen.

### 6. Dokumente vereinheitlichen
Nach der Umbenennung in `2_Aktueller_Stand.md` stimmt `1_theorie.md` noch nicht überall – sie nennt teils die alten englischen Rollennamen („Banger“, „Heavy“, …). Diese Stellen auf die aktuellen `TeamPositions`-Namen (`scout`/`jaeger`/…) und auf den deutschen `displayName` angleichen.

---

## Offene Punkte

| Punkt | Bemerkung |
|-------|-----------|
| **Wie viele Spieler gleichzeitig auf dem Feld? (beantwortet)** | Maximal **13 Spieler pro Team** im Feld; die Ersatzspieler sitzen auf der Wartebank abseits des Schirms. Aktuell also maximal **26 Spieler** auf dem Feld. `isTeamValid` deckt die 13 je Team bereits ab (siehe `1_theorie.md`). |
| **UUID als Primär-ID** | Für viele Clients über alle Sessions: `dbId`/UUID als einzig verbindliche ID verwenden; lokale `int`-IDs nur als Fallback. |
| ~~Kaderobergrenze 20~~ ✅ Erledigt | `requiredRoster` + `maxRosterSize` werden im Modell durchgesetzt (`addPlayer()`). |
| ~~`ready_for_battle`-Synchronisation~~ ✅ Erledigt | `_syncReadyForBattle` berechnet/persistiert den Status nach jeder Kaderänderung neu. |
---

## Neue Erweiterungen (umgesetzt am 24.08.2026)

> Der ursprüngliche Freitext-Beschluss wurde in vier Features überführt – alle sind implementiert und getestet (`test/object_team_test.dart`).

### A. Team-Statistik & Gesamtqualität
Teams halten gewonnene, verlorene und unentschieden beendete Matches fest (`TeamMatchRecord` in `object_team.dart`). Die **Gesamtqualität** errechnet sich nach dem **3-1-0-Schema**: `quality = Siege × 3 + Unentschieden`.

- Persistenz in der Spalte `stats` (jsonb) → keine DB-Migration nötig.
- Eintragung nach Matchende: `ObjectReferee.endMatch` ruft `ProviderTeam.recordMatchResult(winner, loser)` auf.
- UI: Statistik-Zeile im Teambildschirm.

### B. Teamkapitän
Vor Matchbeginn muss genau **ein** Spieler zum Teamkapitän ernannt werden (Checkbox je Spieler im Teambildschirm).

- Modell: `captainId`, `setCaptain()`, Getter `captain` / `hasCaptain`; `hasCaptain` fällt automatisch auf `false`, wenn der Kapitän den Kader verlässt.
- Kapitänspflicht prüfen `ObjectReferee.setTeamReadyForBattle` **und** der „Enter Battle“-Button (`readyForBattle = isTeamValid && hasCaptain`). `isTeamValid` selbst bleibt die reine Kaderprüfung.
- Persistenz ebenfalls über `stats` (`captain_id`).

### C. Primär- und Sekundärrolle
Jeder Spieler hat eine Primärrolle (`position`) und eine Sekundärrolle (`secondaryPosition`, darf nicht identisch mit der Primärrolle sein – wird beim Setzen normalisiert).

- Beide Rollen werden im Teambildschirm gesetzt (zwei Dropdowns je Spieler).
- **„Ready for Battle“ zählt nur die Primärrolle** (`isTeamValid` unverändert).
- Wechsel im Spiel vor jedem Spielzug nur auf freie Rollen: Helfer `ObjectTeam.isRoleFree(role, {exceptPlayerId})` zählt die aktive Belegung gegen `requiredRoster`. Die Wechsel-UI im Match kommt mit der Match-Engine (API ist vorbereitet und getestet).

### D. Rollenprofil (Panzerung, Verteidigung, Ausrüstung, Angriff, Attributsbonus)
`TeamPositions` ist jetzt ein Enhanced Enum mit Profil pro Rolle:

| Rolle | Anzahl | Panzerung | Verteidigung | Ausrüstung | Angriff | Attributsbonus |
|---|---|---|---|---|---|---|
| Scout | 4 | leicht | 1 | persönliche Schusswaffe | 1 | – |
| Jäger | 4 | mittelschwer | 2 | persönliche Schusswaffe | 1 | – |
| Brecher | 2 | mittelschwer | 2 | Sturmgewehr / MP / Schrotflinte (wählen) | 2 | – |
| Schütze | 1 | leicht | 1 | leichtes MG mit Gyrostabilisator | 3 | – |
| Stürmer | 1 | mittelschwer | 2 | Motorrad mit Sturmgewehr / MP / Schrotflinte (wählen) | 2 | +2 Agilität |
| Sani | 1 | schwer | 3 | Medkit | 0 | +2 Widerstand |

- Zugriff über `role.armor` / `.defenseValue` / `.equipmentOptions` / `.attackBonus` / `.modifierFor(attr)`; `ArmorClass` modelliert die Panzerungsklasse.
- **Attributsboni wirken wie Rassenboni:** `ObjectPlayer.effectiveValue(attr, {activeRole})` erhöht den Attributswert – und ist, wie Rassenboni, **nur nach unten gekappt** (Minimum 1), nach oben ungekappet. Gilt nur solange die Rolle aktiv ist. Wirtschaftswerte (`marketValue`, `price`) nutzen weiterhin `value()` ohne Rollenbonus.

----

*Stand: 24.08.2026*
