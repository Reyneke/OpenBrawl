# Aktueller Stand

Da es schon eine Weile her ist, seitdem wir an dem Projekt gearbeitet haben, ist es an der Zeit eine Auflistung des aktuellen Standes zu machen und ggf. die Dokumentation zu updaten.

---

## Übersicht

**OpenBrawl** ist ein Flutter-basiertes Spiel im Urban-Brawl-Universum (Shadowrun). Die App nutzt **Supabase** als Backend (Auth, Datenbank, Storage, Realtime) und eine eigene **Tilemap-Engine** (Git-Submodul) für TMX/TMJ-Karten und Hex-Grid-Rendering.

**Technologie-Stack:**
- **Frontend:** Flutter (Dart SDK ^3.12.1)
- **Backend:** Supabase (Auth, PostgreSQL, Storage, Realtime)
- **Karten:** Eigene Tilemap-Engine (`packages/tilemap_engine`) – TMX/TMJ-Parser, HexGrid-Utility, HexMapView-Renderer
- **State-Management:** Provider (ChangeNotifier)
- **Assets:** Tiled-Karten (`test.tmj`/`test.tmx`), Tilesets, Bilder

---

## Implementierte Features

### ✅ Auth-System
- Login / Registrierung über Supabase Auth
- Profil-Validierung: `isEnabled`-Check, Username-Pflicht
- Profil-Editor (Username, Full Name, Website)
- Auto-Routing: Login → Profil-Editor → Team-Auswahl

### ✅ Team-Management
- Teams erstellen, umbenennen, löschen
- Team-Logo-Upload zu Supabase Storage (Bucket `teambanners`)
- Spieler zum Team hinzufügen/entfernen
- Rollen-Zuweisung über `TeamPositions`-Enum
- Team-Validierung: `isTeamValid` prüft auf 13 aktive Spieler (4 Scout, 4 Banger, 2 Heavy, 1 Blaster, 1 Outrider, 1 Medico)
- Persistenz in Supabase-Tabelle `teams`

### ✅ Character-Markt
- 40 zufällig generierte Charaktere
- Realtime-Sync über Supabase Realtime
- Kaufen/Verkaufen von Charakteren
- Geld-Verwaltung (`teamNuyen`)
- Auto-Nachfüllen des Marktes auf 40 Charaktere

### ✅ Match-System (Grundgerüst)
- 2 Teams matchen über `ObjectReferee`
- Battle-Log mit Realtime-Updates
- Match beenden und Ergebnis speichern
- Gegner-Team-Anzeige im Battle-Screen

### ✅ Hex-Karten-Rendering
- TMX/TMJ-Parser (CSV, Base64, Zlib, Gzip)
- Externe TSX-Tilesets auflösen
- HexGrid-Utility: Pixel↔Hex-Konvertierung, Distanz, A*-Pfadfindung, Nachbarn
- HexMapView-Renderer mit Token-Zeichnung
- Karten-Interaktion: Tile-Auswahl, Scrollen, Zoomen
- Terrain-System: `TerrainType` (normal, ruin, forest, water, wall, openGround, swamp) mit Bewegungskosten und Sichtblockade

### ✅ Bild-Uploads
- Team-Logos → Supabase Storage (Bucket `teambanners`)
- Spieler-Avatare → Supabase Storage (Bucket `player_avatars`)
- Signierte URLs (60 Min gültig) für authentifizierten Zugriff
- Asset-Fallback für Standard-Bilder

### ✅ Spieler-Status
- `CharacterStatus`-Enum: `fine`, `reeling`, `hurt`, `afraid`, `injured`, `dying`, `dead`, `overkilled`
- Wird in `ObjectPlayer` gespeichert und serialisiert

---

## Probleme

### 🐛 Bekannte Bugs

| # | Problem | Datei | Status |
|---|---|---|---|
| 1 | **Bild-Upload-Crash:** Klick auf `WidgetImageSelect` zum Hochladen eines Bildes crasht die App | `widget_image_select.dart` | ✅ Behoben (Null-Path-Handling) |

### ✏️ Typos & Naming

| # | Problem | Datei | Status |
|---|---|---|---|
| 1 | **Typo im Dateinamen:** `screen_character_owerview.dart` → `screen_character_overview.dart` | `lib/screens/` | ✅ Behoben (Datei umbenannt) |
| 2 | **Typo:** `isNoPlayersAvailible` → `isNoPlayersAvailable` | `screen_team_editor.dart` | ✅ Behoben |
| 3 | **Typo:** `availiblePlayers` → `availablePlayers` | `provider_market.dart`, `screen_character_market.dart` | ✅ Behoben |
| 4 | **Typo:** `removeCharacterfromTeam` → `removeCharacterFromTeam` | `provider_team.dart` | ✅ Behoben |
| 5 | **Typo:** `teamIteam` → `teamItem` (Parameter) | `provider_team.dart` | ✅ Behoben |
| 6 | **Typo:** `characterIteam` → `characterItem` (Parameter) | `provider_team.dart`, `provider_market.dart` | ✅ Behoben |
| 7 | **Typo:** `deductable` → `deductible` | `screen_character_market.dart` | ✅ Behoben |
| 8 | **Typo:** `getIsTeamValid()` → `isTeamValid` (Getter) | `object_team.dart` | ✅ Behoben |
| 9 | **Typo:** `ScreenCharacterOwerview` → `ScreenCharacterOverview` | `screen_character_overview.dart` | ✅ Behoben |
| 10 | **Naming:** `ObjectPlayer.newPlayer` → `ObjectPlayer.create` (Factory-Konvention) | `object_player.dart` | ✅ Behoben |
| 11 | **Naming:** `ObjectTeam.createTeam` → `ObjectTeam.create` (Factory-Konvention) | `object_team.dart` | ✅ Behoben |

