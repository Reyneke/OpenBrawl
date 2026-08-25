# Theorie – Grundzüge des OpenBrawl-Regel- und Würfelsystems

Unter Berücksichtigung aller Quellen und Dokumente (inklusive Weblinks und PDFs) sowie des Sourcecodes ist dies der Ort, an dem ein erster Versuch unternommen wird, die Fragen aus dem Dokument "2do_07_07_26.md" zu beantworten und aufzuführen, was wir bereits alles haben und wissen.

---

## Bestandsaufnahme: Code vs. Anforderungen

### 1. Team-Aufstellung (Roster)

| Frage / Anforderung | Status | Details |
|---|---|---|
| **Kaderstärke 20 Spieler** | ✅ Ja | `ObjectTeam.addPlayer()` setzt die Obergrenze **20** (`maxRosterSize`) im Modell durch; `isTeamValid` prüft auf genau **13 aktive Spieler** (`requiredRoster`). |
| **Rollenverteilung dokumentiert** | ✅ Ja | 6 primäre Rollen als `TeamPositions`-Enum: `scout`, `jaeger`, `brecher`, `schuetze`, `stuermer`, `sani` + `inactive`. |
| **Verteilungsschlüssel min/max** | ✅ Ja | Zentral in `ObjectTeam.requiredRoster`: **4 Scout, 4 Jäger, 2 Brecher, 1 Schütze, 1 Stürmer, 1 Sani** = 13 Feldspieler; `isTeamValid` leitet sich generisch daraus ab. |
| **Wieviele gleichzeitig auf dem Feld?** | 🔶 Regel geklärt, Mechanismus offen | Maximal **13 Spieler pro Team** im Feld; Ersatzspieler sitzen auf der Wartebank abseits des Schirms → insgesamt bis zu **26 Spieler** auf dem Feld (Entscheidung in `4_Object_Team.md`). Ein Feld-Slot-Mechanismus fehlt im Code noch. |
| **Ersatzspieler (inactive)** | ✅ Möglich | `inactive`-Status existiert und wird in `isTeamValid` ignoriert → bis zu 7 Ersatzspieler möglich (20 - 13). |

#### Ergänzung aus `doc/plan/spielablauf/spielablauf.md`

Die Diskussion im Dokument definiert die Rollen detaillierter als im Code umgesetzt:

| Rolle (Code) | Rolle (Doku) | Panzerung | Bewaffnung | Besonderheit |
|---|---|---|---|---|
| **Scout** | Scout | Leicht | Persönliche Schusswaffe | – |
| **Banger** | Jäger | Mittelschwer | Persönliche Schusswaffe | – |
| **Heavy** | Brecher | Mittelschwer | Persönliche Schusswaffe + Sturmgewehr/MP/Schrotflinte | – |
| **Blaster** | Schütze | Leicht | Leichtes MG mit Gyrostabilisator | – |
| **Outrider** | Stürmer | Mittelschwer | Persönliche Schusswaffe | Motorrad; kann Spieler (außer Ballträger) transportieren |
| **Medico** | Sani | Schwer | Medkit | Darf weder angreifen noch angegriffen werden |

> **Hinweis:** Die Dokumentation verwendet abweichende Rollennamen (Jäger statt Banger, Brecher statt Heavy, Schütze statt Blaster, Stürmer statt Outrider, Sani statt Medico). Der Code sollte entweder angepasst oder die Doku vereinheitlicht werden.

---

### 2. Spielstruktur

| Anforderung | Status | Details |
|---|---|---|
| **1 Spiel = 4 Viertel** | ❌ Fehlt | Keine Viertel-Logik im Code. |
| **Wechsel nur zwischen Vierteln** | ❌ Fehlt | Nicht umgesetzt. |
| **Auszeiten** | ❌ Fehlt | Nicht implementiert. |
| **Strafen** | ❌ Fehlt | Nicht implementiert. Siehe aber `CharacterStatus` für mögliche Konsequenzen. |
| **Toter Ball** | ❌ Fehlt | Nicht implementiert. |
| **Spielstart / Spielende** | 🔶 Teilweise | `ObjectReferee` kann Match starten (`_createMatch`) und beenden (`endMatch`), aber ohne Viertel-Logik oder Spielregeln. |
| **Siegbedingungen** | ❌ Fehlt | `endMatch` speichert Winner/Loser, aber es ist nicht definiert, *wie* gewonnen wird. |

