# Spielerentscheidungen

Während eines Matches steuern die (menschlichen) Manager ihre Teams **nur indirekt**: Sie legen je Spielzug/Viertel eine **Positionierung** (offensiv / defensiv / aufklären) und ggf. die **Torzone** fest. Die konkreten Handlungen der einzelnen Spielerobjekte auf dem Feld – welche **Aktion** bzw. welches **Kampfmanöver** sie ausführen – übernimmt daher eine **autonome Entscheidungsschicht**. Diese Schicht wird mit einer **Fuzzylogik** umgesetzt, die aus dem Zustand des Spiels und den Eigenschaften des jeweiligen Spielerobjekts eine Handlung ableitet.

Dieses Dokument ist das **Umsetzungskonzept** dieser Entscheidungsschicht. Es konkretisiert den bereits beschlossenen Abschnitt *„Auswahl von Aktion / Manöver"* in `6_Die Regeln des Spiels.md` und führt ihn mit der vorhandenen Fuzzy-Logik-Bibliothek (`lib/fuzzy_logic/`) zusammen. Das dort festgeschriebene Regelwerk bleibt die verbindliche Referenz; hier wird beschrieben, **wie** es als Fuzzyset abgebildet wird.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

---

## Ziel & Abgrenzung

- **Nicht** behandelt: Die übergeordneten Manager-Entscheidungen (Positionierung, Torzone, Einwechslungen). Diese trifft weiterhin der menschliche Manager bzw. `ObjectReferee`.
- **Behandelt:** die pro Spielerobjekt getroffene Wahl der **Aktion / des Manövers** innerhalb eines Kampfzugs – sowie die dabei nötige **Zielauswahl** (wer wird angegriffen / verteidigt).
- Die Persönlichkeit ist ein Kern-Eingangswert (vgl. `8_Persoenlichkeiten.md`): Je Persönlichkeitstyp werden die **drei Kernattribute stärker gewichtet** als die übrigen Attribute.
- **Rollen-Beschränkungen** (z. B. „Ball werfen" nur außer Sani/Stürmer, „Steuern" nur Stürmer) sind **harte Randbedingungen** und werden nicht über die Fuzzy-Logik entschieden, sondern als Filter *nach* der Inferenz angewendet (vgl. Aktionen-Katalog in `spielerhandlungen/spielehandlungen.md`).

---

## Konzeption

Die Entscheidung durchläuft den klassischen vierstufigen Fuzzy-Pfad (Fuzzifizierung → Regelbasis → Aggregation → Defuzzifizierung), wie er auch in `8_Persoenlichkeiten.md` beschrieben ist:

