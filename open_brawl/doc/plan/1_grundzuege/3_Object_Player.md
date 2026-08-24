# Object Player

Dieses Dokument beschreibt das Modell in `lib/objects/object_player.dart` und die am 24.08.2026 umgesetzten Erweiterungen (Attribute, Rassen, Karriere-Tracker, Persönlichkeit, Namensgenerator).

---

## Aktueller Stand

1. **`TeamPositions`** – 6 Rollen + `inactive`, mit `displayName` (deutsch, mit Umlauten) für die UI und Legacy-Mapping (`banger`, `heavy`, `blaster`, `outrider`, `medico`) für alte Supabase-Daten.
2. **`CharacterStatus`** – 8-stufiges Verletzungssystem (`fine` → `overkilled`); Getter `isAlive` / `isFitToPlay`.
3. **`PlayerAttribute`** – die sieben direkt beeinflussbaren Attribute: `attack`, `agility`, `defense`, `resistance`, `attention`, `morale`, `edge` (mit deutschem `displayName`).
4. **`PlayerRace`** – Rassen Mensch, Elf, Ork, Troll, Zwerg mit Modifikatoren-Map.
5. **`EnneagramPersonality`** – neun Typen der Enneagramm-Persönlichkeit, deutscher `displayName`.
6. **`PlayerMatchRecord`** – Karriere-Tracker `won` / `lost` / `drawn` mit `recordWin()`, `recordLoss()`, `recordDraw()` sowie `gamesPlayed` und `score`.
7. **`ObjectPlayer`** – bekannte Felder (`id`, `name`, `image`, `position`, `status`) plus `race`, `personality`, `baseAttributes`, `matchRecord`, `specialPlayFame`; berechnete Werte `marketValue`, `price`, `fame`.

Konkrete Spielerwerte (Würfelpools, Panzerung, Initiative etc.) sind weiterhin geplant – siehe `doc/plan/spielerwerte/spielerwerte.md`.

---

## Verbesserungen (24.08.2026)

| # | Problem | Lösung |
|---|---------|--------|
| 1 | Instabile IDs (`digest.hashCode`, `String.hashCode`) | Neuer Utility `lib/utils/id_utils.dart`: `stableIdFromString()` (deterministisch) + `uniqueId()` (praktisch eindeutig). `ObjectTeam.create`, `ObjectPlayer.create` und `ProviderTeam` umgestellt. |
| 2 | Magische Zahl `3000` doppelt | Konstanten `defaultPrice`, `defaultAttributePoint`, `pricePerMarketValuePoint` |
| 3 | Doppelte Parse-Logik | gemeinsamer Helfer `_enumFromName<T>()` |
| 4 | Sprödes JSON-Parsing | tolerante Casts über `num` |
| 5 | Fehlende Dokumentation / Debug | Dart-Doc auf allen Bausteinen, `toString()` überschrieben |

Kompatibilität: bestehende Aufrufstellen bleiben funktionsfähig; JSON-Schema wurde additiv
erweitert (`attributes`, `race`, `personality`, `record`, `specialPlayFame`).

---

## Erweiterungen im Detail

### 1. Weltweiter Namensgenerator
`ProviderMarket` erzeugte Spieler bisher mit `RandomNames(Zone.germany).name()` (nur deutsche Vornamen). Neu: `RandomNames().fullName()` – pro Erzeugung wird eine zufällige Zone aus **allen 29 Regionen** gewählt und **Vor- + Nachname** generiert. Die ganze Bandbreite des Pakets ist damit abgedeckt.

### 2. Match-Tracker
`PlayerMatchRecord` zählt die Spiele, an denen der Spieler beteiligt war:
- `won`, `lost`, `drawn` (mit Zählmethoden)
- `gamesPlayed` (= won + lost + drawn)
- `score` (= won − lost) als Basis des Ruhms

### 3. Enneagramm-Persönlichkeit
`EnneagramPersonality` (Typen 1–9) wird bei `create()` zufällig gewählt und serialisiert.

### 4. Attribute
- `PlayerAttribute` – sieben direkt beeinflussbare Werte (siehe oben).
- _Erschaffung_: `create()` verteilt **26 Punkte** zufällig auf die sieben Attribute.
  - Minimum je Basisattribut: **1**
  - Maximum ohne Modifikatoren: **6**; Endwert mit Cyber/Bioware gekappt auf **9**