#### Ergänzung aus `doc/plan/spielablauf/spielablauf.md`

Das Dokument definiert die Spielstruktur bereits sehr detailliert:

- **Spielfeld (Kriegszone):** 3×4 Häuserblocks (231.000–346.800 m²), erst 24h vorher bekannt
- **Torzone:** Kreis mit 4m Durchmesser auf Straßenhöhe, vom besitzenden Team zu Viertelbeginn in einem beliebigen Block der eigenen Hälfte versteckt
- **Ball:** 65–70cm Umfang, 500–600g, Leucht-Plastschaum (gelb/gold) mit Sensoren
- **Punkte:** Ball muss in der gegnerischen Torzone den Boden berühren → beide Teams resetten in eigene Torzone
- **Spielzeit:** 4 Viertel à 30 Minuten
- **Pausen:** 5 Min Reorganisation; nach Vierteln: 10/15/10 Minuten
- **Wechsel & Torverlegung:** Nur zwischen Vierteln erlaubt
- **Spielzug:** Max. 5 Minuten
- **Spielzug-Ende bei:** Punkt, Zeitablauf, Toter Ball (einseitig), Wipeout

**Zeitliche Abstraktion (aus der Diskussion):**
```
1 Kampfrunde = 3 Sekunden
1 Spielzug = max. 5 min = max. 100 Kampfrunden
1 Viertel = 30 min = 600 Kampfrunden
1 Spiel = 2h = 2.400 Kampfrunden
```

> **Wichtiger Diskussionspunkt:** Mit 2.400 Kampfrunden und 26 Spielern wäre ein detailliertes Spiel nicht praktikabel (geschätzte 86+ Stunden Spielzeit). Daher wurde vorgeschlagen, das Spiel **abstrakter** zu halten: Ein Spielzug hat nur 5 mögliche Ausgänge (Team A punktet, Team B punktet, Wipeout A, Wipeout B, Zeitlimit). Der Manager entscheidet vorher über offensive/defensive Ausrichtung, und das Ergebnis wird per Zufall ermittelt (Verletzungs- und Punktwurf, beeinflusst durch Aufstellung und Spielerwerte).

---

### 3. Spielzug-Dauer

| Anforderung | Status | Details |
|---|---|---|
| **Basis-Zugdauer** | ❌ Fehlt | Kein Timer oder Zeit-System im Code. |
| **Variable Zuglängen** | ❌ Fehlt | Nicht implementiert. |
| **Zeitvorgaben je Aktionstyp** | ❌ Fehlt | `battle_log` speichert Aktionen nur als Strings (`action`), ohne Zeitdauer. |

#### Ergänzung aus `doc/plan/spielablauf/spielablauf.md`

- Max. 5 Minuten pro Spielzug (abstrakt, nicht in Echtzeit-Aktionen)
- 100 Kampfrunden pro Spielzug (à 3 Sekunden)
- Aber: Diskussion läuft auf **abstrakte Auflösung** pro Spielzug hinaus (keine Einzelaktionen)

---

### 4. Erwartete Spielleistung / Output

| Anforderung | Status | Details |
|---|---|---|
| **Punkte / Score** | ❌ Fehlt | Nicht implementiert. |
| **Fouls / Strafen** | ❌ Fehlt | Kein Foul-System. |
| **Verletzungen / Ausfälle** | ✅ Grundstruktur | `CharacterStatus`-Enum: `fine`, `reeling`, `hurt`, `afraid`, `injured`, `dying`, `dead`, `overkilled`. Wird in `ObjectPlayer` gespeichert. |
| **Ballbesitz / Toter-Ball-Quote** | ❌ Fehlt | Nicht implementiert. |
| **Individuelle Statistiken** (Tore, Assists, Tackles) | ❌ Fehlt | Keine Statistik-Tracking-Struktur. |
| **Live-Daten vs. Post-Game** | 🔶 Battle-Log vorhanden | `logBattleAction` erfasst Aktionen live per Realtime via Supabase. Aber nur als Text-Log, nicht als strukturierte Statistik. |

