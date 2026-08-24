# Object Team

Dieses Dokument beschreibt das Modell in `lib/objects/object_team.dart`, den aktuellen Stand und die notwendigen Änderungen, die eingebaut werden müssen. Es ergänzt die Bestandsaufnahme aus `1_theorie.md` und `2_Aktueller_Stand.md` und folgt der Struktur von `3_Object_Player.md`.

---

## Aktueller Stand

Das Team-Modell `ObjectTeam` (`lib/objects/object_team.dart`) bildet den Kader eines Spielers ab und wird über `ProviderTeam` mit Supabase synchronisiert (Tabelle `teams`).

1. **Felder** – `teamId` (int), `teamName`, `teamLogo`, `teamNuyen` (Geld), `teamPlayers` (Liste von `ObjectPlayer`), `timeCreated` (ungenutzt), `dbId` (String? – UUID aus Supabase).
2. **Factory** – `ObjectTeam.create(teamName, teamLogo)`; vergibt `teamId = IdUtils.uniqueId('team|$teamName')` und startet `teamNuyen` bei `1000`. (Konvention `create` statt früherem `createTeam` – bereits umgesetzt.)
3. **Validierung** – `isTeamValid` (Getter) verlangt exakt **13 aktive Spieler**: 4 Scout, 4 Jäger, 2 Brecher, 1 Schütze, 1 Stürmer, 1 Sani. `inactive`-Spieler werden ignoriert; leere Liste → `false`.
4. **Rollen** – `TeamPositions`-Enum (definiert in `object_player.dart`) mit `scout`, `jaeger`, `brecher`, `schuetze`, `stuermer`, `sani` und `inactive`; deutschem `displayName` sowie Legacy-Mapping (`banger`/`heavy`/`blaster`/`outrider`/`medico`).
5. **Persistenz** – `ObjectTeam` selbst besitzt **kein** `toJson`/`fromJson`. Die Serialisierung liegt dupliziert in `ProviderTeam` (`_serializePlayers`, `updateTeamInDatabase`, `addTeam`, `loadTeamsFromDatabase`).

---

## Beschlossene Änderungen (Stand 24.08.2026)

| # | Problem | Lösung |
|---|---------|--------|
| 1 | Redundanter `team`-Präfix in den Feldnamen | Kürzen: `teamId` → `id`, `teamName` → `name`, `teamLogo` → `logo`, `teamNuyen` → `nuyen`, `teamPlayers` → `players`. |
| 2 | Magische Zahlen in `isTeamValid` (`4,4,2,1,1,1`, `1000`, Obergrenze) | Konstanten: `defaultNuyen`, `maxRosterSize (= 20)` und `Map<TeamPositions, int> requiredRoster`. `isTeamValid` generisch aus der Map ableiten. |
| 3 | `teamPlayers` öffentlich mutierbar | Kapselung über `addPlayer()` / `removePlayer()` / `hasPlayer()`; Kaderober-/Untergrenze und Doppelten im Modell prüfen. |
| 4 | Keine Serialisierung im Modell | `ObjectTeam.toJson()` / `fromJson()` analog `ObjectPlayer` einführen; Mapping in `ProviderTeam` entfernen und zentral nutzen. |
| 5 | Änderungen am Kader aktualisieren den DB-Status nicht | `ready_for_battle` nach Kaderänderung neu berechnen/persistieren (aktuell nur in `addTeam`/`setTeamReadyForBattle`). |
| 6 | `timeCreated` ungenutzt | **Befüllen (beschlossen):** beim Erzeugen auf `DateTime.now()` setzen, beim Laden aus Supabase `created_at` übernehmen. Feld bleibt erhalten. |
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
| **Kaderobergrenze 20** | `requiredRoster` + `maxRosterSize` sollte das Modell durchsetzen, nicht nur die UI/Provider-Ebene. |
| **`ready_for_battle`-Synchronisation** | Nach jeder Kader-/Geldänderung persistieren, sonst zeigt die DB einen veralteten Status. |

---


Erweiterungen
- Ein Spieler muss vor Beginn des Matches zum Teamkapitän ernannt werden
- Jeder Spieler hat zwei, anstelle bsiher einer Rolle, welche er ausfüllen kann. Eine Primärrolle und eine Sekundäre Rolle. Beide werden im Teambildschirm vor Spielbeginn gewählt, können aber im Spiel vor jedem Spielzug gewechselt werden. Damit ein Team aktiv nach einem Spiel suchen kann, der Button also freigegeben wird, gilt dabei rein die Primäreposition.
- Die jeweils aktive Rolle eines Spielers bringt Ausrüstung und dergleichen mit sich. Hier eine Übersicht

Legende: Rolle: Anzahl, Panzerung, Verteidigung, Ausrüstung, Angriff, Bonus auf Attribut
Scout: 4, leicht, 1, persönliche Schusswaffe, 1, nichts
Jäger: 4, mittelschwer, 2, persönliche Schusswaffe, 1, nichts
Brecher: 2, mittelschwer, 2, Sturmgewehr Maschinenpistole oder Schrotflinte (auswählen), 2, nichts
Schütze: 1, leicht, 1, leichtes MG mit Gyrostabilisator, 3, nichts
Stürmer: 1, mittelschwer, 2, Motorrad mit Sturmgewehr Maschinenpistole oder Schrotflinte (auswählen), 2, +2 Agilität
Sani: 1, schwer, 3, Medkit, 0, +2 Widerstand

Hinweis: Attributsboni die durch die gewählte Rolle entstehen, erhöhen, wie Rassenboni, das niedergeschriebene Attribut / Attributsmaximum eines Spielers, aber nur solange sich der Spieler in dieser Rolle befindet.

----

*Stand: 24.08.2026*