- Rassenmodifikatoren (Feld `race`):
  **Hinweis:** Rassenmodifikatoren verschieben das **Maximum** des Attributs
  um den Modifikator – nicht nur den aktuellen Wert. Beispiele ohne
  Cyber/Bioware: Elf-Agilität (Mod +2) → Maximum `6 + 2 = 8`; Troll-Widerstand
  (Mod +2) → Maximum 8; Troll-Aufmerksamkeit (Mod −1) → Maximum `6 − 1 = 5`.
  Das absolute Maximum (v. a. mit Cyber/Bioware) bleibt **9**, das absolute
  Minimum **1**.

| Rasse | Modifikatoren |
|-------|---------------|
| Mensch | +1 Moral, +1 Edge |
| Elf | +2 Agilität, −1 Widerstand, +1 Moral |
| Ork | +1 Angriff, +1 Widerstand |
| Troll | +1 Angriff, +1 Verteidigung, +2 Widerstand, −1 Aufmerksamkeit, −1 Moral |
| Zwerg | −1 Agilität, +1 Verteidigung, +1 Widerstand |

### 5. Marktwert, Preis und Ruhm
- **Marktwert** = Durchschnitt aller sieben Attributendwerte.
- **Preis** = `Marktwert × 1000` – beeinflusst direkt den Markt-Kauf/-Verkauf. (So ergibt das Default-Attribut 3 → Marktwert 3 → Preis 3000, identisch zum bisherigen Standard.)
- **Ruhm** (`fame`) = (`matchRecord.won − matchRecord.lost`) + `specialPlayFame`
  – startet bei 0 und wächst über die Karriere.

### 6. UI-Anbindung (ScreenCharacterOverview)
Der Spieler-Überblick (`ScreenCharacterOverview`) zeigt jetzt alle modellierten Werte:

- **Header:** Spielerbild (`WidgetImageSelect`), Name sowie Chips für **Rasse**, **Persönlichkeit** und **Status** (`CharacterStatus.displayName`, deutsch).
- **Werte-Karte:** `Marktwert`, `Preis`, `Ruhm` sowie **Dropdowns** für Rasse und Persönlichkeit.
- **Attribute-Karte:** alle sieben Attribute mit `Basis · Rassenmod → Endwert`; Basiswerte lassen sich per `+`/`−` zwischen 1 und 6 anpassen.
- **Match-Tracker-Karte:** Siege/Niederlagen/Draws/Spiele als Zahlen samt `Score`.

Ist `currentTeam` gesetzt (Team-Spieler), werden Rassen-, Persönlichkeits- und Attributänderungen über `ProviderTeam.modifyCharacterInTeam` persistiert. Ohne Team (z. B. Markt-Spieler) ist die Ansicht read-only.

---

## Offene Punkte

| Punkt | Bemerkung |
|-------|-----------|
| **ID-Kollision bei Namensgleichheit (gelöst)** | Vorschlag umgesetzt: `ObjectPlayer.create` und `ObjectTeam.create` vergeben `IdUtils.uniqueId()` (Name + Zeitstempel + Zufall) – gleichnamige Spieler erhalten dadurch praktisch nie gleiche IDs. Deterministische IDs für Legacy-Workflows bleiben über `stableIdFromName()` erhältlich. |
| **UUID für absolute Eindeutigkeit** | Für viele Clients über alle Session hinweg: (A) `uuid`-Paket, (B) eigene Spieler-Tabelle in Supabase mit DB-generierter UUID, oder (C) `String`-UUID analog `ObjectTeam.dbId`. |
| **Wert-Gleichheit (`==`)** | Erst wieder aufnehmen, sobald IDs (z. B. via UUID) garantiert eindeutig sind – sonst entfernt `List.remove` möglicherweise den falschen Spieler. |
| **UI-Anbindung (erledigt)** | Rasse, Persönlichkeit, Match-Tracker und Attribute werden in `ScreenCharacterOverview` angezeigt (siehe Abschnitt 6). Basisattribute, Rasse und Persönlichkeit sind dort mit Team-Kontext editierbar. |