---

### 5. Zielvorgabe & Systemparameter

#### 5.1 Verluste, Verletzungen, Tod, Strafen

| Kategorie | Status | Details |
|---|---|---|
| **Häufigkeitsdefinitionen** (leicht/schwer/Tod pro Spiel) | ❌ Fehlt | Keine Richtwerte definiert. |
| **Status-Auswirkungen** | ✅ Enum vorhanden | `CharacterStatus` bietet 8 Zustände, aber ihre *Auswirkungen* aufs Gameplay sind nicht codiert (kein Würfel-/Regelsystem). |

#### 5.2 Toter Ball

| Aspekt | Status |
|---|---|
| **Häufigkeit, Ursachen, Dauer** | ❌ Komplett undefiniert. |

#### 5.3 Variablen & Range-System

| Variable | Status | Details |
|---|---|---|
| **Waffen** (Reichweite, Schaden, Genauigkeit) | ❌ Fehlt | `ObjectPlayer` hat keine Waffen-/Item-Eigenschaften. |
| **Fähigkeiten** (Nahkampf, Fernkampf, Athletik, Wahrnehmung) | ❌ Fehlt | Kein Skills-System. |
| **Umgebung** (Deckung, Licht, Wetter, Gelände) | ❌ Fehlt | Hex-Karte existiert (via `WidgetMapLoader`, `WidgetHexMapRenderer`, `TMXParser`), aber Geländeeffekte sind nicht codiert. |
| **Status-Effekte** (verletzt, erschöpft, gestärkt) | 🔶 Ansatzweise | `CharacterStatus` deckt Verletzungszustände ab, aber keine Buffs/Debuffs. |
| **Range-Beeinflussung** | ❌ Fehlt | Hex-Koordinaten (`hexCol`, `hexRow` in `ObjectToken`) existieren, aber keine Reichweiten-Mechanik. |

#### 5.4 Zielsetzung

> **Zwischenfazit:** Die Parameter sind **noch nicht weit genug definiert**, um ein Würfel-/Regelsystem zu modellieren. Es fehlen:
> - Würfel-Mechanik / Random-Resolver
> - Skill/Wert-System für Spieler
> - Item-/Waffen-System
> - Timing/Zeit-System
> - Siegbedingungen
> - Foul-/Strafen-Katalog

---

## Inventory: Was bereits existiert (vollständig oder im Ansatz)

| Bereich | Status | Beschreibung |
|---|---|---|
| **Team-Management** | ✅ Vollständig | Erstellen, Bearbeiten, Löschen von Teams/Spielern + Supabase-Persistenz. |
| **Character-Markt** | ✅ Vollständig | 40 Charaktere, Realtime-Sync, Zufallsgenerierung. |
| **Auth-System** | ✅ Vollständig | Login/Registrierung via Supabase Auth. |
| **Match-System (Grundgerüst)** | ✅ Vorhanden | 2 Teams matchen, Battle-Log, Match beenden. |
| **Hex-Karte** | ✅ Vorhanden | TMX-Parser, Hex-Map-Renderer, Token-Platzierung (`hexCol`, `hexRow`). |
| **Spieler-Status** | ✅ Vorhanden | 8-stufiges Verletzungssystem (`CharacterStatus`). |
| **Rollen-System** | ✅ Vorhanden | 6 Rollen mit festem Verteilungsschlüssel. |

## Inventory: Was fehlt (komplette Lücken)

