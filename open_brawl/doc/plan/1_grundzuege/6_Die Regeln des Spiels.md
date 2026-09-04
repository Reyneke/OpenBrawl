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
- **Wahl/Zeitlimit:** Ist der **„Automatisch“-Haken** nicht gesetzt (vgl. [Manager-Entscheidung](#manager-entscheidung-positionen)), haben die Manager **15 Minuten** Zeit, die Torzone zu wählen. Trifft ein Manager keine Wahl oder ist „Automatisch“ aktiv, wird die Torzone **zufällig** platziert.

### Fog of War

- Jede Mannschaft hat nur in dem **Sektor volle Sicht**, in dem sich Spieler der eigenen Mannschaft befinden.
- 🔶 Die Sichtbarkeit der **Torzone** ist davon **unabhängig**: Zu Beginn ist jede Torzone nur für das **besitzende Team** sichtbar.
- 🔶 Erst wenn ein Spieler des anderen Teams die Torzone **wahrgenommen** hat (**Würfelwurf**, voraussichtlich über den Wahrnehmungspool → `PlayerAttribute.attention`), wird sie für dieses Team offenbar.

### Sektorkontrolle

- Alle Sektoren sind zu **Spielbeginn unkontrolliert**.
- Ein Sektor kommt unter **Kontrolle eines Teams**, wenn sich am **Ende eines Spielzugs** nur Spieler dieses Teams in ihm aufhalten.
- Ein Team kann sich _nur_ in einem Sektor verstecken, wenn es ihn kontrolliert.
- 🔶 Status: Regel beschlossen; Kontroll-Zustand & Abrechnung am Spielzug-Ende sind im Code nicht umgesetzt.

### Verteidigungsbonus (Sektor)

Ein von einem Team kontrollierter Sektor gibt dessen Spielern einen **Bonus auf die Verteidigung** – er wirkt auf den **Defensiv-Würfelpool** (vgl. [Würfelsystem](#würfelsystem-konzept)). Der Bonus setzt sich zusammen aus:

| # | Eingangswert |
|---|--------------|
| 1 | Defensivwert aller Verteidiger (**Mittelwert**) |
| 2 | Persönlichkeit des **Kapitäns**, wenn dieser unter den Verteidigern ist; sonst Persönlichkeit der Person mit dem **höchsten Verteidigungswert** |
| 3 | Gelände |
| 4 | Points of Interest (spätere Implementierung) |
| 5 | Sektoreffekte (spätere Implementierung) |

Zur Festlegung wird ein **Fuzzyset** definiert (siehe Fuzzy Library in diesem Projekt: `lib/fuzzy_logic/` mit `FuzzySet`, `FuzzyVariable`, `FuzzyRuleBase`). Es erstreckt sich zwischen **„Ideal“** und **„Miserabel“**, nimmt als Eingangswerte die obigen Wertigkeiten und liefert als Ausgangswert eine Menge zwischen **−4 und +4**.

- Für **Angreifer** in diesem Sektor wird der errechnete Wert als **Malus auf den Offensiv-Pool** angerechnet.
- 🔶 Status: Fuzzy-Library existiert (`lib/fuzzy_logic/`), die sektorbezogene Anwendung (Eingangs-Aggregation, Fuzzyset-Parameter, Pool-Verknüpfung) fehlt noch.

### Angriffsbonus (Sektor)

Ein von einem Team kontrollierter Sektor gibt dessen Spielern einen **Bonus beim Konterangriff gegen Angreifer** – er wirkt auf den **Offensiv-Würfelpool** (vgl. [Würfelsystem](#würfelsystem-konzept)). Der Bonus setzt sich zusammen aus:

| # | Eingangswert |
|---|--------------|
| 1 | Angriffswert aller Verteidiger (**Mittelwert**) |
| 2 | Persönlichkeit des **Kapitäns**, wenn dieser unter den Verteidigern ist; sonst Persönlichkeit der Person mit dem höchsten **Angriffswert** ⚠️ |
| 3 | Gelände |
| 4 | Points of Interest (spätere Implementierung) |
| 5 | Sektoreffekte (spätere Implementierung) |

Zur Festlegung wird – wie beim [Verteidigungsbonus](#verteidigungsbonus-sektor) – ein **Fuzzyset** (Fuzzy Library: `lib/fuzzy_logic/`) zwischen **„Ideal“** und **„Miserabel“** mit einem Ausgangsbereich von **−4 bis +4** definiert.

- Für **Angreifer** in diesem Sektor wird der errechnete Wert als **Malus auf den Defensiv-Pool** angerechnet.
- 🔶 Status: Fuzzy-Library existiert (`lib/fuzzy_logic/`), die sektorbezogene Anwendung fehlt noch.

> ⚠️ **Hinweis:** Beim Angriffsbonus ist der Fallback bei der Kapitäns-Persönlichkeit als „höchster **Angriffswert** ⚠️“ markiert – zu klären bleibt, ob hier tatsächlich der Angriffswert gemeint ist (Kopierfehler vom Verteidigungsbonus wäre ausgeräumt) oder doch der Verteidigungswert (vgl. Offene Punkte #27).

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

### Manager-Entscheidung (Positionen)

- Vor dem Spiel / pro Viertel entscheidet der **Manager**, wie viele und welche Spieler **aufklären**, **offensiv** oder **defensiv** eingesetzt werden.
- **Aufklären** verstärkt die Fähigkeit, die gegnerische Torzone zu finden; ein offensiver bzw. defensiver Einsatz verstärkt die **Offensiv- bzw. Defensivkraft** des Teams. Die Positionierung fließt in die Würfe ein.

> **Automatik-Option („Automatisch“):** Der Geschwindigkeit halber kann der Manager bereits bei der **Spielsuche** per Checkbox die Option **„Automatisch“** aktivieren. Das Setup vor Spielbeginn bzw. die Positionierung zwischen den Vierteln erfolgt dann automatisch – die Spieler werden nach ihren **Positionen und Werten** auf die drei Einsatzarten (aufklären/offensiv/defensiv) verteilt.
>
> **Zeitlimit:** Ist die Checkbox **nicht** gesetzt, hat der Manager eine **RL-Viertelstunde** (15 Minuten Echtzeit) Zeit, die Positionierung manuell vorzunehmen. Läuft das Zeitlimit ab, greift derselbe Automatismus.

> **Status:** ❌ beschlossen, im Code noch nicht umgesetzt – weder Positions-UI noch Automatik/Zeitlimit existieren bisher.

### Positionen und Aufgaben

Die Positionierung teilt die Mannschaft in die drei **Einsatzarten** bzw. **Positionen** **Offensiv**, **Defensiv** und **Aufklärer** (vgl. [Manager-Entscheidung (Positionen)](#manager-entscheidung-positionen)). Jede Position übernimmt während eines Spielzugs eigene Aufgaben:

Die Fähigkeit einer Position, sich zu **verstecken**, bestimmt, ob ihre Spieler als „versteckt“ gelten – und ist damit relevant für den [Verstecken-Pool](#die-vier-würfelpools), die [„Suchen und Finden“-Enttarnprobe](#suchen-und-finden) sowie die halbtransparente Tokendarstellung im [Fog of War](#fog-of-war).

#### Offensiv

- Braucht **immer mindestens eine Rolle, die den Ball tragen kann** – wer den Ball führen darf, regelt der Aktionen-Katalog („Ball aufheben/werfen/fangen: alle außer Sani und Stürmer“, vgl. [Aktionen & Kampfmanöver](#aktionen--kampfmanöver)):
  - Ist **kein Ballträger** mehr in der Position „Offensiv“, ist das **Viertel** für die Mannschaft gelaufen.
  - Kann sie keinen Ballträger mehr **reinrotieren**, ist das **Spiel** für die Mannschaft gelaufen (vgl. [Siegbedingungen](#siegbedingungen) – Spielfähigkeit).
- Kann sich nicht verstecken
- Aufgaben:
  1. Sucht die Torzone
  2. Macht Tore
  3. Unterstützt die Aufklärer

#### Defensiv

1. Verteidigt die eigene Torzone
2. Verteidigt kontrollierte Sektoren (vgl. [Sektorkontrolle](#sektorkontrolle))
3. Kann sich **verstecken**, wenn es die Lage zulässt (Special, Points of Interest)

#### Aufklärer

1. Sucht die gegnerische Torzone
2. Sucht das gegnerische Team – als **einzige Position** sehen Aufklärer dafür in **angrenzende Sektoren** (vgl. [Fog of War](#fog-of-war))
3. Erobert Sektoren (vgl. [Sektorkontrolle](#sektorkontrolle))
4. Bewegt sich immer **„versteckt“** voran

> ⚠️ **Hinweis:** Die Sicht-Ausnahme der Aufklärer („in angrenzende Sektoren sehen“) ist bislang nur hier festgehalten; der Abschnitt [Fog of War](#fog-of-war) beschreibt bisher nur die volle Sicht im Sektor mit eigenen Spielern.

> **Status:** ❌ Aufgaben beschlossen, im Code noch nicht umgesetzt – die Positionierungs-Logik folgt mit der Match-Engine (vgl. Offener Punkt #4).
>
> 🔶 **Status (Verstecken-Fähigkeit):** Die positionsbezogene Regel „Offensiv nie, Defensiv situativ, Aufklärer immer“ ist beschlossen, aber noch nicht umgesetzt – die „versteckt“-Zustandslogik folgt mit der [Suchen und Finden](#suchen-und-finden)-Engine (vgl. Offene Punkte #41/#42).

## Wertung & Siegbedingungen

### Wertung

- **Punkt:** wenn der Ball **innerhalb der gegnerischen Torzone den Boden berührt**.
- Nach einem Punkt **resetten beide Teams in ihre eigene Torzone**; ein neuer Spielzug beginnt.
- Das Spielergebnis (inkl. Verletzungen) wird „per Zufall“ ermittelt: **Verletzungswurf** + **Punktwurf**, beide beeinflusst durch die **Positionierung** (aufklären/offensiv/defensiv) und die **Spielerwerte**.

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

`CharacterStatus` bildet die Verletzungsspur ab: `fine → reeling → hurt → afraid → injured → dying → dead → overkilled` (✅ im Code, deutsche `displayName`). Die konkreten Auswirkungen der einzelnen Stufen auf die Würfe (Verletzungswurf etc.) sind noch offen (❌) – die **Todes-Folgen** von `dying` / `dead` / `overkilled` sind dagegen in [Verwundung und Tod](#verwundung-und-tod) festgelegt (inkl. Stabilisierungsschwelle `dead` und Sani-Rettung, Beschluss 30.08.2026). Die **Verletzungs-Arten** aus dem Scan (Unfall, Friendly Fire, Outside Interference, Combat Wound) sind im Abschnitt [Strafen & Verstöße](#strafen--verstöße) festgehalten.

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

### Auswahl von Aktion / Manöver

Die Wahl der richtigen **Aktion bzw. des Manövers** wird **je nach Positionierung** entschieden (offensiv / defensiv / aufklären, vgl. [Manager-Entscheidung (Positionen)](#manager-entscheidung-positionen)).

**Entscheider:**

- Befindet sich der **Teamkapitän** in der Positionierung, gibt er die Aktion/das Manöver an.
- Ansonsten entscheidet der Spieler mit dem **höchsten Wert**, der der jeweiligen Positionierung zugeordnet ist (**Offensiv-Pool für offensiv, Defensiv-Pool für defensiv, Aufklärungs-Pool für aufklären** – vgl. [Würfelsystem](#würfelsystem-konzept)).

**Faktoren, welche die Wahl beeinflussen:**

| # | Faktor |
|---|--------|
| 1 | Wer hat den Ball? |
| 2 | Persönlichkeit |
| 3 | Moral |
| 4 | Art der Positionierung (offensiv / defensiv / aufklären) |
| 5 | Zustand der Positionierung (Verletzungsmodifikatoren) |
| 6 | Andere Faktoren (noch zu definieren) |

Diese Werte dienen als **Eingangswerte eines Fuzzysets** (vgl. `lib/fuzzy_logic/`); die Ausgangswerte sind **alle möglichen Aktionen/Manöver**, von denen das **wahrscheinlichste** ausgewählt wird (Ziel: `FuzzyRuleBase` mit Aktionen/Manövern als Ausgang).

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – die Entscheider-Logik (Kapitän → höchster Pool-Wert), das Fuzzyset der Einflussfaktoren und die Auswahlwahrscheinlichkeit existieren noch nicht.

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
| Biotechpool | Medizinische Versorgung (nur Sani); Grundlage des Sani-Rettungswurfs (vgl. [Verwundung und Tod](#verwundung-und-tod)) | ❌ |
| Moral | Kampfmoral | ✅ Basiswert `PlayerAttribute.morale` |
| Ruf/Fame | Bekanntheitsgrad | ✅ `ObjectPlayer.fame` |
| Marktwert | Wert auf dem Spielermarkt | ✅ `ObjectPlayer.price` / `marketValue` |

> **Hinweis:** Die Basisattribute existieren im Modell; die **Würfelpool-Logik** (wie die Werte in Würfe übersetzt werden) steht noch aus.

## Würfelsystem (Konzept)

> **Status:** 🔶 Konzept **beschlossen** (Entwurf), im Code noch nicht umgesetzt – die bestehende Tabelle [Spielerwerte (Würfelpools)](#spielerwerte-würfelpools) listet die Werte; die eigentliche **Würfelpool-Logik** fehlt noch. Die Pool-Bezeichnungen dieses Abschnitts sind **Gruppen** des Werte-Katalogs.

### Die vier Würfelpools

Prinzipiell gibt es – zusätzlich zum [Bewegungsfaktor](#bewegungsfaktor) – **vier Würfelpools pro Spieler**:

| Pool | Zusammensetzung (Attribut + Attribut) |
|------|---------------------------------------|
| **Offensiv** | Angriff + **Agilität** |
| **Defensiv** | Verteidigung + Widerstand |
| **Aufklärung** | Aufmerksamkeit + Moral |
| **Verstecken** | Agilität + Widerstand |

> 🔶 **Zusatz (beschlossen):** Als **vierter Würfelpool** wurde der **Verstecken-Pool** festgelegt – er setzt sich zusammen aus **Agilität + Widerstand**. Er kommt dort zum Tragen, wo sich Spieler versteckt fortbewegen oder aus dem Versteck agieren (vgl. [Positionen und Aufgaben](#positionen-und-aufgaben)). Ob er mit dem **Heimlichkeitspool** (Schleichen/Tarnen) des [Werte-Katalogs](#spielerwerte-würfelpools) identisch ist, ist noch zu klären (vgl. Offener Punkt #39).

### Modifikatoren

Alle **vier Würfelpools** werden durch folgende Faktoren modifiziert:

| # | Faktor |
|---|--------|
| 1 | Rolle |
| 2 | Persönlichkeit |
| 3 | Ausrüstung |
| 4 | Cyber/Bioware |
| 5 | Positionierung |
| 6 | Verletzungsstufen |

### Positions-Boni

Bei der Positionierung ergeben sich folgende Boni auf die Pool-Werte:

| Positionierung | Offensiv-Pool | Defensiv-Pool | Aufklärungs-Pool | Verstecken-Pool |
|----------------|---------------|---------------|------------------|-----------------|
| **Offensiv** | doppelter Wert | – | halber Wert | halber Wert |
| **Defensiv** | halber Wert | doppelter Wert | halber Wert | – |
| **Aufklärung** | halber Wert | normaler Wert | doppelter Wert | doppelter Wert |

> **Erläuterung:** „–“ bedeutet **normaler Wert** (kein Bonus, keine Änderung).

> 🔶 **Änderung (beschlossen):** Die **Aufklärung** (in der Rohquelle „Scouts“ genannt) erhält einen **normalen Defensiv-Pool** – statt des bisherigen halben Werts – und dafür einen **doppelten Verstecken-Pool**. **Defensiv**-Positionierte behalten den **normalen Verstecken-Wert**; bei der **Offensiv**-Positionierung ändert sich nichts (Verstecken-Pool bleibt normal).

> ⚠️ **Hinweis (Inkonsistenz):** Die [Positions-Boni](#positions-boni)-Tabelle weist für die **Offensiv**-Positionierung beim **Verstecken-Pool** „halber Wert“ aus, die 🔶-Änderungsnotiz dagegen „bleibt normal“ – zu klären (vgl. Offener Punkt #42). Relevant v. a. im Zusammenspiel mit der Regel, dass sich **Offensiv nicht verstecken** kann (vgl. [Positionen und Aufgaben](#positionen-und-aufgaben)).

### Bewegungsfaktor

Zusätzlich zu den vier Würfelpools gibt es einen Bewegungsfaktor:

```
Bewegung (in Pixeln pro Spielzug) =
  ( Agilität (Basiswert)
    + Agilität (Erfolge: Würfel gegen 5 oder höher)
    - Modifikatoren )
  * 5
```

- Der **Bewegungsfaktor** wird durch **dieselben Faktoren** modifiziert wie die Würfelpools (Rolle, Persönlichkeit, Ausrüstung, Cyber/Bioware, Positionierung, Verletzungsstufen).
- **Ausnahme „Positionierung“:** Bei **Aufklärungs-Positionierung** gilt beim Bewegungsfaktor **doppelte Bewegung** (zusätzlich zum doppelten Aufklärungs-Pool).

> 🔶 **Hinweis:** Die Pool-Bezeichnungen (Offensiv/Defensiv/Aufklärung) sind konsistent mit den Positions-„Einsatzarten“ (aufklären/offensiv/defensiv, vgl. [Manager-Entscheidung](#manager-entscheidung-positionen)) – eine offensiv eingestellte Mannschaft stärkt genau den Offensiv-Pool usw. Für den **Verstecken-Pool** gibt es keine eigene Einsatzart; sein Wert wird über die [Positions-Boni](#positions-boni) geregelt (doppelt bei Aufklärung).

### Suchen und Finden

Mit der Einführung des **Verstecken-Pools** wurde auch eine **„Suchen und Finden“-Mechanik** beschlossen. Sie regelt, wann Spieler eines Teams gegnerische Spieler in einem **Sektor** entdecken bzw. **enttarnen** können und wie sich das auf die Sichtbarkeit im [Fog of War](#fog-of-war) auswirkt. Sie baut auf dem [Verstecken-Pool](#die-vier-würfelpools) (Agilität + Widerstand) sowie dem Aufklärungs-Pool auf.

**Ablauf:** Die Mechanik funktioniert **sektorweise** und greift, sobald Spieler eines Teams einen Sektor **aufdecken**, der bisher unter dem [Fog of War](#fog-of-war) gelegen hat:

1. Aus der Gruppe der aufdeckenden Spieler würfelt derjenige, der **innerhalb seiner Position** den **höchsten Wert in „Aufklärung“** besitzt, auf genau diesen Wert.
2. Jeder Spieler des gegnerischen Teams, dessen **„Verstecken“-Pool** kleiner ist als die so erzielten **Erfolge**, gilt als **enttarnt**.
3. Haben sich gegnerische Spieler versteckt (etwa **Aufklärer** – vgl. doppelter [Verstecken-Pool](#positions-boni)), würfeln diese – sollte ihre Entdeckung drohen – mit ihrem **„Verstecken“-Pool**. Erzielen sie dabei **mehr oder gleich viele Erfolge**, wie bei der Aufklärung gewürfelt wurden, bleiben sie **versteckt**.

**Sichtbarkeit:**

- Entdeckte Spieler des gegnerischen Teams sind automatisch **allen Spielern des eigenen Teams** bekannt.
- Versteckte Spielertokens werden auf der Kamera **halb durchsichtig** dargestellt; entdeckte wechseln auf **vollständig undurchsichtig**.

> 🔶 **Status:** Mechanik **beschlossen**, im Code noch nicht umgesetzt – weder eine sektorweise Aufdeckungs-/Enttarnungs-Logik noch die daran gekoppelte Sichtbarkeits-Umsetzung (halbtransparente Tokens) existieren. Die Bausteine ([Verstecken-Pool](#die-vier-würfelpools), [Fog of War](#fog-of-war), Positions-Boni der [Aufklärung](#positions-boni)) sind definiert; offene Umsetzungsfragen siehe Offener Punkt #40.

### Kampf (Kampfentscheidung)

Während eines Spielzugs bewegen sich die Spieler über das Feld und versuchen, ihrer Positionierung und ihren Rollen gerecht zu werden. Treffen sich Spieler **beider Teams** in einem Sektor, kann es zu einem **Kampf** kommen.

Die Bedingungen, ob ein Kampf entsteht, sind spielerbasiert und von mehreren Faktoren abhängig:

| # | Faktor |
|---|--------|
| 1 | Positionierung |
| 2 | Persönlichkeit |
| 3 | Moral |
| 4 | Erlittene Wunden |
| 5 | Anwesenheit des Teamkapitäns im Sektor |
| 6 | Ob bereits ein Kampf im Sektor stattfindet |
| 7 | Das gerade angesagte Manöver |

Diese Werte bilden ein **Fuzzyset** (vgl. `lib/fuzzy_logic/`): Eingangswerte sind die obigen Faktoren, der Ausgangswert ist eine **Wahrscheinlichkeit von 1 bis 10**, die jeder Spieler im Sektor mit seinem **doppelten Moralwert überwürfeln** muss.

**Gewichtung der Faktoren** (absteigende Priorität):

1. **Anwesenheit des Teamkapitäns im Sektor** – und ob dieser in den Kampf geht bzw. sich bereits darin befindet (wichtigster Faktor).
2. **Das angesagte Manöver**.
3. **Anzahl der erlittenen Wunden**.
4. **Zugehörigkeit zur Positionierung** – ein offensives Team ist eher angriffsbereit als ein defensives; **Aufklärer sind ganz unten** (vgl. [Manager-Entscheidung (Positionen)](#manager-entscheidung-positionen)).
5. **Moral** – wenn der Kampf für ein Team schlecht verläuft, zögern zusätzliche Mitglieder eher.
6. **Ob bereits ein Kampf im Sektor stattfindet** (zuletzt).

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – die Kampfentscheidung (Fuzzyset, Überwürfeln mit doppeltem Moralwert, Gewichtung) existiert noch nicht.

### Zielauswahl

Ein Spieler, der in den Kampf in einem Sektor einsteigt, wählt sein Ziel anhand **ähnlicher Faktoren** wie bei der [Kampfentscheidung](#kampf-kampfentscheidung) aus. Änderungen gegenüber der Entscheidungsprobe:

- Ist das Ziel sichtbar? (siehe Verstecken)
- **Zustand / Wunden aller Verteidigenden** fließen mit ein.
- Die **Gewichtung aller Faktoren** ist anders.

Bei der Gewichtung steht zuerst die **Persönlichkeit**, die direkt mit **Moral** und **Zustand / Wunden** korreliert: Für manche Persönlichkeiten ist es eher vertretbar, die **schwächste Einheit** anzugreifen als die stärkste – besonders, wenn es sich um eine Einheit handelt, die regeltechnisch gar nicht angegriffen werden darf (z. B. der **Sani**, vgl. [Sonderregeln](#sonderregeln) und [Strafen & Verstöße](#strafen--verstöße)).

Auch hier wird ein **Fuzzyset** gebildet – allerdings mit einem **Spieler der Gegenseite als Ausgangswert**, welcher zum **Ziel des Angreifers** wird.

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – die Zielauswahl (Persönlichkeits-Gewichtung, Fuzzyset mit Spieler-Output) fehlt noch.

### Angriff und Verteidigung

Bei einem Kampf würfeln **Angreifer und Verteidiger gegeneinander** – jeweils mit den Würfen aus dem [Würfelsystem](#würfelsystem-konzept):

1. **Angriff:** Der Angreifer würfelt seinen **Offensiv-Pool** gegen den (ebenfalls gewürfelten) **Defensiv-Pool** des Verteidigers. Hat er **mehr Erfolge**, ist die Differenz (**Erfolge Angreifer − Erfolge Verteidiger**) die **erlittene Anzahl an Verletzungsstufen** des Verteidigers.
2. **Gegenangriff (zeitgleich):** Der Verteidiger würfelt seinen **Offensiv-Pool** gegen den **Defensiv-Pool** des Angreifers – mit demselben Ergebnis (der Angreifer erleidet entsprechend Verletzungsstufen).

> **Hinweis:** Da beide Würfe **zeitgleich** laufen, können beide Kontrahenten im selben Kampf Verletzungen erleiden.

Anschließend folgt eine **Moralprobe**:

- **Probe-Gegner:** **maximale Anzahl Verletzungsstufen − aktuelle Verletzungsstufe**.
- **Kein Erfolg:** Der Spieler **gibt das Spiel für sich auf** – „Er war einfach zu verletzt“ – und scheidet aus dem aktuellen Spiel aus.
- **„Sterbend“ oder höher:** Erreicht ein Spieler die Verletzungsstufe **„Sterbend“** (`CharacterStatus.dying`) oder höher, fällt er ebenfalls aus dem aktuellen Spiel aus. `dying`-Spieler können geheilt werden und im neuen Viertel zurückkehren; ab `dead` greift die [Rettungs-Kette](#verwundung-und-tod) (Stabilisierung durch Sani möglich, sonst endgültiger Tod).

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – die Kampfabwicklung (Offensiv-/Defensiv-Pool gegeneinander, Verletzungsstufen-Differenz, Moralprobe, Ausscheiden ab „Sterbend“) existiert noch nicht. Die **maximale Anzahl Verletzungsstufen** ist noch zu definieren (vgl. Offene Punkte #30/#31).

### Specials

Würfelt ein **Angreifer oder ein Verteidiger** bei seiner **Angriffsprobe** **mehr als drei Erfolge über** die Verteidigungsprobe seines Gegners (Differenz **> 3**), tritt ein **Special** in Kraft. Das Special wird mit **2W6** ausgewürfelt und ergibt sich aus folgender Tabelle:

| 2W6 | Special |
|-----|---------|
| 2 | Kritischer Treffer (Schaden verdoppelt) |
| 3 | Ausrüstungsspecial 1 |
| 4 | Rollenspecial 1 |
| 5 | Positionsspecial 1 |
| 6 | Ausrüstungsspecial 2 |
| 7 | Rollenspecial 2 |
| 8 | Positionsspecial 2 |
| 9 | Ausrüstungsspecial 3 |
| 10 | Rollenspecial 3 |
| 11 | Positionsspecial 3 |
| 12 | Zweimal auf dieser Tabelle würfeln |

- Der Auslöser greift **symmetrisch**: Wird eine **Verteidigungsprobe** um mehr als drei Erfolge über eine Angriffsprobe geworfen, passiert dasselbe (vgl. [Angriff und Verteidigung](#angriff-und-verteidigung), wo beide Würfe zeitgleich laufen).
- **„Schaden“ beim Kritischen Treffer** = die erlittenen Verletzungsstufen aus der Erfolgs-Differenz (siehe [Angriff und Verteidigung](#angriff-und-verteidigung)).

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – die Special-Auslösung (Erfolgs-Differenz > 3), der 2W6-Wurf und die Special-Effekte existieren noch nicht. Die **Kataloge der Specials** (Ausrüstung/Rolle/Position 1–3) sind noch offen (vgl. Offene Punkte #32/#33).

=> Specials können auch passieren, wenn einer aus der Gegenseite patzt.

### Verwundung und Tod

Unterhalb von `dying` liegen auf der Verletzungsspur (`CharacterStatus`, `lib/objects/object_player.dart`) die Stufen `dead` und `overkilled`. **Beschlossen (30.08.2026):** Die **Stabilisierungsschwelle liegt bei `dead`** (Lesart a). Im Gegensatz zum ursprünglichen Freitext ist ein Spieler bei `dead` **nicht** unwiderruflich tot – ein Sani kann ihn über die [Rettungs-Kette](#rettungs-kette-stabilisierung) stabilisieren. Alle daraus resultierenden Schwellen (etwa das Ausscheiden aus dem Spiel, vgl. [Angriff und Verteidigung](#angriff-und-verteidigung)) sind entsprechend angepasst.

| Stufe | Konsequenz |
|---|---|
| `dying` („Sterbend“) | Fällt aus dem Spiel aus, kann aber **geheilt** werden und im **neuen Viertel** zurückkehren. |
| `dead` („Tot“) | **Stabilisierungsschwelle:** Fällt ganz aus dem Spiel aus, ist aber **nicht** unwiderruflich tot – die [Rettungs-Kette](#rettungs-kette-stabilisierung) greift; ohne erfolgreiche Rettung endgültig tot. |
| `overkilled` („Übertötet“) | Wie `dead`, aber der Sani benötigt die **doppelte** Anzahl an Biotech-Erfolgen (Tiefe unter `dead` × 2). |
| Schaden **oberhalb** von `overkilled` | **Permanent tot** – weder Stabilisierung noch Rettung durch den Sani. |

#### Rettungs-Kette (Stabilisierung)

Erreicht ein Spieler die Stabilisierungsschwelle (`dead` oder tiefer), greift **einmalig** folgende Kette:

1. **Eigenwurf auf doppelten Widerstand:** Der Spieler würfelt auf **doppelten Widerstand** (`PlayerAttribute.resistance` × 2). Erwürfelt er **mindestens zwei Erfolge**, stabilisiert er sich und **heilt eine Stufe** – danach wird nach den üblichen Regeln verfahren.
2. **Scheitern ohne Sani:** Gelingt der Wurf nicht und ist **kein Sani (mehr) im Team**, ist der Spieler **endgültig tot**.
3. **Scheitern mit Sani im Sektor:** Ist ein **Sani im Sektor**, würfelt dieser aus dem **Biotechpool**. Erforderlich sind **mindestens so viele Erfolge, wie der verletzte Spieler unter `dead` liegt** – 0-basiert gezählt, mindestens **1**; ab `overkilled` **verdoppeln** sich die benötigten Erfolge:

   | Status des Spielers | Tiefe unter `dead` | Benötigte Sani-Erfolge (Biotechpool) |
   |---|---|---|
   | `dead` | 0 (Minimum) | **1** |
   | `overkilled` | 1 | **2** (1 × 2) |

   Gelingt der Wurf, heilt der verletzte Spieler **eine Stufe Schaden**, und es wird weiter nach der Stufenlogik verfahren.
4. **Scheitern des Sani:** Gelingt dem Sani der Biotech-Wurf nicht, ist der Charakter **tot**.

> ✅ **Beschlossen (30.08.2026):** Lesart **(a)** – Stabilisierungsschwelle bei `dead`. Ein Spieler auf `dead` ist **nicht** unwiderruflich tot; ein Sani kann ihn stabilisieren. Benötigte Sani-Erfolge = Tiefe unter `dead` (0-basiert, min. 1), ab `overkilled` **verdoppelt**. „Permanent tot“ gilt nur noch oberhalb von `overkilled` bzw. bei gescheiterter Rettung (kein Sani im Team oder Biotech-Wurf nicht bestanden).

> 🔶 **Status:** Regeln beschlossen (Freitext + Ergänzung 30.08.2026: Sani-Rettung für `dead`/`overkilled`). Im Code existieren die Stufen (`CharacterStatus`), aber **keine Widerstands-/Biotech-Proben und keine Rettungs-Logik** – `isAlive` (`dead`/`overkilled` = endgültig) müsste für die Sani-Rettung angepasst werden. Bausteine: `PlayerAttribute.resistance` (doppelter Widerstand), **Biotechpool** (nur Sani, ❌ vgl. [Spielerwerte (Würfelpools)](#spielerwerte-würfelpools)), Sani mit Medkit (vgl. [Rollenprofil](#rollenprofil)).

## Events (Viertel-Events)

Wie bereits in `9_TeamManagement.md` angedeutet (anheuerbare NSC, insbesondere der **Fixer**), kann es während eines **Viertels** zu **Events** kommen, die das Spielgeschehen beeinflussen. Es gibt **zwei Auslöser-Arten**:

| Auslöser | Beispiele | Beschreibung |
|---|---|---|
| **Manager-getriggert** | **Shadowrunner** (Sabotage) | Wird von einem Teammanager ausgelöst – z. B. über einen anheuerbaren **Fixer**-NSC (vgl. `9_TeamManagement.md`). |
| **Zufällig** | **Wetter** | Passiert ohne Zutun der Manager, beeinflusst aber das Spiel (z. B. über Sicht, Bewegung oder Würfe). |

- Die **Standardwahrscheinlichkeit** für **zufällige** Events beginnt bei **50 %** und ist durch **noch zu bestimmende Faktoren** beeinflussbar (vgl. Offener Punkt #38).
- **Manager-getriggerte** Events (z. B. Shadowrunner-Sabotage) folgen eigenen Auslösern (Würfelproben der NSC, vgl. `9_TeamManagement.md`) und unterliegen nicht der Zufalls-Wahrscheinlichkeit.

### Eventliste

Die konkrete **Eventliste** ist noch offen – zu jedem Event sind **Auslöser**, **Wirkung** und **Wahrscheinlichkeit** zu definieren (vgl. Offener Punkt #38). Erste Kandidaten aus dem Vorschlag:

| # | Event | Auslöser | Wirkung (Entwurf) |
|---|-------|----------|-------------------|
| 1 | **Shadowrunner-Sabotage** | Manager-getriggert (Fixer) | Sabotageaktionen vor oder während eines Spiels; Einordnung zwischen Verletzungsart „Outside Interference“ ([Strafen & Verstöße](#strafen--verstöße)) und Siegbedingung 3 „Schiedsrichter-Abbruch“ steht aus |
| 2 | **Wetter** | Zufällig (Standardp. 50 %) | Beeinflusst das Spiel dynamisch (z. B. Sicht, Bewegung, Würfe) – konkrete Wirkung offen |
| … | **– weitere –** | – | Noch zu definieren |

> ❌ **Status:** Vorschlag, nicht beschlossen – kein Code. Anknüpfung: `9_TeamManagement.md` (anheuerbare NSC, Fixer), [Strafen & Verstöße](#strafen--verstöße) (Verletzungsart „Outside Interference“), [Siegbedingungen](#siegbedingungen) („Schiedsrichter-Abbruch“).

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
- **Events (Viertel-Events):** Manager-getriggerte (z. B. Shadowrunner via Fixer-NSC) und zufällige (z. B. Wetter) Events pro Viertel; Standardwahrscheinlichkeit 50 % bei zufälligen Events, Eventliste offen – vgl. [Events (Viertel-Events)](#events-viertel-events).
- **Sektor-Sicht / Fog of War:** volle Sicht nur im Sektor mit eigenen Spielern; Sektorennamen für alle sichtbar; Datenmodell (Sektor je Spieler) & Rendering fehlen.
- **Sektorkontrolle & Sektor-Boni:** Kontroll-Mechanismus (Ende eines Spielzugs, nur Spieler eines Teams), Verteidigungs-/Angriffsbonus über Fuzzyset (`lib/fuzzy_logic/`), Malus für Angreifer.
- **Torzonen-Platzierung & -Wahrnehmung:** Auswahl in den Startsektoren, zufällige Platzierung („Automatisch“/keine Wahl), Wahrnehmung per Würfelwurf (`PlayerAttribute.attention`).
- **Siegbedingungen** im Code umsetzen (beschlossen: meiste Punkte → Tiebreaker spielfähige Spieler; Spielfähigkeit/Wipeout; Schiri-Abbruch; beidseitiger Wipeout → Unentschieden).
- **Auszeiten, toter Ball** (Häufigkeiten, Dauer, Konsequenzen).
- **Strafen-Engine** umsetzen: Regelverstoß-Katalog (Strafe je Verstoß), Strafarten (Freeze/Treffer/Abschuss), „Strafverdrahtung“, automatische Niederlage bei Spielabbruch (beschlossen, vgl. Abschnitt [Strafen & Verstöße](#strafen--verstöße)).
- **Positionierung (aufklären/offensiv/defensiv)** als Manager-Entscheidung pro Viertel – inkl. Automatik-Checkbox (bei Spielsuche) und RL-Zeitlimit (15 Min.).
- **Punkte-/Verletzungswurf** (Würfelmechanik) mit Einfluss von Positionierung und Spielerwerten.
- **Verletzungswurf & Tod** umsetzen: Rettungs-Kette (Stabilisierungswurf mit doppeltem Widerstand, Sani-Rettung über Biotechpool mit tiefenabhängigen Erfolgen – ab `overkilled` verdoppelt; permanenter Tod nur oberhalb von `overkilled` bzw. nach gescheiterter Rettung) – vgl. [Verwundung und Tod](#verwundung-und-tod).
- **Würfelsystem implementieren:** vier Würfelpools (Offensiv/Defensiv/Aufklärung/Verstecken), Modifikatoren (Rolle, Persönlichkeit, Ausrüstung, Cyber/Bioware, Positionierung, Verletzungsstufen), Positions-Boni (doppelt/halbiert, inkl. Verstecken-Pool), Bewegungsfaktor (inkl. doppelter Bewegung bei Aufklärungs-Positionierung).
- **Suchen und Finden (Enttarnen):** sektorweise Aufdeckung eines zuvor unter dem [Fog of War](#fog-of-war) liegenden Sektors – Aufklärungs-Wurf der aufdeckenden Gruppe (höchster positionsbezogener Wert) gegen die „Verstecken“-Pools der Gegner, Gegenwurf versteckter Spieler; enttarnte Spieler werden automatisch dem ganzen Team bekannt, versteckte Tokens erscheinen halbtransparent (vgl. [Suchen und Finden](#suchen-und-finden), Offener Punkt #40).
- **Kampfentscheidung & Zielauswahl:** Fuzzyset der 7 Faktoren (Ausgang 1–10) auf Basis von `lib/fuzzy_logic/`, Überwürfeln mit doppeltem Moralwert, Gewichtungsreihenfolge; Zielauswahl-Fuzzyset mit gegnerischem Spieler als Output (Persönlichkeits-Gewichtung, Sani-Schutz).
- **Angriff & Verteidigung:** gegenläufige Würfe (Offensiv-Pool vs. Defensiv-Pool), Verletzungsstufen als Erfolgs-Differenz, Moralprobe (`max. Stufen − aktuelle Stufe`), Ausscheiden beim Aufgeben bzw. ab „Sterbend“.
- **Specials:** Auslöser bei Erfolgs-Differenz > 3 (Angriffs- und Verteidigungsprobe), 2W6-Specialtabelle (2–12), Effekt-Kataloge (Ausrüstung/Rolle/Position 1–3) noch offen.
- **Aktionen-Engine** inkl. Kampfmanöver, Sani-Schutz („nicht angegriffen“), Stürmer-Transport/Motorrad, Ballführungs-Verbot (Sani/Stürmer).
- **Aktions-/Manöver-Auswahl:** Entscheider (Kapitän → höchster positionsbezogener Pool-Wert), Fuzzyset der Einflussfaktoren (Ballbesitz, Persönlichkeit, Moral, Positionsart/-zustand, weitere), Auswahl des wahrscheinlichsten Ausgangs (`FuzzyRuleBase`).
- **Einwechsel-Logik** (beschlossen): Primärrolle zuerst, sonst Sekundärrolle; ungedeckte Rollen bleiben leer (`isRoleFree`-API vorbereitet).
- **Magie/Hacking** (bewusst für die erste Simulation ausgeklammert).

## Offene Punkte

| # | Punkt | Status |
|---|-------|--------|
| 1 | **Siegbedingungen** im Code umsetzen (meiste Punkte → Tiebreaker spielfähige Spieler; Spielfähigkeit/Wipeout; Schiri-Abbruch; beidseitiger Wipeout → Unentschieden) | 🔶 |
| 2 | **Viertel-/Spielzug-Logik** im `ObjectReferee` (4 × 30 Min., 5-Min-Zug, Wechselregeln) | ❌ |
| 3 | **Abstrakte Auflösung:** Punkte-/Verletzungswurf inkl. Positions- und Werte-Einfluss | ❌ |
| 4 | **Positionierung (aufklären/offensiv/defensiv)** inkl. Automatik-Checkbox & RL-Zeitlimit (15 Min.) | ❌ |
| 5 | **Auszeiten, toter Ball** (Häufigkeit/Dauer/Konsequenzen; Strafen-Katalog liegt vor) | ❌ |
| 6 | **Feld-Slot-Mechanismus** (26 Spieler gleichzeitig auf dem Feld) | ❌ |
| 7 | **Aktionen-/Kampfmanöver-Engine** | ❌ |
| 8 | **Sani-Schutz** („darf nicht angegriffen werden“) | ❌ |
| 9 | **Stürmer-Transport / Motorrad-Mechanik** | ❌ |
| 10 | **Zustandsmonitor:** konkrete Wirkung der Status-Stufen auf Würfe | ❌ |
| 11 | **Zeitmodell pro Aktion** (variable Zuglängen) | ❌ |
| 12 | **Ausrüstung → Marktwert/Preis-Formel** | 🔶 |
| 13 | **Magie/Hacking** endgültig beschließen (erste Simulation: weglassen) | 🔶 |
| 14 | **Aufklärungs-Mechanik:** Wie wirkt das Aufklären konkret auf das Auffinden der gegnerischen Torzone (Modifikator auf den Wahrnehmungs-Wurf, vgl. [Torzone (Zielzone)](#torzone-zielzone))? | ❌ |
| 15 | **Automatik-Algorithmus:** Nach welcher Logik werden Positionen/Werte auf aufklären/offensiv/defensiv verteilt? | ❌ |
| 16 | **Schiedsrichter-Abbruch in der Simulation:** Wie wird Siegbedingung 3 (Abbruch bei Übergriff von außen) abgebildet – manueller Admin-/Schiri-Eingriff oder Automatik? | ❌ |
| 17 | **Beidseitiger Wipeout → Unentschieden:** Siegbedingung 4 ist beschlossen. Offen: (a) Soll der beidseitige Wipeout als zusätzlicher (6.) Ausgang der abstrakten Spielzug-Auflösung modelliert werden? (b) Umsetzung im Match-Record: `endMatch`/`recordMatchResult` kennen nur Winner/Loser – `TeamMatchRecord.drawn` existiert bereits | ❌ |
| 18 | **Einwechsel-Logik:** beschlossen (Primär- vor Sekundärrolle; ungedeckte Rolle bleibt leer). Umsetzung folgt mit der Match-Engine/Substitutions-UI auf Basis von `isRoleFree` | ❌ |
| 19 | **Strafen-Engine:** Regelverstoß-Katalog umsetzen – Strafarten (Freeze/Treffer/Abschuss), „Ball tot“, „Strafverdrahtung“ (Mechanik definieren), automatische Niederlage bei Spielabbruch; Protokollierung in der `battle_log` | ❌ |
| 20 | **Verletzungsarten in der Simulation:** Wie werden Unfall / Friendly Fire / Outside Interference / Combat Wound in der abstrakten Auflösung ausgelöst (Wurf-Trigger)? „Friendly Fire“-Behandlung („Shit happens“) fixieren | ❌ |
| 21 | **Fog of War / Sektor-Sicht:** volle Sicht nur im Sektor mit eigenen Spielern; Datenmodell (Sektor je Spieler), Sichtbarkeits-Logik & Rendering offen | ❌ |
| 22 | **Torzonen-Platzierung & -Wahrnehmung:** Auswahl in den Startsektoren (15-Min-Zeitlimit/„Automatisch“), zufällige Platzierung, Wahrnehmung per Würfelwurf (Wahrnehmungspool `attention`) | ❌ |
| 23 | **Würfelsystem (Konzept):** vier Pools (Offensiv=Angriff+Agilität, Defensiv=Verteidigung+Widerstand, Aufklärung=Aufmerksamkeit+Moral, Verstecken=Agilität+Widerstand), Modifikatoren (Rolle, Persönlichkeit, Ausrüstung, Cyber/Bioware, Positionierung, Verletzungsstufen), Positions-Boni (doppelt/halbiert, inkl. Verstecken-Pool) – Umsetzung offen | ❌ |
| 24 | **Bewegungsfaktor:** Formel `(Agilität Basis + Erfolge ≥5 − Modifikatoren) × 5` px/Spielzug; doppelte Bewegung bei Aufklärungs-Positionierung; Pixel-Koordination mit HexGrid (Tilemap-Engine) offen | ❌ |
| 25 | **Sektorkontrolle:** Kontroll-Mechanismus umsetzen (am Ende eines Spielzugs: nur Spieler eines Teams im Sektor) – erst danach greifen die Sektor-Boni | ❌ |
| 26 | **Fuzzyset für Sektor-Boni:** Eingangs-Aggregation (Mittelwert Verteidigungs-/Angriffswert, Kapitäns-Persönlichkeit, Gelände, später PoI/Sektoreffekte) und Ausgangswert (−4 bis +4, „Ideal“–„Miserabel“) auf Basis von `lib/fuzzy_logic/` definieren; Malus für Angreifer in Offensiv-/Defensiv-Pool integrieren | ❌ |
| 27 | **Angriffsbonus (Sektor) – Inkonsistenz:** Fallback der Kapitäns-Persönlichkeit lautet „höchster Verteidigungswert“ – vermutlich Kopierfehler; gemeint ist vermutlich „höchster Angriffswert“ (klären) | ❌ |
| 28 | **Kampfentscheidung:** Fuzzyset der 7 Faktoren (Positionierung, Persönlichkeit, Moral, Wunden, Kapitän, laufender Kampf, Manöver) mit Ausgangswert 1–10; Überwürfeln mit doppeltem Moralwert (exakte Wurfmechanik offen); Gewichtungsreihenfolge fixieren | ❌ |
| 29 | **Zielauswahl:** Fuzzyset mit gegnerischem Spieler als Ausgangswert; Gewichtung nach Persönlichkeit (korreliert mit Moral & Zustand/Wunden); Umgang mit „darf nicht angegriffen werden“ (Sani, ausgeschaltete Spieler, Offizielle) klären | ❌ |
| 30 | **Kampfabwicklung (Angriff & Verteidigung):** gegenläufige Würfe (Offensiv- vs. Defensiv-Pool), Verletzungsstufen = Erfolgs-Differenz, Moralprobe (`max. Stufen − aktuelle Stufen`, Aufgeben bei 0 Erfolgen), Ausscheiden ab `CharacterStatus.dying` – exakte Wurfmechanik/Erfolgszählung offen | ❌ |
| 31 | **Maximale Verletzungsstufen festlegen:** Die Moralprobe referenziert „maximale Anzahl Verletzungsstufen“ – entspricht das der `CharacterStatus`-Stufenleiter (8 Stufen, `fine`→`overkilled`) oder einem eigenen Wert? | ❌ |
| 32 | **Special-Kataloge definieren:** Ausrüstungsspecial 1–3, Rollenspecial 1–3, Positionsspecial 1–3 (Effekte, Dauer, Ziel), Kritischer Treffer (Schaden verdoppelt), „Zweimal würfeln“ bei 12 – inhaltliche Ausgestaltung offen | ❌ |
| 33 | **Special-Auslösung & Balance:** Auslöser Erfolgs-Differenz > 3 bei Angriffs- UND Verteidigungsprobe; 2W6-Verteilung (2 und 12 selten, 7 häufig) berücksichtigen; Rekursion bei wiederholtem 12er-Wurf klären (Rekursionslimit?) | ❌ |
| 34 | **Aktions-/Manöver-Auswahl:** Entscheider-Logik (Kapitän → Spieler mit höchstem positionsbezogenem Pool-Wert), Fuzzyset der Einflussfaktoren (Ballbesitz, Persönlichkeit, Moral, Positionsart/-zustand, weitere offen), Auswahl des wahrscheinlichsten Ausgangs – Umsetzung offen | ❌ |
| 35 | **Auswahl-Faktoren vervollständigen:** „Andere Faktoren (noch zu definieren)“ der Aktions-/Manöver-Auswahl festlegen; Zuordnung „höchster Wert“ je Positionierung präzisieren (Offensiv-/Defensiv-/Aufklärungs-Pool, vgl. Würfelsystem) | ❌ |
| 36 | **Verwundung und Tod – Stufen-Zuordnung (beschlossen 30.08.2026):** Stabilisierungsschwelle = `dead` (Lesart a); ein Spieler bei `dead` ist **nicht** unwiderruflich tot, ein Sani kann ihn stabilisieren – benötigte Biotech-Erfolge = Tiefe unter `dead` (0-basiert, min. 1), ab `overkilled` verdoppelt; permanenter Tod nur oberhalb von `overkilled` bzw. nach gescheiterter Rettung. Restfragen: „doppelter Widerstand“ = `resistance` × 2, Bedingung „Sani im Sektor“ vs. „im Team“ | ✅ |
| 37 | **Sani-Rettung im Code:** `isAlive`/`CharacterStatus` anpassen (da `dead`/`overkilled` nicht mehr endgültig sind, vgl. #36), Widerstands-/Biotech-Proben und Rettungs-Logik implementieren | ❌ |
| 38 | **Events (Viertel-Events):** Eventliste definieren (Event, Auslöser, Wirkung, Wahrscheinlichkeit); beeinflussende Faktoren der Standard-Wahrscheinlichkeit (50 %) festlegen; Zusammenspiel mit `9_TeamManagement.md` (Fixer/Shadowrunner) klären; Einordnung „Outside Interference“ / „Schiedsrichter-Abbruch“ | ❌ |
| 39 | **Verstecken-Pool vs. Heimlichkeitspool:** Verhältnis des neuen Verstecken-Pools (Agilität + Widerstand, vgl. [Würfelsystem](#würfelsystem-konzept)) zum „Heimlichkeitspool“ (Schleichen/Tarnen) des [Werte-Katalogs](#spielerwerte-würfelpools) klären – gleicher Pool (Namens-/Übersetzungsfrage) oder zwei getrennte Pools? | ❌ |
| 40 | **Suchen und Finden umsetzen:** sektorweise Aufdeckung unter dem [Fog of War](#fog-of-war) – wer würfelt (höchster positionsbezogener Aufklärungs-Wert der Gruppe) und wie „Erfolge“ gezählt werden; Gegenwurf versteckter Spieler mit dem Verstecken-Pool; sofortige Teambekanntgabe enttarnter Spieler; halbtransparente/undurchsichtige Tokendarstellung; Zusammenspiel mit der Aufklärer-Sicht in angrenzende Sektoren und dem Datenmodell „Sektor je Spieler“ klären | ❌ |
| 41 | **Verstecken je Positionierung:** Offensiv darf sich nicht verstecken – besteht sein (halber) Verstecken-Pool aus den [Positions-Boni](#positions-boni) dennoch für die [Suchen-und-Finden](#suchen-und-finden)-Enttarnprobe der Gegner fort? Defensiv versteckt sich nur bei „Special/Points of Interest“ – Auslöser/Wirkung präzisieren; Aufklärer „immer versteckt“ – automatischer Gegenwurf bei jeder Aufdeckung unter dem [Fog of War](#fog-of-war) (doppelter Verstecken-Pool)? Zusammenspiel mit „versteckt“-Status und halbtransparenter Tokendarstellung klären | ❌ |
| 42 | **Positions-Boni – Offensiv-Verstecken (Inkonsistenz):** [Positions-Boni](#positions-boni)-Tabelle zeigt „halber Wert“, die 🔶-Änderungsnotiz sagt „bleibt normal“ für den Verstecken-Pool der Offensiv-Positionierung – welcher Wert ist verbindlich? Zusammenspiel mit „Offensiv kann sich nicht verstecken“ (vgl. [Positionen und Aufgaben](#positionen-und-aufgaben)) klären | ❌ |

## Quellen

- `spielablauf/spielablauf.md` – Spielstruktur, Spielfeld, abstrakte Auflösung
- `ausruestung/ausruestung.md` – Waffen, Panzerung, Verbote, Magie
- `spielerhandlungen/spielehandlungen.md` – Aktionen, Kampfmanöver
- `spielerwerte/spielerwerte.md` – Werte-Katalog
- `1_theorie.md` – Bestandsaufnahme Code vs. Anforderungen
- `2do_07_07_26.md` – Sprintvorgaben (Spielstruktur, Spielzug-Dauer, Systemparameter, Output)
- `3_Object_Player.md`, `4_Object_Team.md`, `5_Ausruestung.md` – Modell- und Werte-Dokumentation
- `image2.png` (Scan „Strafen und Verstösse“) – Strafen-Katalog: Regelverstoß → Strafe, Strafarten, Verletzungen
- `lib/fuzzy_logic/` – Fuzzy-Logik-Bibliothek (Fuzzyset-Basis für die Sektor-Boni: `FuzzySet`, `FuzzyVariable`, `FuzzyRuleBase`)
- `data/Shadowrun 4D - Blut & Spiele (Scan).pdf` – Zustandsmonitor-/Todes-Konzept (Grundlage des `CharacterStatus`-Enums und des Abschnitts [Verwundung und Tod](#verwundung-und-tod))

---

*Stand: 03.09.2026*