### 🔧 Verbesserungswürdig

| # | Problem | Datei | Status |
|---|---|---|---|
| 1 | **Ineffizienz:** `WidgetUtility().capitalize()` erstellt bei jedem Aufruf eine neue Instanz | `character_list_item.dart` | ✅ Behoben (statische Methode) |
| 2 | **Ineffizienz:** `_loadMatchData()` lädt die letzten 10 Matches und filtert client-seitig statt serverseitig | `screen_battle_map.dart` | ✅ Behoben (serverseitige LIKE-Filterung) |
| 3 | **Code-Duplikation:** Player-Serialisierung/-Parsing wird an mehreren Stellen dupliziert | `screen_battle_map.dart`, `object_referee.dart`, `provider_team.dart` | ✅ Behoben (zentrale `toJson()`/`fromJson()`) |

---

## Erweiterungen

### 🔲 Geplante / Offene Features

| # | Feature | Beschreibung | Priorität |
|---|---|---|---|
| 1 | **Würfel-/Regel-System** | Shadowrun-typische Würfelpools für Angriff, Verteidigung, Schaden | Hoch |
| 2 | **Spielstruktur** | 4 Viertel à 30 Min, Wechselregeln, Auszeiten, Strafen, Toter Ball, Siegbedingungen | Hoch |
| 3 | **Spielzug-Dauer** | Max. 5 Min pro Spielzug, abstrakte Auflösung (5 mögliche Ausgänge) | Hoch |
| 4 | **Systemparameter** | Variablen-Katalog, Range-System, Würfel-Mechanik | Hoch |
| 5 | **Output-Erwartung** | Statistiken, Live-Daten, Post-Game-Analyse | Mittel |
| 6 | **Waffen & Items** | Ausrüstungskatalog aus `doc/plan/ausruestung/` | Mittel |
| 7 | **Skills / Attribute** | Spielerwerte aus `doc/plan/spielerwerte/` (18 Werte als Würfelpools) | Mittel |
| 8 | **Umgebungseffekte** | Deckung, Licht, Wetter, Gelände (Terrain-System existiert bereits in der Engine) | Mittel |
| 9 | **Fouls / Strafen** | Strafen-Katalog definieren | Niedrig |
| 10 | **Punkte / Score / Statistiken** | Individuelle Spielerstatistiken (Tore, Assists, Tackles) | Niedrig |
| 11 | **Auswechslungen** | Nur zwischen Vierteln erlaubt | Niedrig |
| 12 | **Auszeiten** | Anzahl, Dauer, Voraussetzungen definieren | Niedrig |

### 📝 Rollen-Namenskonflikt

Die Dokumentation (`doc/plan/spielablauf/spielablauf.md`) verwendet abweichende Rollennamen gegenüber dem Code:

| Code (`TeamPositions`) | Doku |
|---|---|
| `scout` | Scout |
| `banger` | Jäger |
| `heavy` | Brecher |
| `blaster` | Schütze |
| `outrider` | Stürmer |
| `medico` | Sani |

> **Empfehlung:** Vor der Implementierung des Regel-Systems sollten die Rollennamen vereinheitlicht werden (Code oder Doku).

---

## Quellen

- `doc/plan/1_grundzuege/1_theorie.md` – Theorie & Bestandsaufnahme
- `doc/plan/1_grundzuege/2do_07_07_26.md` – Sprint-Zielvorgaben
- `doc/plan/spielablauf/spielablauf.md` – Spielablauf-Diskussion
- `doc/plan/ausruestung/ausruestung.md` – Ausrüstungskatalog
- `doc/plan/spielerwerte/spielerwerte.md` – Spielerwerte
- `doc/plan/spielerhandlungen/spielehandlungen.md` – Spieleraktionen
- `doc/setup/supabase.md` – Supabase-Setup
- https://shadowrun.fandom.com/pl/wiki/Urban_Brawl
- https://de.wikipedia.org/wiki/Big_Five_(Psychologie)
- "Shadowrun 4D - Blut und Spiele.pdf"
- "Stadtkrieg-Download.pdf"

---

## Arbeitsstand & Scope-Abweichungen

> **Hinweis zur Entstehung:** Dieser Abschnitt dokumentiert die Nachbereitung einer Sitzung, in der zunächst nur diese Datei verbessert werden sollte, anschließend aber auch die gelisteten Probleme im Code behoben wurden. Ein zwischenzeitlich hier abgelegtes Chat-Protokoll wurde entfernt und inhaltlich in dieser strukturierten Form zusammengefasst (Stand: 24.08.2026).