| Bereich | Status |
|---|---|
| **Würfel-/Regel-System** | ❌ Komplett |
| **Spielzug-Dauer / Timer** | ❌ Komplett |
| **Viertel-Struktur** | ❌ Komplett |
| **Waffen & Items** | ❌ Komplett |
| **Skills / Attribute** | ❌ Komplett |
| **Umgebungseffekte** (Deckung, Wetter etc.) | ❌ Komplett |
| **Fouls / Strafen** | ❌ Komplett |
| **Punkte / Score / Statistiken** | ❌ Komplett |
| **Siegbedingungen** | ❌ Komplett |
| **Toter Ball** | ❌ Komplett |
| **Auswechslungen** | ❌ Komplett |
| **Auszeiten** | ❌ Komplett |

---

## Ergänzende Informationen aus den Planungsdokumenten (`/doc`)

### Ausrüstung (`doc/plan/ausruestung/ausruestung.md`)

#### Panzerung
- Leicht
- Mittelschwer
- Schwer

#### Waffen
| Kategorie | Beispiele |
|---|---|
| **Persönliche Schusswaffen** | Schwere Pistolen, Revolver, Automatikpistolen, Schrotpistolen (kurzer Lauf) |
| **Sturmgewehre** | – |
| **Maschinenpistolen** | – |
| **Schrotflinten** | – |
| **Schwere Waffen** | Leichtes MG mit Gyrostabilisator |
| **Nahkampf** | Waffenlos, Schlagring, Einhandklinge/-knüppel, Anderthalbhandklinge/-knüppel, Zweihandklinge/-knüppel, Peitsche |

#### Waffenregeln
- Im Feld gefundene Waffen dürfen aufgehoben und verwendet werden
- ⛔ **Verboten:** Monofilamentwaffen, Elektrowaffen, Chemiewaffen, Cyberwaffen
- ✅ **Erlaubt:** Alle Munitionsarten (APDS, panzerbrechend, Ex-Ex)
- ⛔ **Verboten:** Technik-/Magie-Schummelei (z. B. astrale Aufklärung)
- ✅ **Erlaubt:** Cyberware und Bioware (Standard bei Profis)
- ⛔ **Verboten:** Drogen (wird aber oft ignoriert)

#### Typische Bodytech (Cyberware/Bioware)
Reflexbeschleuniger, Kunstmuskeln, Orthoskin, Knochenverstärkung, Trombozytenfabrik, Reflexrecorder, Cyberaugen, Cyberohren, Smartlink, Datenbuchse, Cybergliedmaßen

#### Typische Adeptenkräfte
Verbesserte Attribute, verbesserte Reflexe, Kampfsinn, magische Panzerung, verbesserte Fertigkeit, Wandlaufen

#### Magieregeln
- ✅ **Erlaubt:** Adeptenkräfte, magische Heilung durch Sanis, indirekte Kampfmagie
- ⛔ **Verboten:** direkte Kampfmagie, Illusions- und Beherrschungszauber, alle Arten von Foki

---

### Spielerwerte (`doc/plan/spielerwerte/spielerwerte.md`)

Das Dokument definiert die folgenden Werte, die ein Spieler haben sollte:

| Wert | Beschreibung | Im Code? |
|---|---|---|
| **Panzerung** | Rüstungsklasse | ❌ |
| **Zustandsmonitor** | Verletzungs-Tracking (analog zu `CharacterStatus`) | 🔶 Ansatzweise |
| **Initiative** | Reaktionsgeschwindigkeit | ❌ |
| **Haupt- und Nebenhandlungen** | Aktionen pro Runde | ❌ |
| **Verteidigungspool** | Würfelpool für Verteidigung | ❌ |
| **Schadenswiderstandspool** | Würfelpool für Schadensresistenz | ❌ |
| **Nahkampfangriffspool** | Würfelpool für Nahkampf | ❌ |
| **Fernkampfangriffspool** | Würfelpool für Fernkampf | ❌ |
| **Athletikpool** | Bewegung, Klettern, Springen (alle außer Stürmer) | ❌ |
| **Steuernpool** | Fahrzeugsteuerung (nur Stürmer) | ❌ |
| **Wahrnehmungspool** | Entdecken, Aufklären | ❌ |
| **Heimlichkeitspool** | Schleichen, Tarnen | ❌ |
| **Edge** | Glück / Schicksalspunkte | ❌ |
| **Einfluss** | Führung / Taktik kleinerer Einheiten | ❌ |
| **Biotechpool** | Medizinische Versorgung (nur Sani) | ❌ |
| **Moral** | Kampfmoral | ❌ |
| **Ruf/Fame** | Bekanntheitsgrad | ❌ |
| **Marktwert** | Wert auf dem Spielermarkt | 🔶 `ObjectPlayer.price` (3000 Standard) |

