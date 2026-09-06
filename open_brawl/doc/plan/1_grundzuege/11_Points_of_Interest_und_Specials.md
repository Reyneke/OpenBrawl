# Points of Interest & Special-Kataloge (Spezifikation)

> **Zweck:** Dieses Dokument ist die **normative Spezifikation** zu den Abschnitten *„Points of Interest (Sektor)“* und *„Specials“* in `6_Die Regeln des Spiels.md` (im Folgenden „§6“). §6 bleibt die zentrale Referenz der Spielregeln; hier wird festgeschrieben, **wie** die dort geführten PoI-Effekte und Special-Kataloge (Offene Punkte #32/#33) zu lesen, aufzuschlüsseln und an die Mechaniken (Würfelpools, Sektor-Boni, Strafen, Ruhm) anzubinden sind. Es enthält außerdem den **Review-Log** der beim Cleanup gefundenen Inkonsistenzen und Querverweis-Probleme.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen/Entwurf, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

> **Verhältnis zu §6:** Die PoI-Liste (Standorttyp + Zeile/1. W10) und der **Dach-Zustand** je PoI (Spalte „Aktivierung (Sektorkontrolle)“) sind in §6 verbindlich gepflegt. Dieses Dokument ergänzt die **Teil-Effekt-Aufschlüsselung**, die **Sektor-Bonus-Einbindung**, die **Special-Kataloge** und die **Begriffsklärung** und listet offene Abhängigkeiten.

> **Querverweise:** Abschnitts-Links der Form `[…](#…)` ohne Dateipräfix (z. B. `[Sektorkontrolle](#sektorkontrolle)`), auch als „§6 […](#…)“ formuliert, verweisen auf die gleichnamigen Abschnitte in `6_Die Regeln des Spiels.md`. Verweise auf Modell-Dokumente (`3_Object_Player.md`, `7_Referees.md`, …) sind als solche benannt.

---

## 1. Begriffsklärung (normativ)

Damit PoI-Effekte und Specials einheitlich gelesen werden können, gelten folgende Begriffe **verbindlich**.

### 1.1 Aktivierung vs. Wirkungs-Radius vs. Begünstigte

Die drei Aktivierungs-Zustände aus §6 beschreiben allein, **ob/wann** eine Umgebungswirkung aktiv ist. Sie werden um zwei orthogonale Achsen ergänzt:

| Begriff | Bedeutung | Ausprägungen |
|---|---|---|
| **Aktivierung (Dach-Zustand)** | Abhängigkeit von der [Sektorkontrolle](#sektorkontrolle); steht in der §6-Spalte | **Nur bei Kontrolle** · **Immer aktiv** · **Nur unkontrolliert** |
| **Wirkungs-Radius** | Wie weit der Effekt greift | **im Sektor** (Standard) · **alle Sektoren** (team-global) · **sektorunabhängig** (nur an Kontrolle gebunden) · **Match-global** (bis Spielende) |
| **Begünstigte / Betroffene** | Auf wen der Effekt wirkt | **eigenes (kontrollierendes) Team** · **beide Teams** · **Umgebung/neutral** · **einzelner Spieler** (freiwillig) · **NPC-Gegner** (Drohnen, Ghule, …) |

> **Lesart:** Ein PoI mit Dach-Zustand **„Immer aktiv“** kann **zusätzlich** Teil-Effekte enthalten, deren **Begünstigte** das kontrollierende Team sind (z. B. Umgebungs-Gefahr **plus** Vorteil bei Kontrolle). Der Dach-Zustand klassifiziert nur die Umgebungswirkung; Teil-Effekte werden **je Effekt** gegated (vgl. §6-Hinweis „Dach-Zustand & Teil-Effekte“). Solche PoIs sind in Abschnitt 4 je Teil-Effekt aufgeschlüsselt.

### 1.2 Bonus-/Malus-Schreibweise „nW6 auf X“

Die Effekt-Texte in §6 verwenden „nW6 Bonus auf Attribut/Pool“ uneinheitlich. Verbindlich gilt:

- **„nW6 Bonus auf Probe X“** = **zusätzliche Würfel** auf den Würfelpool der Probe X (keine Attributpunkte). Erfolgszählung wie im [Würfelsystem](#würfelsystem-konzept) (Würfel ≥ 5 = Erfolg).
- **„nW6 Bonus auf Attribut A“** (z. B. „Aufmerksamkeit“) = +n Würfel auf Würfe, die **dieses Attribut** als Grundlage nutzen. Die betroffenen Pools folgen dem Würfelsystem (Angriff+Agilität → offensiv; Verteidigung+Widerstand → defensiv; Aufmerksamkeit+Moral → Aufklärung; Agilität+Widerstand → Verstecken).
- **„Bonus auf Angriffs-/Verteidigungsproben“** wirkt auf den **Offensiv- bzw. Defensiv-Pool**.
- **„Versteckengrundwerte werden verdoppelt“** (PoI „Elevated Rail“) = der **Verstecken-Pool** wird verdoppelt (analog dem doppelten Pool der Aufklärer-Positionierung), nicht die Positionierungs-Modifikatoren.

> 🔶 **Stand:** Schreibweise vereinheitlicht (Dach-Entwurf). Die genaue Erfolgszählung und der Umgang mit attributgebundenen Boni sind mit der Würfelpool-Engine abzustimmen (§6 Offener Punkt #23).

### 1.3 „Fertigkeit Erste Hilfe“ & „Reparatur“

- Eine allgemeine Fertigkeit **„Erste Hilfe“** für Nicht-Sanis ist **nicht definiert** (nur „Biotech“ als Sani-Aktion existiert, §6 Aktionen-Katalog). Der PoI „Pharmacy“ setzt eine solche **allgemeine** Erste-Hilfe-Fähigkeit voraus (❌ neu, siehe 6.1).
- **„Reparatur“** (PoI „Auto or Robotics Repair“) ist als **Ausrüstungs-Aktion** nicht im Aktionen-Katalog; Mechanik offen (❌, siehe 6.1).

### 1.4 „Sachbeschädigung“ / „Geldstrafe“ / „Strafe nach dem Spiel“

- Der Strafen-Katalog (§6) kennt nur die Strafarten **Freeze / Treffer / Abschuss** und Verstoß-Konsequenzen (Ball tot, Spielverlust, Niederlage). Eine **„Sachbeschädigung“** (Property-Damage) bzw. **Geldstrafe fürs Team** ist dort **nicht** vorgesehen.
- Lesart für dieses Dokument: „Strafe wegen Sachbeschädigung / Geldstrafe“ ist eine **vermögensrechtliche Konsequenz** (Kosten bzw. Geldstrafe fürs Team), **keine** der drei Bewegungs-Strafarten. Sie braucht eine eigene Mechanik **außerhalb** der Strafarten-Tabelle (❌, siehe 6.2). Bis dahin wird der Effekt-Text wörtlich geführt, ohne Übersetzung ins Modell.

### 1.5 „Ruhm-Bonus“ / „erhöhter Gewinn von Ruhm“

- „Ruhm“ (`fame`) ist im Modell **karriereweit** (`won − lost` + `specialPlayFame`), nicht match-intern. PoIs mit „Bonus auf erhaltenen/erzielten Ruhm“ bzw. „um X % erhöhtem Gewinn von Ruhm“ brauchen eine **match-interne Ruhm-Menge**, die am Ende dem `specialPlayFame` der Spieler (und der Schiedsrichter-NPCs, vgl. `7_Referees.md`) zugeschlagen wird (❌, siehe 6.4).
- „Um X % erhöhter Gewinn von Ruhm“ ist **relativ** zum im Match verdienten Ruhm zu rechnen; „Bonus auf erhaltenen Ruhm“ (absolut/relativ) ist noch zu präzisieren (❌, siehe 6.4).

### 1.6 Begegnungs-NPCs (Ghule, Drohnen, Mob, Fans, Cyberzombie, Wildtiere, Sicherheits-KI)

Diese kommen in vielen PoIs vor, sind aber **nirgends** als NPC/Typ definiert (kein `ObjectNpc`, keine Begegnungs-Mechanik). Sie gehören zu den Begegnungs-/Events-Bausteinen (❌, siehe 6.5). In diesem Dokument werden sie nur referenziert, **nicht** neu definiert.

---

## 2. Review-Log (Befunde & Empfehlungen)

Beim Cleanup von §6 (PoI-Tabelle) und im Abgleich mit den anderen Dokumenten gefundene Punkte. „Ort“ = wo; „Empfehlung“ = vorgeschlagene Auflösung; „Owner“ = zuständiges Dokument/Baustein.

| # | Befund | Ort | Empfehlung | Owner | Status |
|---|---|---|---|---|---|
| R1 | Erzeugungsregel widersprüchlich: „1w3 PoI“ vs. „Korrektur 75 %/genau einer“ | §6 PoI-Einleitung | **Erledigt:** Text auf „75 % kein PoI, sonst genau einer“ vereinheitlicht | §6 | ✅ |
| R2 | Aktivierungsspalte nutzt Nicht-Kanon-Werte (`Kontrolliert`/`Immer`/`kontrolliert`) | §6 PoI-Tabelle | **Erledigt:** auf „Nur bei Kontrolle“ / „Immer aktiv“ normalisiert; „Nur unkontrolliert“ bleibt reserviert (aktuell kein rein unkontrollierter PoI) | §6 | ✅ |
| R3 | „Immer aktiv“-PoIs mit **kontrolliert-gebundenen Teil-Effekten** widersprechen der Zustands-Definition („unabhängig von der Sektorkontrolle“) | §6 (Police, Department Store, Industrial, VRcade, Apartment Block, Courier, Suburban, Antiques, Fashion Boutique, Mall) | Dach-Zustand = Umgebungswirkung; Teil-Effekte **je Effekt** gegaten (vgl. Abschnitt 4) | 11 (Abs. 4) | 🔶 |
| R4 | „nW6 Bonus auf Attribut/Pool“ uneinheitlich (1w6/1W6/2w6/„Verteidungs-“/„Versteckenproben“) | §6 PoI-Tabelle | **Erledigt (Text):** Großschreibung `nW6`, Bindestrich-Schreibweisen vereinheitlicht; Bedeutung normativ in 1.2 | §6 | ✅ |
| R5 | Fertigkeit **„Erste Hilfe“** (allgemein) & Aktion **„Reparatur“** existieren nicht (nur Biotech/Sani) | §6 PoI „Pharmacy“, „Auto or Robotics Repair“; Aktionen-Katalog | Neue allgemeine Erste-Hilfe-/Reparatur-Mechanik definieren oder Effekte umformulieren | Aktionen-Engine (6.1) | ❌ |
| R6 | **„Sachbeschädigung/Geldstrafe“** ist keine der Strafarten Freeze/Treffer/Abschuss | §6 Strafen-Katalog vs. viele PoIs | Vermögensrechtliche Folge als eigene Mechanik einführen (6.2) | Strafen-Engine (6.2) | ❌ |
| R7 | **Match-interner Ruhm** fehlt; PoI-Ruhm-Boni haben keine Senke | §6 PoIs (Data Storage, New Media, Nightclub, Movie Theatre, Fans…) vs. `3_Object_Player.md` | Match-Ruhm → `specialPlayFame`-Zuschlag; Schiris analog (`7_Referees.md`) | Karriere-/Ruhm-Modell (6.4) | ❌ |
| R8 | Begegnungs-NPCs (Ghule, Drohnen, Mob, Fans, Cyberzombie, Wildtiere, Sicherheits-KI) **undefiniert** | viele §6-PoIs | NPC-/Begegnungs-Baustein definieren; hier nur referenziert | Begegnungen/Events (6.5) | ❌ |
| R9 | „Haus der Heilung“ (Religious Building) stabilisiert „Sterbend **oder tiefer**“ – kollidiert mit Stabilisierungsschwelle `dead` (Beschluss 30.08.2026) | §6 PoI „Religious Building“ vs. [Verwundung und Tod](#verwundung-und-tod) | Wortlaut an Rettungs-Kette angleichen: „Sterbend“ = `dying` (ausgeschieden, heilbar), eigentliche Stabilisierung nur ab `dead`; „tote werden belebt“ als Sonder-Regel der Zuflucht präzisieren | 11 (Abs. 4) | 🔶 |
| R10 | „Hospital or Clinic“ bündelt „Pharmacy“ + „Religious Building“ – welche Teil-Effekte übertragen sich (auch Cyberzombie-Hazard/Persönlichkeitswechsel)? | §6 PoI „Hospital or Clinic“ | Nur Heilungs-/Stabilisierungsanteile übertragen, nicht „Zuflucht“/Cyberzombie; explizit machen | 11 (Abs. 4) | 🔶 |
| R11 | Wirkungs-Radius-Wörter uneinheitlich („sektorunabhängig“, „in allen Sektoren“) | §6 PoIs (Police-Stash, New Media, Department Store, Fashion…) | Über die neue Achse **Wirkungs-Radius** (1.1) vereinheitlichen; je PoI festhalten | 11 (Abs. 4) | 🔶 |
| R12 | „School or College“: auf wen wirkt der Attribut-Bonus? (Text war grammatisch verstellt) | §6 PoI „School or College“ | Lesart: ein **zufälliger** Spieler des sektorkontrollierenden Teams; präzisieren | 11 (Abs. 4) | ❌ |
| R13 | Taxi-Formel kryptisch („75% **plus** Aufmerksamkeit der Schiedsrichter Chance“) | §6 PoI „Taxi Firm“ | Formel sauber fassen (Prozentwert + Schiri-`attention`), Entdeckung vs. Strafe trennen | Strafen-Engine (6.2) | ❌ |
| R14 | „Bar“: „25% − Wert in Widerstand Chance“ kryptisch | §6 PoI „Bar“ | Widerstand gegen Alkoholwirkung als `Widerstand`-Probe formulieren | Kampf-/Zustands-Engine | ❌ |
| R15 | „Commercial Cybernetics“: „25 % Abzug auf Einbauten von Cyberware … für alle Spieler“ – Vorteil/Nutzer unklar | §6 PoI „Commercial Cybernetics“ | Begünstigte (kontrollierendes Team?) und Zeitpunkt (während/nach Viertel) klären | 11 (Abs. 4) | ❌ |
| R16 | „Elevated Rail“: „Aufklärer völlig unauffindbar“ greift in [Suchen und Finden](#suchen-und-finden)/Verstecken-Logik (#40/#41) ein | §6 PoI „Elevated Rail“ | Zusammenspiel mit Aufklärer-Immunität & Positions-Boni festlegen | 11 / §6 (#40/#41) | ❌ |

> 🔶 **Stand:** R1/R2/R4 sind im §6-Text bereits umgesetzt. R3, R9–R11 werden in Abschnitt 4 je Teil-Effekt verbindlich zugeordnet; R5–R8, R12–R16 sind Querabhängigkeiten in eigene Bausteine (siehe Abschnitt 6).

---

## 3. Special-Kataloge & Auslöse-Regeln (Offene Punkte #32/#33)

### 3.1 Auslöser (verbindlich)

Ein **Special** tritt in Kraft, wenn eine **Angriffs-** **oder** **Verteidigungsprobe** um **mehr als drei Erfolge** über die Gegenprobe gewinnt (Erfolgs-Differenz **> 3**). Der Auslöser ist **symmetrisch** (Angreifer wie Verteidiger; beide Würfe laufen zeitgleich, vgl. [Angriff und Verteidigung](#angriff-und-verteidigung)).

- Die **aktive Partei** = jene, die die Probe mit Differenz > 3 gewinnt; sie erhält das Special.
- **„Specials können auch passieren, wenn einer aus der Gegenseite patzt.“** Als **Patzer (Fumble)** gilt ein Wurf, bei dem **mehr als die Hälfte der Würfel Einsen** zeigt (Definition analog der Stress-/Sicherheits-Mechanik in `8_Persoenlichkeiten.md`). Erzielt eine Partei einen Patzer **und** verliert die Probe, kann die Gegenpartei ein **zusätzliches** Special auslösen (zusätzlich zum normalen Auslöser, ohne die Differenz > 3 zu erfüllen). Patzer + Differenz > 3 lösen **ein** Special aus (kein Doppelauslöser).

### 3.2 Der 2W6-Wurf

Die Auswahl erfolgt mit **2W6** über die Tabelle in §6 (2–12). Verbindlich:

- **2 = Kritischer Treffer** – erlittene Verletzungsstufen (aus der Erfolgs-Differenz) werden **verdoppelt**.
- **12 = „Zweimal würfeln“** – es werden **zwei weitere** Ausgänge bestimmt (je 2W6). Ergibt einer davon erneut eine 12, wird **einmal** nachgewürfelt (Rekursionslimit **1**); ergibt die Nachverwürfelung erneut eine 12, zählt sie als **7** (Rollenspecial 2). Insgesamt entstehen so maximal **drei** Ausgänge.
- Die übrigen Felder (3–11) greifen auf die Kataloge unten (Ausrüstung 1–3 / Rolle 1–3 / Position 1–3).

### 3.3 Kategorien-Semantik

Die **aktive Partei** löst ein Special ihrer Kategorie aus:

- **Ausrüstungsspecial** – wirkt über die **Ausrüstung** (Waffe/Panzerung) der aktiven Partei bzw. des Verlierers.
- **Rollenspecial** – hängt an der **Rolle** (Scout, Jäger, Brecher, Schütze, Stürmer, Sani) der aktiven Partei.
- **Positionsspecial** – hängt an der **Positionierung** (offensiv / defensiv / aufklären, §6 [Positionen und Aufgaben](#positionen-und-aufgaben)) der aktiven Partei.

### 3.4 Kataloge (Entwurf 🔶 – zur Ratifikation)

**Ausrüstungsspecial** (wirkt auf Waffe/Panzerung):

| # | Name | Effekt | Ziel / Dauer |
|---|---|---|---|
| 1 | **Gezielter Treffer** | Panzerung des Verlierers wird bei der Schadensabrechnung dieses Ausgangs **ignoriert** | Verlierer / einmalig |
| 2 | **Munition durchgeladen** | Die **nächste** Angriffsprobe der aktiven Partei im Spielzug erhält **+2W6** | aktiv Partei / 1 Spielzug |
| 3 | **Ausrüstung beschädigt** | Das teuerste Ausrüstungsstück (Waffe/Panzerung) des Verlierers ist bis Viertelende **ohne Wirkung** | Verlierer / 1 Viertel |

**Rollenspecial** (abhängig von der Rolle der aktiven Partei):

| # | Name | Effekt | Ziel / Dauer |
|---|---|---|---|
| 1 | **Eingespielt** (Jäger/Brecher) | **+1W6** auf die nächste Probe im selben Spielzug; bei Sani: statt dessen +1 Heilung | aktiv Partei / 1 Spielzug |
| 2 | **Überlegenes Manöver** (Schütze/Stürmer) | Bewegungsfaktor des Verlierers halbiert für den Spielzug; Gegner gilt 1 Spielzug als „aufgedeckt“ (kein Verstecken-Bonus) | Verlierer / 1 Spielzug |
| 3 | **Schutzengel** (Sani) / **Kampfeslust** (sonst) | Sani: Verlierer auf `dying` wird sofort um 1 Stufe stabilisiert; sonst: Moralprobe des Verlierers +2W6 erschwert | abhängig / einmalig |

**Positionsspecial** (abhängig von der Positionierung der aktiven Partei):

| # | Name | Effekt | Ziel / Dauer |
|---|---|---|---|
| 1 | **Schwung** (offensiv) | Verlierer verliert den **Ballbesitz**; der Ball ist 1 Spielzug „frei“ | Spielzustand / 1 Spielzug |
| 2 | **Bollwerk** (defensiv) | +2W6 auf den **Defensiv-Pool** der aktiven Partei im Sektor bis Spielzugende | aktiv Partei (Sektor) / 1 Spielzug |
| 3 | **Aus dem Nichts** (aufklären) | Aktive Partei gilt bis Spielzugende als **versteckt** und darf unentdeckt agieren (vgl. [Suchen und Finden](#suchen-und-finden)) | aktiv Partei / 1 Spielzug |

> 🔶 **Stand:** Auslöser (3.1), 2W6-Wurf inkl. Rekursionslimit (3.2) und Kategorie-Semantik (3.3) sind als Dach beschlossen. Die konkreten Katalog-Inhalte (3.4) sind **Entwürfe zur Ratifikation** – Effekte/Dauer/Ziel sind mit den Rollen- und Ausrüstungs-Katalogen abzustimmen, bevor sie in §6 zurückgespielt und die Offenen Punkte #32/#33 geschlossen werden.

---

## 4. PoI-Spezifikation & Teil-Effekt-Zuordnung

Die **Dach-Zustände** je PoI stehen verbindlich in der §6-Tabelle. Dieser Abschnitt legt für die **gemischten** PoIs fest, welcher Teil-Effekt wann greift (Aktivierung), wie weit er wirkt (Radius) und wen er begünstigt/betrifft.

### 4.1 Klassifikation der Dach-Zustände

- **Rein „Nur bei Kontrolle“** (gesamter Effekt ist Vorteil des kontrollierenden Teams, Radius im Sektor, sofern nicht anders im Effekttext): Pharmacy, Consumer Electronics, Auto or Robotics Repair, Capsule Hotel, Grocery Store, School or College, Public Transport Hub, Hospital or Clinic, Body Augmentation Clinic, Luxury Apartments, New Media Company, Security Tech, Vehicle Showroom, Commercial Cybernetics, Gym, Underpass, Ripperdoc, 3D Print Fabrication, Restaurant, Coffee Shop, Taxi Firm, Weapons Tech or Sales, Bank.
  - Davon mit **team-globalem / abweichendem Radius** (aus dem Effekttext): New Media Company (alle Sektoren), Department-Store-Angriffsbonus (alle Sektoren), Police-Stash (sektorunabhängig) – siehe unten.
- **Rein „Immer aktiv“** (Umgebungswirkung ohne kontrollierendes Teil-Effekt): Art Dealer, Legal Firm, Data Storage, Low Rent Housing, Elevated Rail, Fast Food, Government Building, Garage, Office Block, Hotel, Pop-Up Market, Movie Theatre, Pocket Park, Multi-Level Car Park, Bar.
- **Gemischt (Dach „Immer aktiv“ + kontrollierte Teil-Effekte)** → siehe 4.2: Storage Units, Religious Building, Police Precinct, Department Store, Industrial, Fashion Boutique*, Mall, VRcade, Apartment Block, Courier, Suburban Housing, Antiques.

> \* **Fashion Boutique** trägt aktuell den Dach-Zustand „Immer aktiv“, sein einziger Effekt (Verstecken-Bonus) ist jedoch ein Vorteil des kontrollierenden Teams. Empfehlung (Review R11): Dach-Zustand zu „Nur bei Kontrolle“ ändern – offen zur Bestätigung (❌).

### 4.2 Teil-Effekt-Zuordnung (gemischte PoIs)

| 1. W10 | PoI | Teil-Effekt | Aktivierung (Teil) | Radius | Betroffene / Begünstigte |
|---|---|---|---|---|---|
| 1 | Storage Units | „Unerwartete Mieter“ (Ghule) | **Nur unkontrolliert** | im Sektor | NPC (Ghule) vs. Anwesende |
| 1 | Storage Units | „Spontane Autogrammstunde“ (Fans → Ruhm) | **Nur unkontrolliert** | im Sektor | beide Teams + Schiris |
| 1 | Storage Units | „Hide and Seek“ (1W6 Verstecken) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |
| 2 | Religious Building | „Zuflucht“ (Strafe bei Angriff auf Liegende) | Immer aktiv | im Sektor | beide (Angreifer = Regelverstoß) |
| 2 | Religious Building | „Haus der Heilung“ (Stabilisierung/Belebung) | Immer aktiv | im Sektor | beide (Verletzte/Tote) |
| 2 | Religious Building | Cyberzombie (10 % bei Kampf) | Immer aktiv | im Sektor (bleibt lokal) | NPC vs. alle Kämpfenden |
| 3 | Police Precinct | „Der lange Arm des Gesetzes“ | Immer aktiv | im Sektor | beide (Kämpfende) |
| 3 | Police Precinct | „Der geheime Stash“ (2W6 Kämpfe) | **Nur bei Kontrolle** | **sektorunabhängig** | kontrollierendes Team |
| 4 | Department Store | Mitarbeiter (Kettensäge + Schrotflinte) | Immer aktiv | im Sektor | NPC vs. Kämpfende |
| 4 | Department Store | „Sportartikelabteilung“ (1W6 Angriff) | **Nur bei Kontrolle** | **alle Sektoren** | kontrollierendes Team |
| 5 | Industrial | „Eine enge Sache“ (2W6 Malus Angriff) | Immer aktiv | im Sektor | alle Kämpfenden |
| 5 | Industrial | „Wer ist Osha?“ (Maschinen-Verletzung) | Immer aktiv | im Sektor | Umgebung / Anwesende |
| 5 | Industrial | „Hast du das gesehen?“ (Ruhm +25 %) | **Nur bei Kontrolle** | **team-global** | kontrollierendes Team |
| 5 | Industrial | „Fehlfunktion“ (Sektoreffekt, 75 %) | Immer aktiv | im Sektor | Umgebung |
| 6 | VRcade | „Spiegelkabinett“ (Verteid./Verstecken 2W6) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |
| 6 | VRcade | „Sicherheitsprotokolle Offline“ (Drohnen) | Immer aktiv | im Sektor | NPC vs. alle; bei Kontrolle vs. gegnerisches Team |
| 6 | VRcade | „Nur noch eine Runde“ (Zocken) | Immer aktiv | im Sektor | beide Teams |
| 6 | Mall | „Ich sagte: Nicht rennen!“ (Sicherheitsdrohnen) | Immer aktiv | im Sektor | NPC vs. alle im Sektor |
| 6 | Mall | „Spätkauf“ (Ghule / Fans) | Immer aktiv | im Sektor | NPC vs. Anwesende / beide (Fans→Ruhm) |
| 7 | Apartment Block | Begegnung Ghule / Fans (50 %) | **Nur unkontrolliert** | im Sektor | NPC vs. Anwesende / beide (Fans→Ruhm) |
| 7 | Apartment Block | Verteidigungs-Bonus (statt Verstecken) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |
| 8 | Courier | „Fran Jatzek was here“ (Versenden) | Immer aktiv | zufälliger Sektor | Anwesende beider Teams |
| 8 | Courier | „Packetpost“ (als Paket → versteckt) | **Nur bei Kontrolle** | Zielsektor | kontrollierendes Team |
| 10 | Suburban Housing | „Ups!“ / „Knights of Suburbia“ (Drohnen) | Immer aktiv | im Sektor | NPC vs. Anwesende |
| 10 | Suburban Housing | „Ich identifiziere mich als Briefkasten“ (1W6 Verstecken) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |
| 10 | Suburban Housing | „Eingegraben“ (2W6 Verteidigung) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |
| 10 | Antiques | „Sicherheitsnetzwerk“ (Drohnen) | Immer aktiv | im Sektor | NPC vs. Kämpfende |
| 10 | Antiques | „Wo gehobelt wird, fallen Späne“ (Sachbeschädigung) | Immer aktiv | im Sektor | Umgebung |
| 10 | Antiques | „Garantiert echt“ (1W6 Verteidigung) | **Nur bei Kontrolle** | im Sektor | kontrollierendes Team |

**Erläuterungen (Review R9/R10):**

- **Religious Building – „Haus der Heilung“:** Der Effekttext nennt „Sterbend oder tiefer“. Nach der Rettungs-Kette (§6 [Verwundung und Tod](#verwundung-und-tod), Stabilisierungsschwelle `dead`) wird **normativ** gelesen: Er hilft `dying`-Spielern (Heilung/Stabilisierung wie Sani) und kann ab `dead` die [Rettungs-Kette](#rettungs-kette-stabilisierung) unterstützen; „Eigentlich tote … 75 % Persönlichkeitswechsel“ betrifft eine **Belebung** oberhalb der Rettungs-Kette (Sonderregel der Zuflucht, separat zu klären ❌).
- **Hospital or Clinic:** Vereint nur die **Heilungs-/Stabilisierungsanteile** von Pharmacy und Religious Building (für das kontrollierende Team) – **nicht** „Zuflucht“, Cyberzombie-Hazard oder Persönlichkeitswechsel; zusätzlich 1 Verletzungsstufe/Spielzug-Heilung.
- **Fashion Boutique** (nicht in der Tabelle): einziger Effekt (Verstecken-Bonus) ist kontrollierter Vorteil → Dach-Zustand „Nur bei Kontrolle“ empfohlen (❌, Review R11).
- Alle übrigen PoIs (reine Gruppen in 4.1) wirken in Gänze unter ihrem Dach-Zustand; Radius/Begünstigte folgen dem Effekttext bzw. der Gruppe.

---

## 5. Sektor-Bonus-Einbindung (Eingangswerte Nr. 4 & Nr. 5)

Die beiden Sektor-Bonus-Tabellen in §6 ([Verteidigungsbonus](#verteidigungsbonus-sektor) und [Angriffsbonus](#angriffsbonus-sektor)) listen als Eingangswerte Nr. 4 **„Points of Interest (spätere Implementierung)“** und Nr. 5 **„Sektoreffekte (spätere Implementierung)“**. Normative Einordnung:

- **Eingangswert Nr. 4 (PoI)** fasst jene PoI-Teil-Effekte zusammen, die einen **sektorbezogenen Würfelpool-Bonus/-Malus** des Sektors erzeugen und damit in das Fuzzyset des Sektor-Bonus einfließen.
- **Eingangswert Nr. 5 (Sektoreffekte)** ist für **weitere Sektor-Effekte** reserviert (nicht PoI; siehe §6-Events-Konzept und Industrial-„Fehlfunktion“), getrennt vom PoI-Wert zu halten.
- **Nicht** in Nr. 4/5, sondern als **eigenständige, teambezogene Modifikatoren** zu führen: PoIs mit **team-globalem** oder **sektorunabhängigem** Radius (z. B. New Media „alle Sektoren“, Department-Store-Angriffsbonus, Police-Stash, Industrial-Ruhm, New-Media-Ruhm) sowie reine Ruhm-/Verstecken-Freigaben ohne Defensiv-/Angriffs-Bezug.

**Kandidaten für Eingangswert Nr. 4** (sektorbezogener Verteidigungs-/Angriffs-Pool-Bonus, für das kontrollierende Team): Grocery Store (1W6 Verteidigung), Police-Stash nur bei sektorweiter Lesart – da **sektorunabhängig** hier zu Nr. 4-Ausnahme; Department Store (Angriff, aber alle Sektoren → Ausnahme); Underpass (Verstecken), Suburban Housing (Verteidigung), Antiques (Verteidigung), VRcade-Spiegelkabinett (Verteidigung), Fashion Boutique (Verstecken), Multi-Level Car Park (Verteidigung), Bank-Tresor (Verteidigung), Fast Food/Elevated Rail (Umgebungs-Änderungen der Pools).

> 🔶 **Stand:** Die **Synthese** (welcher Bonus mit welchem Gewicht in den Fuzzyset-Output −4…+4 eingeht, Anrechnung als Malus für Angreifer) ist **nicht** hier, sondern im §6-Abschnitt zu den Sektor-Boni (Offener Punkt #26) zu definieren. Hier ist nur die **PoI→Eingangswert-Zuordnung** vorgezeichnet. Eine verbindliche Liste mit Gewichtung wird ergänzt, sobald das Fuzzyset spezifiziert ist (❌).

---

## 6. Abhängigkeiten & neue Bausteine (offen, ❌)

Die folgenden Bausteine werden von den PoI-Effekten vorausgesetzt, existieren aber noch nicht in §6/Modell. Sie werden hier **nicht** stillschweigend definiert, sondern mit Vorschlag und Owner-Dokument gelistet.

### 6.1 Allgemeine Fertigkeit „Erste Hilfe“ & Ausrüstungs-„Reparatur“
- **Bedarf:** PoI „Pharmacy“ (Erste Hilfe für das kontrollierende Team), PoI „Auto or Robotics Repair“ (Reparatur beschädigter Ausrüstung).
- **Vorschlag:** Eine allgemeine (nicht-Sani-)Aktion „Erste Hilfe“ als Sonderfall neben „Biotech“ (nur Sani) sowie eine „Reparieren“-Aktion für beschädigte Ausrüstung; beides nur in PoI-Sektoren mit entsprechendem Bonus aktivierbar.
- **Owner:** Aktionen-Katalog & -Engine (§6 [Aktionen & Kampfmanöver](#aktionen--kampfmanöver)). Status ❌ (Review R5).

### 6.2 Sachbeschädigung / Geldstrafe (vermögensrechtliche Folge)
- **Bedarf:** sehr viele PoIs vergeben „Strafe/Kosten wegen Sachbeschädigung“, teils „Geldstrafe fürs Team“ (Legal Firm, Low Rent, Police, Luxury, Mall, VRcade?, Suburban, Antiques, Multi-Level Car Park, Bank, Pop-Up Market, Garage, Hotel-Folge…).
- **Vorschlag:** Eigene „Vermögensfolge“ neben den Strafarten Freeze/Treffer/Abschuss: nach dem Spiel anfallende Kosten/Strafe für das Team (Prozent- oder Fixbetrag); Auslöser = „bei Kampfhandlungen“, Zufallswurf je PoI. Keine Bewegungswirkung.
- **Owner:** Strafen-Engine (§6 [Strafen & Verstöße](#strafen--verstöße), [Strafarten](#strafarten)); Modell: Team-/Budget-Wert nötig. Status ❌ (Review R6).

### 6.3 Verstecken-/Aufdeckungs-Engine
- **Bedarf:** PoIs mit „Verstecken“-Bonus (Art Dealer, Fashion, Underpass, Suburban, VRcade, Elevated Rail inkl. „Aufklärer unauffindbar“) und „als versteckt gelten“ (Courier-„Packetpost“).
- **Vorschlag:** Boni als **Würfel** auf den [Verstecken-Pool](#die-vier-würfelpools) gem. 1.2; „Aufklärer unauffindbar“ greift in die Gegenproben von [Suchen und Finden](#suchen-und-finden).
- **Owner:** §6-Offene Punkte #40/#41/#42. Status ❌ (Review R16).

### 6.4 Match-Ruhm-Senke
- **Bedarf:** „Bonus/erhöhter Gewinn von Ruhm“ (Data Storage, New Media, Nightclub, Movie Theatre, Industrial, Fans-Kontakte; „auch für Schiris“).
- **Vorschlag:** Match-interne Ruhm-Sammlung; Zuschlag am Spielende auf `specialPlayFame` (Spieler) bzw. das Schiri-Fame (vgl. `7_Referees.md`). Prozentangaben relativ zur Match-Ruhm-Menge.
- **Owner:** Modell `3_Object_Player.md`, `7_Referees.md`. Status ❌ (Review R7).

### 6.5 Begegnungs- & Events-NPCs
- **Bedarf:** Ghule, Drohnen (Sicherheits-/Hochsicherheits-), Mob, Fans, Cyberzombie, Wildtiere, „Mitarbeiter“ (Department Store), Sicherheits-KI (Office Block).
- **Vorschlag:** eigener Begegnungs-Baustein (NPC-Typ, Auftreten per Zufallswurf bei Kampfhandlungen bzw. Anwesenheit, Kampfwerte, Verhalten, Lokalität/Persistenz – z. B. Cyberzombie bleibt im Sektor, Body-Aug-„Wanderschaft“). Anknüpfung an die [Events (Viertel-Events)](#events-viertel-events)-Liste (§6 #38) und Referee-Drohnen-Token (`7_Referees.md`).
- **Owner:** Events-/NPC-Dokument (neu) bzw. §6 [Events](#events-viertel-events). Status ❌ (Review R8).

---

## 7. Quellen & Referenzen

- `6_Die Regeln des Spiels.md` – zentrale Referenz; Abschnitte [Points of Interest (Sektor)](#points-of-interest-sektor) und [Specials](#specials)
- `7_Referees.md` – Referee-NPC (Schiedsrichter-Aufmerksamkeit, Drohnen-Token, Ruhm)
- `8_Persoenlichkeiten.md` – Enneagramm, Kernattribute, Stress-/Sicherheits-Wechsel (Patzer-Definition)
- `3_Object_Player.md` – `ObjectPlayer`, `PlayerAttribute`, `CharacterStatus`, `fame`/`specialPlayFame`
- `10_Spielerentscheidungen.md` – Entscheidungsschicht (Aktions-/Manöver-Auswahl, Rollen-Filter)
- `spielerwerte/spielerwerte.md`, `spielerhandlungen/spielehandlungen.md` – Werte- und Aktionen-Katalog
- `data/Augmented Reality PLUS.pdf` (S. 5) – „The Downtown 2D10 Grid“ (Standorttyp + Zeile/1. W10)

### Status-Übersicht

| Baustein | Abschnitt | Status |
|---|---|---|
| Begriffsklärung (Aktivierung/Radius/Begünstigte, nW6-Lesart) | 1 | 🔶 |
| Review-Log (Cleanup-Befunde) | 2 | ✅ (Text) / 🔶 (offene Querabhängigkeiten) |
| Special-Auslöser & 2W6-Wurf (inkl. Patzer, Rekursion) | 3.1–3.3 | 🔶 Dach beschlossen |
| Special-Kataloge (Ausrüstung/Rolle/Position 1–3) | 3.4 | 🔶 Entwurf zur Ratifikation |
| PoI-Dach-Klassifikation & Teil-Effekt-Zuordnung | 4 | 🔶 Entwurf (je Zeile in §6) |
| Sektor-Bonus-Einbindung (Eingangswerte Nr. 4/5) | 5 | 🔶 Vorzeichnung; Synthese offen (#26) |
| Offene Abhängigkeiten / neue Bausteine | 6.1–6.5 | ❌ |

> **Offene Punkte §6 #32/#33** (Special-Kataloge, Auslöser & Balance): Bleiben **❌**, bis die Katalog-Inhalte in Abschnitt 3.4 ratifiziert sind; danach in §6 zurückspielen und schließen.

---

*Stand: 06.09.2026 – Entwurf zur Review gegen §6 und die Modell-Dokumente.*