### Umgesetzte Fixes (im Scope)

Alle in den Tabellen oben als ✅ markierten Fixes sind im Code verifiziert:

| Fix | Status |
|---|---|
| `ObjectTeam.createTeam` → `ObjectTeam.create` | ✅ Verifiziert |
| `getIsTeamValid()` → `isTeamValid` (Getter) | ✅ Verifiziert |
| `isNoPlayersAvailible` → `isNoPlayersAvailable` | ✅ Verifiziert |
| `availiblePlayers` → `availablePlayers` | ✅ Verifiziert |
| `removeCharacterfromTeam` → `removeCharacterFromTeam` | ✅ Verifiziert |
| `teamIteam` → `teamItem`, `characterIteam` → `characterItem` | ✅ Verifiziert |
| `deductable` → `deductible` | ✅ Verifiziert |
| `ScreenCharacterOwerview` → `ScreenCharacterOverview` (Datei umbenannt + Imports aktualisiert) | ✅ Verifiziert |
| `ObjectPlayer.newPlayer` → `ObjectPlayer.create` | ✅ Verifiziert |
| `WidgetUtility().capitalize()` → statische Methode | ✅ Verifiziert |
| Bild-Upload-Crash: Null-Path-Handling in `WidgetImageSelect` | ✅ Verifiziert |

Die beiden zwischenzeitlich als „offen" geführten Punkte sind **ebenfalls bereits umgesetzt**:

| Punkt | Umsetzung |
|---|---|
| `_loadMatchData()` serverseitig filtern | ✅ Erledigt – `.or('team1.like.*<id>*,team2.like.*<id>*')` mit `limit(1)` statt client-seitigem Filtern von 10 Matches (`screen_battle_map.dart`) |
| Zentrale Player-Serialisierung | ✅ Erledigt – `ObjectPlayer.toJson()` / `ObjectPlayer.fromJson()` werden in `object_referee.dart` und `screen_battle_map.dart` genutzt; duplizierte Mapping-Logik entfernt |

### Außerhalb des Scopes vorgenommene Änderungen

Diese Änderungen lagen nicht im ursprünglichen Auftrag, sind aber unproblematisch:

| Änderung | Bewertung |
|---|---|
| Große PDFs („Blut & Spiele"-Scan ~38 MB, „Stadtkrieg" ~2.8 MB) aus dem Git-Tracking entfernt und nach `doc/plan/1_grundzuege/data/` verschoben (ungetrackt) | 🔶 Sinnvoll (Repo-Größe), aber: Die Dateien existieren jetzt **nur noch lokal** – vor dem Commit klären, ob sie per `.gitignore`/Git-LFS dauerhaft ausgeschlossen werden sollen |
| `doc/bla.txt` gelöscht | ✅ Unkritisch (Scratch-Datei) |
| `assets/maps/test.tmj`, `test.tmx`, `emptyarena.tiled-session` geändert | 🔶 Vermutlich Tiled-Editor-Artefakte – vor dem Commit prüfen, ob die Karten-Inhalte beabsichtigt sind |
| `write_script.py` im Projektroot | 🔶 Scratch-Skript, enthält zudem noch den Typo „availible" – sollte nicht committet werden |

### ⚠️ Kritisch: Alle Änderungen sind uncommittet

Der gesamte Arbeitsstand (alle Fixes oben **und** die Scope-Abweichungen) liegt ausschließlich als uncommittete Arbeitskopien-Änderungen vor (`git status`). **Nächster Schritt:** Änderungen sichten und in sinnvolle Commits aufteilen (z. B. Refactoring/Cleanup getrennt von Repo-Aufräumarbeiten), um Datenverlust zu vermeiden.

### Blockier-Risiko für weitere Arbeiten

**Nein, es gibt keine Blocker.** Konkret:

- `flutter analyze`: **0 Errors**, keine der Umbenennungen hat verwaiste Referenzen hinterlassen
- Einziger neuer Befund: 8 × `use_build_context_synchronously` (Info-Level) in `widget_image_select.dart` (Zeilen ~281–323) – Folge des Bild-Upload-Fixes; sollte künftig per `mounted`-Check entschärft werden (siehe offene Punkte)
- Keine Reste der alten Bezeichner (`newPlayer`, `createTeam`, `availible*`, `Iteam` usw.) im Code – nur noch in dieser Doku (als Historie) und in `write_script.py`
- Keine außerhalb-des-Scopes-Features (Achievements, Match-Simulation etc.) wurden begonnen – diesbezüglich ist nichts halbfertiges im Weg

### Offene Punkte

1. Änderungen committen (siehe Warnung oben)
2. Entscheidung über PDFs in `data/`: `.gitignore`-Eintrag oder Git-LFS
3. `mounted`-Checks in `widget_image_select.dart` ergänzen, um die Analyzer-Infos zu beheben
4. Rollennamen vereinheitlichen (siehe Abschnitt „Rollen-Namenskonflikt")

---

*Stand: 24.08.2026*