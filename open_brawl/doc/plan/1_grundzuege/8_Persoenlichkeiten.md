# Persönlichkeiten

In diesem Kapitel geht es um die **Persönlichkeiten** – ein Kernaspekt jedes Charakters (Spieler wie NPC), der strikt am "Enneagram of Personality" orientiert ist und als Eingangsvariable für fuzzy-logische Entscheidungen dient.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

---

## Aktueller Stand

Persönlichkeiten sind als `EnneagramPersonality`-Enum in `lib/objects/object_player.dart` umgesetzt und an `ObjectPlayer` gekoppelt. Die Verknüpfung mit der fuzzy-logischen Entscheidungslogik ist beschlossen, aber noch nicht implementiert.

| Aspekt | Status | Details |
|---|---|---|
| **Datenmodell** | ✅ | `EnneagramPersonality` (9 Typen, deutscher `displayName`) in `lib/objects/object_player.dart`. |
| **Zuordnung bei Charaktererstellung** | ✅ | `ObjectPlayer.create()` wählt zufällig einen Typ; siehe `3_Object_Player.md`. |
| **Serialisierung** | ✅ | Persistiert als Enum-Name in Supabase (`personality`-Feld) über `toJson`/`fromJson`. |
| **Fuzzy-Logik-Eingang** | 🔶 | Konzept: Persönlichkeit fließt als Eingangswert in Fuzzysets ein (vgl. `6_Die Regeln des Spiels.md`). Kernattribute sind stärker gewichtet. Noch nicht implementiert. |
| **Attributs-Zuordnung pro Typ** | ❌ | Jedem Typ sind drei Kernattribute zugeordnet – Tabelle fehlt noch (Vorschlag siehe unten). |
| **Referee-NPC-Persönlichkeit** | 🔶 | Beschlossen: Schiedsrichter haben eine Persönlichkeit (analog `ObjectPlayer`); fließt in Strafentscheidung ein (vgl. `7_Referees.md`). Noch nicht umgesetzt. |
| **Stress-/Sicherheits-Wechsel** | 🔶 | Mechanik hier beschrieben (Würfelpool `Moral − Verwundungen`, Patzer → permanent, Wechsel-Tabelle). Umsetzung im Code offen. |

### Anknüpfungspunkte im Code

- **`EnneagramPersonality`** (`lib/objects/object_player.dart`, Zeilen 255–280) – Enum mit 9 Typen und deutschem `displayName`.
- **`ObjectPlayer.personality`** (`lib/objects/object_player.dart`) – Feld auf dem Charakter; zufällig bei `create()` gesetzt.
- **`ObjectPlayer.fromJson` / `ObjectPlayer.toJson`** – Persistiert über `EnneagramPersonality.fromName()`.

---

## Konzept

Jeder Persönlichkeit aus dem Enneagram werden **drei Attribute** als **Kernattribute** zugeordnet. Diese drei Kernattribute, die zum Persönlichkeitstyp passen, beeinflussen die Entscheidungsfindung – zu deren Zweck das `Personality`-Attribut herangezogen wird. Eine solche Anfrage kann beispielsweise die Frage sein, ob ein Kampf begonnen wird (siehe `6_Die Regeln des Spiels.md`) oder wie ein Schiedsrichter einen Regelverstoß bewertet (siehe `7_Referees.md`).

Die Kernattribute eines Typs werden bei fuzzy-logischen Entscheidungen **stärker gewichtet** als die übrigen Attribute, da sie den Kern der Persönlichkeit ausmachen.

### Einbindung in die Fuzzy-Logik

