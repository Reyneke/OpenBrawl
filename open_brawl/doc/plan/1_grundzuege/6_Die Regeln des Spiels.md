# Regeln des Spiels

Hier sollen die ersten Regeln des Spiels festgehalten, welche innerhalb der Simulation zum Tragen kommen werden.

Dieses Dokument ist die **zentrale Referenz der Spielregeln** für das Match-System (`ObjectReferee`). Es bündelt die Regelfragmente aus den Roh-Quellen (`spielablauf/spielablauf.md`, `ausruestung/ausruestung.md`, `spielerhandlungen/spielehandlungen.md`, `spielerwerte/spielerwerte.md`) sowie den Sprintvorgaben (`2do_07_07_26.md`) in eine strukturierte, simulationsrelevante Form. Die Roh-Protokolle bleiben Primärquelle; hier wird der für die Umsetzung **verbindliche Stand** festgeschrieben. Details zu Modell und Werten finden sich in `3_Object_Player.md`, `4_Object_Team.md` und `5_Ausruestung.md`.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

---

## Spielfeld

### Kriegszone

- **Größe:** in der Regel **3 × 4 Häuserblocks** (231.000–346.800 m²)
- **Begrenzung:** oft in alle Richtungen durch eine offene Fläche (Straße, Parkanlage, Wasser)
- **Bekanntgabe:** erst **24 Stunden vor Spielbeginn**

### Sektoren

- Die Tilemap ist in **Sektoren** aufgeteilt.
- Die **Sektorennamen** sind für alle Parteien sichtbar **mittig im Sektor** dargestellt.

### Startsektoren

- Jedes Team zählt die Sektoren zu seinen **Startsektoren**, die – vom eigenen **Spawnpunkt** aus gesehen – die **kürzere Seite des Feldes** bilden.
- **Beispiel:** Bei einer auf **3 × 4 Sektoren** aufgeteilten Karte sind das die **drei vertikalen Sektoren**.

### Torzone (Zielzone)