1. **Fuzzifizierung:** Der scharfe Ist-Zustand wird über Zugehörigkeitsfunktionen (`FuzzySet`) in linguistische Werte übersetzt.
2. **Regelanwendung:** Eine `FuzzyRuleBase` wendet Regeln der Form *„WENN … UND … DANN …"* an.
3. **Aggregation:** Die Wahrheitsgrade der Ausgangs-Sets werden je Aktionstyp zusammengeführt.
4. **Defuzzifizierung:** Aus den aggregierten Wahrheitsgraden wird ein scharfer Ausgangswert („Neigung") je Ausgangs-Dimension bestimmt.

### Eingangswerte (Fuzzifizierung)

Die folgenden **Faktoren** steuern die Entscheidung (verbindlich aus `6_Die Regeln des Spiels.md`, Abschnitt *„Auswahl von Aktion / Manöver"*). Für die Umsetzung wird jeder Faktor auf eine **scharfe Quelle** im Modell zurückgeführt:

| # | Faktor (Regelwerk) | Scharfe Quelle im Modell | Fuzzy-Eingangsvariable (linguistische Werte) |
|---|---|---|---|
| 1 | Wer hat den Ball? | Ballbesitz-Zustand des Spielzugs | `ballbesitz` — *eigene Mannschaft / Gegner / frei / Spieler selbst* |
| 2 | Persönlichkeit | `ObjectPlayer.personality` (`EnneagramPersonality`) + Kernattribute | `aggressivitaet`, `courage` – abgeleitet aus den Kernattributen des Typs |
| 3 | Moral | `PlayerAttribute.morale` (Endwert inkl. Rassenmodifikator) | `moral` — *niedrig / mittel / hoch* |
| 4 | Art der Positionierung | Manager-Entscheidung (offensiv/defensiv/aufklären) des aktuellen Spielzugs | `positionierung` — *offensiv / defensiv / aufklaeren* |
| 5 | Zustand der Positionierung | `CharacterStatus` (`ObjectPlayer.status`, `isFitToPlay`) + Verletzungsmodifikatoren | `zustand` — *frisch / verletzt / schwer verletzt* |
| 6 | Distanz & Umfeld | HexGrid (Ziel-/Gegnerdistanz, eigener/gegnerischer Torsektor) | `distanz`, `bedrohung` — *nah / mittel / weit* |
| 7 | Weitere (offen) | – | siehe [Offene Punkte](#offene-punkte) |

> **Hinweis:** Die Persönlichkeit ist ein **diskreter** Enum-Wert; die Bibliothek arbeitet mit numerischen Variablen (`FuzzyVariable<T extends num>`). Der Persönlichkeitstyp muss daher zuerst in eine numerische „Neigung" überführt werden (z. B. gewichtete Summe der drei Kernattribute → linguistische Werte wie *eher kampfbereit / eher defensiv*). Ein Vorschlag für diese Abbildung liegt in `8_Persoenlichkeiten.md`.

### Inferenz (Regelbasis)

Die Regeln sind **Spielregeln als Wenn-Dann-Sätze**, z. B.:

- `WENN ballbesitz = Spieler selbst UND positionierung = offensiv UND moral = hoch DANN aktion = Fernkampfangriff`
- `WENN positionierung = defensiv UND bedrohung = hoch DANN aktion = volle Verteidigung`
- `WENN zustand = schwer verletzt UND moral = niedrig DANN aktion = Ausweichen/Rückzug` (Persönlichkeit gewichtet die Schwelle)
- `WENN positionierung = aufklaeren UND distanz = weit DANN aktion = Bewegen`

Umsetzung mit der vorhandenen Bibliothek `lib/fuzzy_logic/` (`FuzzyVariable`, `FuzzySet`, `FuzzyRuleBase`, `very`/`fairly` aus `fuzzyhedges.dart`). Ein realistisches Gerüst:

```dart
// 1. Eingangsvariablen
final moral = FuzzyVariable<int>()..name = 'moral';
moral.sets = [
  FuzzySet.LeftShoulder(0, 0, 40, name: 'niedrig'),
  FuzzySet.Triangle(30, 60, 90, name: 'mittel'),
  FuzzySet.RightShoulder(60, 100, 100, name: 'hoch'),
];
// Analog: distanz, zustand, positionierung …

// 2. Ausgangsvariable je Aktionstyp (z. B. „Angriffsneigung" 0..100)
final angriff = FuzzyVariable<int>()..name = 'angriff';
angriff.sets = [
  FuzzySet.LeftShoulder(0, 0, 30, name: 'niedrig'),
  FuzzySet.Triangle(20, 50, 80, name: 'mittel'),
  FuzzySet.RightShoulder(70, 100, 100, name: 'hoch'),
];

// 3. Regelbasis
final regelwerk = FuzzyRuleBase();
regelwerk.addRules([
  (moral['hoch'] & distanz['nah']) >> (angriff['hoch']),
  (zustand['schwer verletzt'] & moral['niedrig']) >> (angriff['niedrig']),
  // …
]);

// 4. Inferenz pro Entscheidung
final ausgang = angriff.createOutputPlaceholder();
regelwerk.resolve(
  inputs: [moral.assign(spieler.moralEndwert), distanz.assign(distanzZumZiel)],
  outputs: [ausgang],
);
final neigung = ausgang.crispValue; // scharfer Wert, gewichteter Mittelwert
```

> ⚠️ **Design-Hinweis:** Die Bibliothek liefert als scharfen Ausgangswert den **gewichteten Mittelwert der Repräsentativwerte** über die Wahrheitsgrade (`_computeCrispValue()` in `lib/fuzzy_logic/lib/src/value.dart`) – ein Wert je Ausgangs-Dimension, kein diskreter Aktions-Enum. Die *Wahl einer konkreten Aktion* (siehe Ausgangswerte) liegt daher in einer dünnen Schicht **oberhalb** der Fuzzylogik.

### Ausgangswerte (Defuzzifizierung & Aktionswahl)

Als **fuzzy Ausgänge** werden pro Spielerobjekt wenige, numerische **Handlungs-Dimensionen** modelliert, z. B. *Angriffsneigung*, *Bewegungs-/Vorstoßneigung*, *Defensiv-/Rückzugsneigung*, *Unterstützungsneigung*. Nach der Defuzzifizierung wird in drei Schritten die konkrete Aktion gewählt:

1. **Zulässige Aktionen filtern** – Rollen-Beschränkungen & Ball-/Fahrzeug-Regeln (vgl. Aktionen-Katalog in `spielerhandlungen/spielehandlungen.md`):
   - Einzelaktionen: Bewegen, Sprinten, Klettern, Springen, Steuern, Ausweichen, Parieren, Volle Verteidigung, Volle Deckung, Nahkampf-/Ringen-/Fernkampf-/Salvenangriff, Biotech (nur Sani), Ball aufheben/werfen/fangen, Auf-/Absteigen.
   - Kampfmanöver (Gruppenaktionen): Dynamisches Eindringen, Feuerwalze, Flankieren, Gedeckte Aufklärung, Kreuzfeuer, Rautenformation, Rudelangriff, Schilde vor!, Überschlagender Rückzug, Überschlagendes Vorgehen, Unterstützungsfeuer.
2. **Dimension bestimmt den Handlungstyp** – die Dimension mit der höchsten Neigung legt fest, *ob* angegriffen, bewegt, verteidigt oder unterstützt wird.
3. **Konkrete Aktion per gewichteter Zufallswahl** – aus der passenden, gefilterten Aktionen-Menge wird mit einer Wahrscheinlichkeit proportional zur Neigung gewählt (**nicht** deterministisch per `argmax`), damit die KI nicht vorhersehbar ist und sich ein tie-Spielen mit dem Persönlichkeitstyp ergeben kann.

Die **Zielauswahl** beim Angreifen folgt einer eigenen Inferenz (beschlossen in `6_Die Regeln des Spiels.md`): Als Ausgang dient hier ein **Spieler der Gegenseite**, gewichtet über Persönlichkeit (z. B. Tendenz, gezielt die schwächste bzw. die regeltechnisch unantastbare Einheit wie den Sani *nicht* anzugreifen) – als Fuzzyset über die Gegner-Spielerobjekte.

> 🔶 **Status:** Konzept beschlossen, im Code nicht umgesetzt – Entscheider-Logik (Kapitän → höchster Pool-Wert), Eingangs-Aggregation, Regelsätze und Aktionswahl existieren noch nicht.

---

## Verknüpfung mit dem Würfelsystem

Die Neigungen fließen in bestehende Pools ein (vgl. `6_Die Regeln des Spiels.md`, Abschnitt *Würfelsystem*):

- Wer den Handlungstyp **vorgibt**, bestimmt die in die Inferenz einfließende Stärke: Der **Teamkapitän** (falls in der Positionierung) gibt die Aktion/das Manöver an, sonst der Spieler mit dem **höchsten** der Positionierung zugeordneten Pool (**Offensiv-Pool** für offensiv, **Defensiv-Pool** für defensiv, **Aufklärungs-Pool** für aufklären).
- Verletzungsstufen aus dem Kampf verändern `CharacterStatus` und damit den Eingang `zustand` – die Entscheidungsschicht reagiert dadurch in Folgerunden selbstständig (z. B. Rückzug bei schweren Verletzungen).

---

## Offene Punkte

| # | Punkt | Status |
|---|---|---|
| 1 | **Ausgangs-Modell klären:** numerische Handlungs-Dimensionen (Neigungen) + dünne Aktions-Schicht – deckungsgleich mit dem Wunsch „Aktionen/Manöver als Ausgang" aus `6_Die Regeln des Spiels.md`? | ❌ |
| 2 | **Persönlichkeit → numerische Neigung:** deterministische Abbildung `EnneagramPersonality` (3 Kernattribute) auf Eingangsvariablen festlegen | ❌ |
| 3 | **Faktor #7 („andere Faktoren")** definieren (z. B. Sektor-Kontrolle, Points of Interest, Sani-Anwesenheit) | ❌ |
| 4 | **Regelsatz katalogisieren** – je Handlungs-Dimension eine Wenn-Dann-Tabelle (Quelle: Regelwerk) | ❌ |
| 5 | **Gewichtungslogik Kernattribute** in der `FuzzyRuleBase` höher gewichten als Nicht-Kernattribute | ❌ |
| 6 | **Kapitän-Entscheider** über die Inferenz anbinden (`ObjectTeam` → Kapitäns-Spielerobjekt) | ❌ |
| 7 | **Aktionswahl-Ebene** (gewichtete Zufallswahl, Rollen-Filter, Fahrzeug-/Ballregeln) implementieren | ❌ |

---

## Referenzen

- `6_Die Regeln des Spiels.md` – verbindliches Regelwerk, Abschnitt „Auswahl von Aktion / Manöver" & Würfelsystem (Zielauswahl, Pools)
- `spielerhandlungen/spielehandlungen.md` – Aktionen-/Kampfmanöver-Katalog mit Rollen-Beschränkungen
- `8_Persoenlichkeiten.md` – Enneagramm-Typen, Kernattribute, Einbindung in die Fuzzy-Logik
- `3_Object_Player.md` – `ObjectPlayer`, `PlayerAttribute`, `CharacterStatus`, `EnneagramPersonality`
- `4_Object_Team.md` – `ObjectTeam`, Kapitän, Rollen/Positionen
- `lib/fuzzy_logic/` – `FuzzyVariable`, `FuzzySet`, `FuzzyRuleBase`, `fuzzyhedges.dart` (`very`, `fairly`)
- `9_TeamManagement.md` – Manager-Entscheidungen (Positionierung) als oberste Ebene

---

*Stand: 05.09.2026 – Entwurf in Überarbeitung (Struktur + Umsetzungsbezug), offen für Review gegen `6_Die Regeln des Spiels.md`.*