> **Hinweis:** Die Werte sind als **Würfelpools** konzipiert (Shadowrun-typisch). Keiner dieser Werte ist bisher im Code implementiert. `ObjectPlayer` hat nur `price` als numerischen Wert.

---

### Spielerhandlungen (`doc/plan/spielerhandlungen/spielehandlungen.md`)

#### Mögliche Aktionen (pro Rolle)
| Aktion | Ausführende |
|---|---|
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

#### Kampfmanöver (Taktik kleinerer Einheiten)
Dynamisches Eindringen, Feuerwalze, Flankieren, Gedeckte Aufklärung, Kreuzfeuer, Rautenformation, Rudelangriff, Schilde vor!, Überschlagender Rückzug, Überschlagendes Vorgehen, Unterstützungsfeuer

> **Diskussion:** Hacking und Magie sollen erstmal weggelassen werden. Die Kampfmanöver wurden als "witzige Idee" für Gruppenaktionen bewertet.

---

### Supabase-Setup (`doc/setup/supabase.md`)

- **Projekt-ID:** `rcjxeoaqvvamxkflplrx`
- **Profiles-Tabelle** mit: `id`, `updated_at`, `username`, `full_name`, `avatar_url`, `website`, `isEnabled`, `soullight`
- **Login-Flow:** Nach Login wird `isEnabled` geprüft → bei `false` wird der User ausgeloggt mit Warnung
- **Username-Pflicht:** Bei leerem Username → Weiterleitung zum Profil-Editor

---

## Nächste Schritte (Priorität)

Basierend auf der Abhängigkeiten-Reihenfolge aus `2do_07_07_26.md`:

1. ✅ **Team-Aufstellung** – Fertig implementiert. Aber: Rollennamen in Doku und Code weichen voneinander ab (Scout/Jäger/Brecher vs. Scout/Banger/Heavy).
2. 🔲 **Spielstruktur** – Viertel, Wechselregeln, Auszeiten, Strafen, Toter Ball, Siegbedingungen definieren. Die Doku in `spielablauf.md` liefert bereits detaillierte Vorgaben (Kriegszone, Torzone, Ball, 4×30 Min, 5-Min-Spielzüge).
3. 🔲 **Spielzug-Dauer** – Zeitliche Grundlage für Aktionen schaffen. Diskussion tendiert zu **abstrakter Auflösung** pro Spielzug (5 mögliche Ergebnisse) statt Einzelaktionen.
4. 🔲 **Systemparameter** – Variablen-Katalog, Range-System, Würfel-Mechanik entwerfen. Die Dokumente liefern bereits:
   - **Ausrüstungskatalog** (Waffen, Panzerung, Cyberware, Magie)
   - **Spielerwerte-Katalog** (18 Werte als Würfelpools)
   - **Aktionen-Katalog** (18 Aktionen + 12 Kampfmanöver)
5. 🔲 **Output-Erwartung** – Statistiken und Live-Daten modellieren.

**Empfehlung:** Bevor mit der Implementierung begonnen wird, sollten die Rollennamen vereinheitlicht werden (Code oder Doku). Das Würfel-/Regel-System sollte auf Basis der vorhandenen Pools und Aktionen als abstraktes System modelliert werden (angelehnt an die Diskussion in `spielablauf.md`).

---


*Stand der Analyse: 08.07.2026*