- **Form:** Kreis mit **4 m Durchmesser** auf Straßenhöhe.
- **Platzierung:** Beide Teams platzieren ihre Torzone innerhalb ihrer **Startsektoren** (vgl. [Startsektoren](#startsektoren)); zwischen den Vierteln darf sie neu platziert werden.
- **Wahl/Zeitlimit:** Ist der **„Automatisch“-Haken** nicht gesetzt (vgl. [Manager-Entscheidung](#manager-entscheidung-aufstellung)), haben die Manager **15 Minuten** Zeit, die Torzone zu wählen. Trifft ein Manager keine Wahl oder ist „Automatisch“ aktiv, wird die Torzone **zufällig** platziert.

### Fog of War

- Jede Mannschaft hat nur in dem **Sektor volle Sicht**, in dem sich Spieler der eigenen Mannschaft befinden.
- 🔶 Die Sichtbarkeit der **Torzone** ist davon **unabhängig**: Zu Beginn ist jede Torzone nur für das **besitzende Team** sichtbar.
- 🔶 Erst wenn ein Spieler des anderen Teams die Torzone **wahrgenommen** hat (**Würfelwurf**, voraussichtlich über den Wahrnehmungspool → `PlayerAttribute.attention`), wird sie für dieses Team offenbar.

### Ball

- **Maße:** 65–70 cm Umfang, 500–600 g schwer
- **Material:** Leucht-Plastschaum (gelb/gold), mit **Sensoren** ausgestattet

## Spielstruktur

### Viertel & Spielzeit

- 1 Spiel = **4 Viertel à 30 Minuten** → 2 Stunden gesamt
- 1 Spielzug = **maximal 5 Minuten**
- Zeitliche Relation: 1 Spielzug = max. 5 Min. = max. **100 Kampfrunden**; 1 Viertel = 30 Min. = **600 Kampfrunden**; 1 Spiel = 2h = **2.400 Kampfrunden**
- Pausen: **5 Minuten** Reorganisation; zwischen den Vierteln **10 / 15 / 10 Minuten**

### Spielzug (abstrakte Auflösung)

Ein Spielzug kann **genau einen** der folgenden Ausgänge haben:

| # | Ausgang |
|---|---------|
| 1 | Mannschaft A punktet |
| 2 | Mannschaft B punktet |
| 3 | Mannschaft A erleidet einen Wipeout |
| 4 | Mannschaft B erleidet einen Wipeout |
| 5 | Zeitlimit (5 Min.) läuft ab |

Ein Spielzug endet, wenn ein Team punktet, die Spielzuguhr (oder das Viertel) abläuft, der Ball für „tot“ erklärt wird (gilt nur für eine Seite – das andere Team darf weitermachen) oder alle Offensivspieler eines Teams „ausgelöscht“ sind (Wipeout).

> **Hinweis:** Bei 2.400 Kampfrunden pro Spiel würde die Detail-Simulation („jeder Schuss jedes Spielers“) die Spielzeit explodieren lassen (vgl. Diskussion in `spielablauf.md`). Deshalb ist die **abstrakte Auflösung** pro Spielzug beschlossen: Die Züge werden über Würfe aufgelöst (siehe [Wertung](#wertung--siegbedingungen)) statt über Einzelaktionen.

### Manager-Entscheidung (Aufstellung)

- Vor dem Spiel / pro Viertel entscheidet der **Manager**, wie viele und welche Spieler **scouten**, **offensiv** oder **defensiv** eingesetzt werden.
- **Scouten** verstärkt die Fähigkeit, die gegnerische Torzone zu finden; ein offensiver bzw. defensiver Einsatz verstärkt die **Offensiv- bzw. Defensivkraft** des Teams. Die Aufstellung fließt in die Würfe ein.

> **Automatik-Option („Automatisch“):** Der Geschwindigkeit halber kann der Manager bereits bei der **Spielsuche** per Checkbox die Option **„Automatisch“** aktivieren. Das Setup vor Spielbeginn bzw. die Aufstellung zwischen den Vierteln erfolgt dann automatisch – die Spieler werden nach ihren **Positionen und Werten** auf die drei Einsatzarten (scouten/offensiv/defensiv) verteilt.
>
> **Zeitlimit:** Ist die Checkbox **nicht** gesetzt, hat der Manager eine **RL-Viertelstunde** (15 Minuten Echtzeit) Zeit, die Aufstellung manuell zu treffen. Läuft das Zeitlimit ab, greift derselbe Automatismus.

> **Status:** ❌ beschlossen, im Code noch nicht umgesetzt – weder Aufstellungs-UI noch Automatik/Zeitlimit existieren bisher.

## Wertung & Siegbedingungen

### Wertung

- **Punkt:** wenn der Ball **innerhalb der gegnerischen Torzone den Boden berührt**.
- Nach einem Punkt **resetten beide Teams in ihre eigene Torzone**; ein neuer Spielzug beginnt.
- Das Spielergebnis (inkl. Verletzungen) wird „per Zufall“ ermittelt: **Verletzungswurf** + **Punktwurf**, beide beeinflusst durch die **Aufstellung** (scouten/offensiv/defensiv) und die **Spielerwerte**.

### Siegbedingungen

1. **Meiste Punkte:** Gewonnen hat die Mannschaft mit den **meisten Punkten** (Toren). Bei **Gleichstand** entscheidet, welches Team noch die **meisten spielfähigen Spieler** hat.
2. **Spielfähigkeit:** Gilt eine Mannschaft als **nicht mehr spielfähig** – kein Spieler mehr, der den **Ball führen darf** (Sani und Stürmer dürfen den Ball nicht führen, vgl. [Aktionen](#aktionen--kampfmanöver)) – oder erleidet sie einen **Wipeout**, gewinnt das andere Team.
3. **Schiedsrichter-Abbruch:** Die Schiedsrichter können das Spiel – etwa bei einem bemerkten **Übergriff von außen** – zugunsten einer Mannschaft **abbrechen**. Führt ein schwerer Regelverstoß (**Zerstörung/Brandstiftung**) zum Spielabbruch, bedeutet das die **automatische Niederlage** des verantwortlichen Teams (vgl. [Strafen & Verstöße](#strafen--verstöße)).
4. **Beidseitiger Wipeout:** Erleiden **beide Teams** im Verlauf des Matches einen Wipeout, endet das Spiel **unentschieden** (weder Sieger noch Verlierer).

> **Status:** 🔶 Regeln beschlossen, im Code noch nicht umgesetzt – `ObjectReferee.endMatch` speichert bisher nur Winner/Loser, ohne die Bedingungen zu prüfen. Ein Unentschieden lässt sich im Modell zwar bereits abbilden (`TeamMatchRecord.drawn`), wird von `endMatch` aber noch nicht unterstützt.

## Kader & Rollen

### Kader-Größe

| Regel | Wert | Status |
|-------|------|--------|
| Kadergröße (Feldspieler + Ersatz) | **20 Spieler** | ✅ `ObjectTeam.maxRosterSize` |
| Aktive Feldspieler je Team | **13 Spieler** | ✅ `ObjectTeam.requiredRoster` |
| Spieler auf dem Feld (beide Teams) | bis zu **26 Spieler** | 🔶 Regel geklärt, Feld-Slot-Mechanismus fehlt |
| Ersatzspieler | bis zu 7 (`inactive`) | ✅ wird in `isTeamValid` ignoriert |

### Rollenprofil

Verteilungsschlüssel und Profil je Rolle (im Code als `TeamPositions`; umgesetzt am 24.08.2026):

| Rolle | Anzahl | Panzerung | Verteidigung | Ausrüstung | Angriff | Attributsbonus |
|-------|--------|-----------|--------------|------------|---------|----------------|
| Scout | 4 | leicht | 1 | persönliche Schusswaffe | 1 | – |
| Jäger | 4 | mittelschwer | 2 | persönliche Schusswaffe | 1 | – |
| Brecher | 2 | mittelschwer | 2 | Sturmgewehr / MP / Schrotflinte (wählen) | 2 | – |
| Schütze | 1 | leicht | 1 | leichtes MG mit Gyrostabilisator | 3 | – |
| Stürmer | 1 | mittelschwer | 2 | Motorrad mit Sturmgewehr / MP / Schrotflinte (wählen) | 2 | +2 Agilität |
| Sani | 1 | schwer | 3 | Medkit | 0 | +2 Widerstand |

> **Hinweis:** Die Rollennamen folgen der Doku (`spielablauf.md`). Alte Code-Bezeichner (`banger`, `heavy`, `blaster`, `outrider`, `medico`) werden beim Laden via Legacy-Mapping unterstützt.

### Sonderregeln

- **Sani:** darf weder angreifen **noch angegriffen** werden.
  - ✅ Angriffsverbot über `attackBonus = 0` abgebildet.
  - ❌ „Darf nicht angegriffen werden“ (Schutz vor Zielwahl) noch nicht modelliert – ein Angriff auf den Sani ist ein Regelverstoß mit Strafe **Abschuss** (vgl. [Strafen & Verstöße](#strafen--verstöße)).
  - 🔶 **Darf keinen Ball führen** – im Aktionen-Katalog festgehalten (Ball aufheben/werfen/fangen: „alle außer Sani und Stürmer“); Verstoß → **Ball tot** (vgl. [Strafen & Verstöße](#strafen--verstöße)). Durchsetzung folgt mit der Aktionen-Engine.
- **Stürmer:** kann Spielende (außer dem Ballträger) transportieren.
  - ❌ Transport-/Motorrad-Mechanik noch nicht modelliert (Attributsbonus +2 Agilität ✅).
  - 🔶 **Darf keinen Ball führen** – im Aktionen-Katalog festgehalten (Ball aufheben/werfen/fangen: „alle außer Sani und Stürmer“); Verstoß → **Ball tot** (vgl. [Strafen & Verstöße](#strafen--verstöße)). Durchsetzung folgt mit der Aktionen-Engine.
- **Rollenwechsel:** im Spiel vor jedem Spielzug nur auf **freie Rollen** (`ObjectTeam.isRoleFree`).
  - **Einwechselreihenfolge (beschlossen):** Beim Einwechseln eines Spielers wird **zuerst** geprüft, ob in der **Primärrolle** des Spielers noch Platz ist; nur wenn das nicht der Fall ist, wird die **Sekundärrolle** zugewiesen.
  - **Ungedeckte Rolle:** Ist kein einsetzbarer Spieler vorhanden, der eine leere Rolle füllen kann, **bleibt diese Rolle leer** (sie wird im Spielzug nicht besetzt).
  - 🔶 Logik beschlossen; `isRoleFree` existiert, die Einwechsel-UI/-Logik folgt mit der Match-Engine.
- **Kapitän:** vor Matchbeginn muss genau **ein** Spieler zum Kapitän ernannt sein (`hasCaptain`).

### Verletzungsstatus (Zustandsmonitor)

`CharacterStatus` bildet die Verletzungsspur ab: `fine → reeling → hurt → afraid → injured → dying → dead → overkilled` (✅ im Code, deutsche `displayName`). Die konkreten Auswirkungen der einzelnen Stufen auf die Würfe (Verletzungswurf etc.) sind noch offen (❌). Die **Verletzungs-Arten** aus dem Scan (Unfall, Friendly Fire, Outside Interference, Combat Wound) sind im Abschnitt [Strafen & Verstöße](#strafen--verstöße) festgehalten.

## Aktionen & Kampfmanöver

Der Aktionen-Katalog (`spielerhandlungen/spielehandlungen.md`) definiert die möglichen Aktionen mit ihren Rollen-Einschränkungen:

| Aktion | Ausführende |
|--------|-------------|
| Bewegen | Alle außer Stürmer |
| Sprinten | Alle außer Stürmer |
| Klettern | Alle außer Stürmer |
| Springen | Alle außer Stürmer |
| Steuern | Nur Stürmer |
| Ausweichen | Alle |
| Parieren | Alle |
| Volle Verteidigung | Alle |
| Volle Deckung | Alle außer Stürmer |
| Nahkampfangriff | Alle |
| Ringenangriff | Alle |
| Fernkampfangriff | Alle |
| Salvenangriff | Alle |
| Biotech | Nur Sani |
| Ball aufheben | Alle außer Sani und Stürmer |
| Ball werfen | Alle außer Sani und Stürmer |
| Ball fangen | Alle außer Sani und Stürmer |
| Aufsteigen (Beifahrer) | Alle außer Ballträger und Stürmer |
| Absteigen (Beifahrer) | Alle außer Ballträger und Stürmer |

Hinzu kommen die **Kampfmanöver** (Taktik kleinerer Einheiten) für Gruppenaktionen: Dynamisches Eindringen, Feuerwalze, Flankieren, Gedeckte Aufklärung, Kreuzfeuer, Rautenformation, Rudelangriff, Schilde vor!, Überschlagender Rückzug, Überschlagendes Vorgehen, Unterstützungsfeuer.

> **Stand:** Hacking und Magie werden für die erste Simulation **weggelassen** (vgl. Diskussion in `spielerhandlungen/spielehandlungen.md`). Eine Aktionen-/Kampfmanöver-Engine gibt es im Code noch nicht (❌).

## Strafen & Verstöße

Der Strafen-Katalog (Scan `image2.png` in diesem Ordner, Titel „Strafen und Verstösse“) regelt die **Konsequenzen von Regelverstößen** während des Spiels. Der gesamte Katalog ist 🔶 **beschlossen, aber im Code noch nicht umgesetzt**.

### Regelverstoß → Strafe

| # | Regelverstoß | Strafe |
|---|--------------|--------|
| 1 | Angriff auf Sani / Offizielle / ausgeschaltete Spieler | **Abschuss** |
| 2 | Verlassen der Kriegszone | **Treffer** |
| 3 | Illegale Ballaufnahme (z. B. durch Sani/Stürmer) | **Ball tot** |
| 4 | Keine Ballaufnahme binnen 10 Sekunden nach Ballverlust | **Ball tot** |
| 5 | Zerstörung, Brandstiftung | **Treffer/Abschuss**; bei Spielabbruch = automatische Niederlage |
| 6 | Technik-/Magie-Schummelei (z. B. astrale Aufklärung) | **Abschuss + Spielverlust** |
| 7 | Unsportlichkeit (z. B. Provokation, Kameramanipulation) | je nach Ausmaß **Treffer oder Abschuss** |
| 8 | Illegale Waffe aufgenommen/genutzt | **Treffer** |
| 9 | Ball 60 Sekunden im selben Block | **Freeze** |
| 10 | Strafmissachtung | **Abschuss via Strafverdrahtung** |
| 11 | Eintritt in die Kriegszone nicht binnen 30 Sekunden vor dem nächsten Spielzug | **Freeze** |

> **Hinweis (Scan `image2.png`):** „Strafverdrahtung“ (Zeile 10) ist ein Begriff aus dem Scan; die genaue Mechanik ist noch zu definieren (vgl. Offene Punkte). „Zerstörung, Brandstiftung“ (Zeile 5) bezieht sich auf die Kriegszone/Umgebung.

### Strafarten

| Strafe | Wirkung |
|--------|---------|
| **Freeze** | Team darf sich nicht bewegen (meist zur Spielbeschleunigung) |
| **Treffer** | Spieler ist bewegungsunfähig, bis der Spielzug zu Ende ist |
| **Abschuss** | Spieler wird für den Rest des Viertels entfernt |

### Verletzungen

Der Scan listet vier Verletzungs-Arten. Sie wirken auf die Verletzungsspur des betroffenen Spielers ([Zustandsmonitor](#verletzungsstatus-zustandsmonitor)):

| Verletzungsart | Ursache / Bemerkung (Scan) |
|----------------|----------------------------|
| **Unfall** | Durch Gelände, z. B. ein schwerer Sturz |
| **Friendly Fire** | „Shit happens“ – Kollateralschaden durch eigene Spieler (kein Schuldiger) |
| **Outside Interference** | Angriff (durch Shadowrunner) von außerhalb der Kampfzone |
| **Combat Wound** | Angriff durch gegnerische Spieler |

> 🔶 **Status:** Regelverstoß-Katalog, Strafarten und Verletzungen sind beschlossen. Die Strafen-Engine (Erkennung/Auswertung, Protokollierung in der `battle_log`, Wirkung auf `CharacterStatus`) fehlt im Code.

## Ausrüstung

### Panzerung

| Klasse | Rollen |
|--------|--------|
| leicht | Scout, Schütze |
| mittelschwer | Jäger, Brecher, Stürmer |
| schwer | Sani |

### Waffen & Munition

- Erlaubt sind u. a.: persönliche Schusswaffe, schwere Pistolen, Revolver, Automatikpistolen, Schrotpistolen, Sturmgewehr, Maschinenpistole, Schrotflinte, leichtes MG mit Gyrostabilisator sowie Nahkampfwaffen (waffenlos, Schlagring, Klingen, Knüppel, Peitsche).
- **Im Feld gefundene Waffen** dürfen aufgehoben und verwendet werden.
- **Jegliche Munitionsart** ist erlaubt (APDS, panzerbrechend, Ex-Ex).

### Verbote

| Verbot | Status |
|--------|--------|
| Monofilamentwaffen, Elektrowaffen, Chemiewaffen | ✅ beschlossen |
| Cyberwaffen | ✅ beschlossen |
| Technik-/Magie-Schummelei (z. B. astrale Aufklärung) | ✅ beschlossen |
| Drogen | ✅ beschlossen |

### Cyberware & Bioware

- **Erlaubt** (beides ist Standard bei Profis); die Werte-Modifikatoren stehen in `5_Ausruestung.md`.
- Einschränkungen nach SR5-Standard: **Essenz-Budget** (6.0), Kategorie-Obergrenzen (max. 1 Implantat pro Körperbereich), Availability, Nuyen-Kosten.
- 🔶 Wirkung auf `marketValue`/`price` ist beschlossen, die genaue Umrechnungsformel fehlt noch.

## Magie

- **Erlaubt:** Adeptenkräfte, magische Heilung durch Sanis, indirekte Kampfmagie.
- **Verboten:** direkte Kampfmagie, Illusions- und Beherrschungszauber sowie alle Arten von Foki.
- ❌ Umsetzung für die erste Simulation zurückgestellt (wird weggelassen).

## Spielerwerte (Würfelpools)

Der Katalog aus `spielerwerte/spielerwerte.md` (18 Werte als Würfelpools) mit Umsetzungsstand im Modell (`3_Object_Player.md`):

| Wert | Bedeutung | Status |
|------|-----------|--------|
| Panzerung | Rüstungsklasse der Rolle | ✅ `TeamPositions.armor` (`ArmorClass`) |
| Zustandsmonitor | Verletzungsspur | 🔶 `CharacterStatus` (8 Stufen), Wurf-Wirkung offen |
| Initiative | Reaktionsgeschwindigkeit | ❌ (SR5-Boosts werden auf Agilität abgebildet) |
| Haupt-/Nebenhandlungen | Aktionen pro Runde | ❌ |
| Verteidigungspool | Ausweichen/Parieren | 🔶 Basiswert `PlayerAttribute.defense` |
| Schadenswiderstandspool | Widerstand gegen Schaden | 🔶 Basiswert `PlayerAttribute.resistance` |
| Nahkampfangriffspool | Nahkampf | 🔶 Basiswert `PlayerAttribute.attack` |
| Fernkampfangriffspool | Fernkampf | 🔶 Basiswert `PlayerAttribute.attack` |
| Athletikpool | Bewegen/Klettern/Springen | 🔶 Basiswert `PlayerAttribute.agility` |
| Steuernpool | Motorrad (Stürmer) | ❌ |
| Wahrnehmungspool | Wahrnehmung | 🔶 Basiswert `PlayerAttribute.attention` |
| Heimlichkeitspool | Schleichen/Tarnen | ❌ |
| Edge | Glück / Schicksalspunkte | ✅ Basiswert `PlayerAttribute.edge` |
| Einfluss | Führung/Taktik kleinerer Einheiten | ❌ |
| Biotechpool | Medizinische Versorgung (nur Sani) | ❌ |
| Moral | Kampfmoral | ✅ Basiswert `PlayerAttribute.morale` |
| Ruf/Fame | Bekanntheitsgrad | ✅ `ObjectPlayer.fame` |
| Marktwert | Wert auf dem Spielermarkt | ✅ `ObjectPlayer.price` / `marketValue` |

> **Hinweis:** Die Basisattribute existieren im Modell; die **Würfelpool-Logik** (wie die Werte in Würfe übersetzt werden) steht noch aus.

## Aktueller Stand (Simulation)

### ✅ Umgesetzt

- **Kaderregeln:** `maxRosterSize = 20`, `requiredRoster` (4/4/2/1/1/1 = 13), `isTeamValid`, gekapselter Kader (`addPlayer`/`removePlayer`/`updatePlayer`).
- **Rollenprofil:** `TeamPositions` mit Panzerung, Verteidigung, Ausrüstungsoptionen, Angriffsbonus und Attributsbonus; Legacy-Mapping alter Code-Namen.
- **Kapitänspflicht:** genau ein Kapitän vor Matchbeginn (`hasCaptain`, geprüft in `ObjectReferee.setTeamReadyForBattle`).
- **Primär-/Sekundärrolle** inkl. Rollenwechsel-Regel (`isRoleFree`; UI folgt mit der Match-Engine).
- **Teamstatistik:** 3-1-0-Schema (`TeamMatchRecord.quality`), Eintragung bei Matchende.
- **Spielerwerte:** 7 Attribute, Rassen-Modifikatoren, Marktwert/Preis/Ruhm, Enneagramm-Persönlichkeit.
- **Verletzungssystem:** `CharacterStatus` (8 Stufen, deutscher `displayName`).
- **Match-Gerüst:** Matchstart über `ready_for_battle`, `battle_log` mit Realtime-Updates, Matchende mit Ergebnisspeicherung.

### 🔶 Teilweise umgesetzt

- **Ausrüstung:** Modifikatoren-Tabellen definiert (`5_Ausruestung.md`), wirken noch nicht über `effectiveValue`; Marktwert-Formel offen.
- **Feldgröße:** Regel „13 pro Team“ geklärt, ein Feld-Slot-/26-Spieler-Mechanismus fehlt.
- **Abstrakte Auflösung:** als Konzept beschlossen (5 Ausgänge), aber keine Würfel-/Wurf-Engine.

### ❌ Fehlt noch

- **Viertel-/Spielzug-Logik** im `ObjectReferee` (4 × 30 Min., 5-Min-Spielzüge, Wechsel nur zwischen Vierteln).
- **Sektor-Sicht / Fog of War:** volle Sicht nur im Sektor mit eigenen Spielern; Sektorennamen für alle sichtbar; Datenmodell (Sektor je Spieler) & Rendering fehlen.
- **Torzonen-Platzierung & -Wahrnehmung:** Auswahl in den Startsektoren, zufällige Platzierung („Automatisch“/keine Wahl), Wahrnehmung per Würfelwurf (`PlayerAttribute.attention`).
- **Siegbedingungen** im Code umsetzen (beschlossen: meiste Punkte → Tiebreaker spielfähige Spieler; Spielfähigkeit/Wipeout; Schiri-Abbruch; beidseitiger Wipeout → Unentschieden).
- **Auszeiten, toter Ball** (Häufigkeiten, Dauer, Konsequenzen).
- **Strafen-Engine** umsetzen: Regelverstoß-Katalog (Strafe je Verstoß), Strafarten (Freeze/Treffer/Abschuss), „Strafverdrahtung“, automatische Niederlage bei Spielabbruch (beschlossen, vgl. Abschnitt [Strafen & Verstöße](#strafen--verstöße)).
- **Aufstellung (scouten/offensiv/defensiv)** als Manager-Entscheidung pro Viertel – inkl. Automatik-Checkbox (bei Spielsuche) und RL-Zeitlimit (15 Min.).
- **Punkte-/Verletzungswurf** (Würfelmechanik) mit Einfluss von Aufstellung und Spielerwerten.
- **Aktionen-Engine** inkl. Kampfmanöver, Sani-Schutz („nicht angegriffen“), Stürmer-Transport/Motorrad, Ballführungs-Verbot (Sani/Stürmer).
- **Einwechsel-Logik** (beschlossen): Primärrolle zuerst, sonst Sekundärrolle; ungedeckte Rollen bleiben leer (`isRoleFree`-API vorbereitet).
- **Magie/Hacking** (bewusst für die erste Simulation ausgeklammert).

## Offene Punkte

| # | Punkt | Status |
|---|-------|--------|
| 1 | **Siegbedingungen** im Code umsetzen (meiste Punkte → Tiebreaker spielfähige Spieler; Spielfähigkeit/Wipeout; Schiri-Abbruch; beidseitiger Wipeout → Unentschieden) | 🔶 |
| 2 | **Viertel-/Spielzug-Logik** im `ObjectReferee` (4 × 30 Min., 5-Min-Zug, Wechselregeln) | ❌ |
| 3 | **Abstrakte Auflösung:** Punkte-/Verletzungswurf inkl. Aufstellungs- und Werte-Einfluss | ❌ |
| 4 | **Aufstellung (scouten/offensiv/defensiv)** inkl. Automatik-Checkbox & RL-Zeitlimit (15 Min.) | ❌ |
| 5 | **Auszeiten, toter Ball** (Häufigkeit/Dauer/Konsequenzen; Strafen-Katalog liegt vor) | ❌ |
| 6 | **Feld-Slot-Mechanismus** (26 Spieler gleichzeitig auf dem Feld) | ❌ |
| 7 | **Aktionen-/Kampfmanöver-Engine** | ❌ |
| 8 | **Sani-Schutz** („darf nicht angegriffen werden“) | ❌ |
| 9 | **Stürmer-Transport / Motorrad-Mechanik** | ❌ |
| 10 | **Zustandsmonitor:** konkrete Wirkung der Status-Stufen auf Würfe | ❌ |
| 11 | **Zeitmodell pro Aktion** (variable Zuglängen) | ❌ |
| 12 | **Ausrüstung → Marktwert/Preis-Formel** | 🔶 |
| 13 | **Magie/Hacking** endgültig beschließen (erste Simulation: weglassen) | 🔶 |
| 14 | **Scouten-Mechanik:** Wie wirkt das Scouten konkret auf das Auffinden der gegnerischen Torzone (Modifikator auf den Wahrnehmungs-Wurf, vgl. [Torzone (Zielzone)](#torzone-zielzone))? | ❌ |
| 15 | **Automatik-Algorithmus:** Nach welcher Logik werden Positionen/Werte auf scouten/offensiv/defensiv verteilt? | ❌ |
| 16 | **Schiedsrichter-Abbruch in der Simulation:** Wie wird Siegbedingung 3 (Abbruch bei Übergriff von außen) abgebildet – manueller Admin-/Schiri-Eingriff oder Automatik? | ❌ |
| 17 | **Beidseitiger Wipeout → Unentschieden:** Siegbedingung 4 ist beschlossen. Offen: (a) Soll der beidseitige Wipeout als zusätzlicher (6.) Ausgang der abstrakten Spielzug-Auflösung modelliert werden? (b) Umsetzung im Match-Record: `endMatch`/`recordMatchResult` kennen nur Winner/Loser – `TeamMatchRecord.drawn` existiert bereits | ❌ |
| 18 | **Einwechsel-Logik:** beschlossen (Primär- vor Sekundärrolle; ungedeckte Rolle bleibt leer). Umsetzung folgt mit der Match-Engine/Substitutions-UI auf Basis von `isRoleFree` | ❌ |
| 19 | **Strafen-Engine:** Regelverstoß-Katalog umsetzen – Strafarten (Freeze/Treffer/Abschuss), „Ball tot“, „Strafverdrahtung“ (Mechanik definieren), automatische Niederlage bei Spielabbruch; Protokollierung in der `battle_log` | ❌ |
| 20 | **Verletzungsarten in der Simulation:** Wie werden Unfall / Friendly Fire / Outside Interference / Combat Wound in der abstrakten Auflösung ausgelöst (Wurf-Trigger)? „Friendly Fire“-Behandlung („Shit happens“) fixieren | ❌ |
| 21 | **Fog of War / Sektor-Sicht:** volle Sicht nur im Sektor mit eigenen Spielern; Datenmodell (Sektor je Spieler), Sichtbarkeits-Logik & Rendering offen | ❌ |
| 22 | **Torzonen-Platzierung & -Wahrnehmung:** Auswahl in den Startsektoren (15-Min-Zeitlimit/„Automatisch“), zufällige Platzierung, Wahrnehmung per Würfelwurf (Wahrnehmungspool `attention`) | ❌ |

## Quellen

- `spielablauf/spielablauf.md` – Spielstruktur, Spielfeld, abstrakte Auflösung
- `ausruestung/ausruestung.md` – Waffen, Panzerung, Verbote, Magie
- `spielerhandlungen/spielehandlungen.md` – Aktionen, Kampfmanöver
- `spielerwerte/spielerwerte.md` – Werte-Katalog
- `1_theorie.md` – Bestandsaufnahme Code vs. Anforderungen
- `2do_07_07_26.md` – Sprintvorgaben (Spielstruktur, Spielzug-Dauer, Systemparameter, Output)
- `3_Object_Player.md`, `4_Object_Team.md`, `5_Ausruestung.md` – Modell- und Werte-Dokumentation
- `image2.png` (Scan „Strafen und Verstösse“) – Strafen-Katalog: Regelverstoß → Strafe, Strafarten, Verletzungen

---

*Stand: 29.08.2026*