1. **Eingangsvariable:** Die Persönlichkeit (und ihre drei Kernattribute) dienen als Eingangsvariable eines Fuzzysets.
2. **Fuzzifizierung:** Der aktuelle Attributswert wird über die Zugehörigkeitsfunktion des Fuzzysets in einen Fuzzy-Wert umgewandelt.
3. **Regelanwendung:** `FuzzyRuleBase` wendet Regeln an (z. B. „WENN Persönlichkeit = Enthusiast UND Moral hoch DANN Aktion = Angriff").
4. **Defuzzifizierung:** Der Ausgangswert (z. B. Wahrscheinlichkeit eines Angriffs) wird bestimmt.

> **Referenz:** `lib/fuzzy_logic/` (`FuzzyVariable`, `FuzzySet`, `FuzzyRuleBase`) und `6_Die Regeln des Spiels.md` (Abschnitt Spielerhandlungen).

---

## Persönlichkeiten und Attribute

### Die neun Enneagramm-Typen

Quelle: https://en.wikipedia.org/wiki/Enneagram_of_Personality

| # | Typ (Code) | Deutscher Name | Beschreibung | Kernattribute |
|---|---|---|---|---|
| 1 | `one` | Reformer | Prinzipientleh, diszipliniert, perfektionistisch | Verteidigung, Aufmerksamkeit, Moral |
| 2 | `two` | Helfer | Fürsorglich, großzügig, bestätigend | Moral, Widerstand, Aufmerksamkeit |
| 3 | `three` | Erfolgstyp | Erfolgsorientiert, getrieben, angepasst | Angriff, Edge, Agilität |
| 4 | `four` | Individualist | Ausdrucksstark, emotional, introspektiv | Aufmerksamkeit, Moral, Edge |
| 5 | `five` | Forscher | Analytisch, unabhängig, distanziert | Aufmerksamkeit, Verteidigung, Widerstand |
| 6 | `six` | Loyalist | Verlässlich, engagiert, sicherheitsorientiert | Verteidigung, Widerstand, Moral |
| 7 | `seven` | Enthusiast | Verspielt, abenteuerlustig, impulsiv | Agilität, Edge, Moral |
| 8 | `eight` | Herausforderer | Durchsetzungsstark, protektiv, dominant | Angriff, Verteidigung, Widerstand |
| 9 | `nine` | Vermittler | Ausgleichend, begütigend, widerstandslos | Moral, Widerstand, Agilität |

> ⚠️ **Hinweis:** Die obige Kernattributs-Zuordnung ist ein **Vorschlag** basierend auf den Charakterzügen der Enneagramm-Typen und den verfügbaren Spielattributen (`attack`, `agility`, `defense`, `resistance`, `attention`, `morale`, `edge`). Sie sollte im Team abgestimmt und festgeschrieben werden, bevor die Implementierung beginnt.

### Stress

Eine Persönlichkeit kann **temporär** wechseln, wenn der Charakter **unter Stress** gerät (siehe [Enneagramm-Artikel](#die-neun-enneagramm-typen)). Stress entsteht, wenn der Charakter nach **Beginn eines Spielzuges**, nach einem **einschneidenden Ereignis** (z. B. Verwundung, Heilung durch den Sani) oder nach einem **fehlgegangenen Manöver** *keinen Erfolg* auf eine Probe **Moral − aktuelle Verwundungen** erzielt.

**Würfelpool der Probe:** `Moral − aktuelle Verwundungen`

| Ergebnis | Folge |
|---|---|
| **Pool ≤ 0** | Es wird nicht gewürfelt – der Charakter verfällt **direkt** in den Stresszustand. |
| **Kein Erfolg** | Der Charakter wechselt **temporär** auf seinen Stress-Typ (siehe [Tabelle](#wechsel-unter-stress-und-sicherheit)). |
| **Patzer** (kein Erfolg und zugleich **mehr als die Hälfte Einser** im Wurf) | Die Persönlichkeitsänderung ist **permanent**. |

Der temporäre Wechsel gilt bis zum **nächsten Stresswurf**.

### Sicherheit

Analog zum Stress kann ein Persönlichkeitswechsel eintreten, wenn der Charakter sich **„in Sicherheit“** fühlt. Wird ein **Stresswurf** gefordert und erzielt der Charakter **mindestens drei Erfolge**, so wechselt er **temporär** auf seinen Sicherheits-Typ (siehe [Tabelle](#wechsel-unter-stress-und-sicherheit)). Dieser Zustand hält an bis zum **nächsten Stresswurf**.

### Wechsel unter Stress und Sicherheit

Neben den Kernattributen hat jede Persönlichkeit einen **Stress-Typ** (bei Belastung) und einen **Sicherheits-Typ** (bei Sicherheit) – die Verbindungslinien des Enneagramms. Quelle der Zuordnung: die Spalten „Stress/Disintegration“ und „Security/Integration“ im [Enneagramm-Artikel](https://en.wikipedia.org/wiki/Enneagram_of_Personality).

| # | Typ (Code) | Wechsel unter **Stress** → | Wechsel in **Sicherheit** → |
|---|---|---|---|
| 1 | `one` (Reformer) | 4 – `four` (Individualist) | 7 – `seven` (Enthusiast) |
| 2 | `two` (Helfer) | 8 – `eight` (Herausforderer) | 4 – `four` (Individualist) |
| 3 | `three` (Erfolgstyp) | 9 – `nine` (Vermittler) | 6 – `six` (Loyalist) |
| 4 | `four` (Individualist) | 2 – `two` (Helfer) | 1 – `one` (Reformer) |
| 5 | `five` (Forscher) | 7 – `seven` (Enthusiast) | 8 – `eight` (Herausforderer) |
| 6 | `six` (Loyalist) | 3 – `three` (Erfolgstyp) | 9 – `nine` (Vermittler) |
| 7 | `seven` (Enthusiast) | 1 – `one` (Reformer) | 5 – `five` (Forscher) |
| 8 | `eight` (Herausforderer) | 5 – `five` (Forscher) | 2 – `two` (Helfer) |
| 9 | `nine` (Vermittler) | 6 – `six` (Loyalist) | 3 – `three` (Erfolgstyp) |

> ℹ️ **Hinweis:** Ein Wechsel wirkt sich auf die [Kernattribute](#persönlichkeiten-und-attribute) des Charakters aus – ab dem Wechsel fließen die Kernattribute des *neuen* Typs stärker gewichtet in die [Fuzzy-Logik](#einbindung-in-die-fuzzy-logik) ein.

---

## Persönlichkeit und Fuzzy-Logik: Interaktionsbeispiele

### Beispiel 1: Kampfentscheidung (Spieler)

Ein Kapitän mit Persönlichkeit `Enthusiast` (Typ 7) hat die Kernattribute Agilität, Edge und Moral. Bei der Entscheidung, ob ein Kampf begonnen werden soll (vgl. `6_Die Regeln des Spiels.md`):

- **Hohe Moral** → höhere Kampfbereitschaft
- **Hohes Edge** → höhere Risikoakzeptanz
- **Hohe Agilität** → höhere Erfolgsaussicht im Nahkampf

Die Fuzzy-Regelbasis gewichtet diese drei Kernattribute stärker als die übrigen vier (Angriff, Verteidigung, Widerstand, Aufmerksamkeit).

### Beispiel 2: Strafentscheidung (Referee)

Ein Schiedsrichter mit Persönlichkeit `Reformer` (Typ 1) hat die Kernattribute Verteidigung, Aufmerksamkeit und Moral (vgl. `7_Referees.md`):

- **Hohe Aufmerksamkeit** → Regelverstöße werden häufiger bemerkt
- **Hohe Moral** → strengere Strafen (Freeze/Treffer/Abschuss)
- **Hohe Verteidigung** → widerstandsfähiger gegen „Übergriff von außen"

---

## Nächste Schritte

| # | Punkt | Status |
|---|---|---|
| 1 | **Kernattributs-Zuordnung festlegen** – Tabelle oben mit dem Team abstimmen und festschreiben | ❌ |
| 2 | **Fuzzy-Integration implementieren** – `EnneagramPersonality` als Eingangsvariable in Fuzzysets einbinden (vgl. `lib/fuzzy_logic/`) | ❌ |
| 3 | **Gewichtungslogik** – Kernattribute in der `FuzzyRuleBase` höher gewichten als Nicht-Kernattribute | ❌ |
| 4 | **Referee-Integration** – Persönlichkeit in die Strafentscheidungs-Logik des Schiri-NPCs einbinden (vgl. `7_Referees.md`) | ❌ |
| 5 | **UI-Erweiterung** – Persönlichkeits-Dropdown in `ScreenCharacterOverview` um Beschreibung und Kernattribute ergänzen | ❌ |
| 6 | **Stress-/Sicherheits-Mechanik implementieren** – Würfelpool `Moral − Verwundungen`, Patzer-Erkennung (mehr als die Hälfte Einser) und Typ-Wechsel (temporär/permanent nach Tabelle) im `ObjectPlayer`-Modell abbilden | ❌ |

---

*Stand: 30.08.2026*