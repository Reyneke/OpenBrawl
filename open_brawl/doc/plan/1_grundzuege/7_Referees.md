# Referees

In diesem Kapitel geht es um die **Referees** – jene Charaktere, die das Spiel beobachten und Strafen ahnden. Hintergrund dafür ist, dass Referees laut dem SR-Kanon ebenfalls Charaktere sind und sogar eigene Superstars werden können.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

---

## Aktueller Stand

„Referee“ existiert im Code bisher nur als **Dienst-Klasse**, nicht als Charakter – der kanonische Anspruch („Referees sind Charaktere“) ist noch nicht abgebildet:

| Aspekt | Status | Details |
|---|---|---|
| **Match-Orchestrierung** | ✅ | `ObjectReferee` (`lib/objects/object_referee.dart`) startet Matches, protokolliert Aktionen und speichert Ergebnisse. |
| **Spiel beobachten & Strafen ahnden** | ❌ | Kein Regel-/Strafen-System zur Laufzeit; der Katalog in `6_Die Regeln des Spiels.md` ist beschlossen, aber nicht umgesetzt. |
| **Referee als Charakter** | ❌ | Kein eigenes NPC-Modell; `ObjectPlayer` (`lib/objects/object_player.dart`) kennt keine Schiri-Rolle. |
| **Superstar-Karriere** | 🔶 | Beschlossen: Referees sind **NPCs** (kein Verkauf, kein aktives Spiel), können laut Kanon aber über Ruhm zu Superstars werden – Mechanik offen (vgl. Design). |

### Aufgaben von `ObjectReferee` heute

`ObjectReferee` übernimmt aktuell drei Aufgaben rund um den Match-Lebenszyklus (Klassen-Doc-Kommentar: Regeln einhalten, faires Antreten, Aktionen protokollieren):

1. **Spielvorbereitung** – `setTeamReadyForBattle` prüft `isTeamValid` und `hasCaptain` und setzt das Team auf `ready_for_battle = true`.
2. **Spielstart** – `_checkAndStartMatch` / `_createMatch` suchen ein zweites bereites Team und legen einen `matches`-Eintrag mit leerem `battle_log` an.
3. **Spielende** – `endMatch` speichert das Ergebnis über `ProviderTeam.recordMatchResult` (3-1-0-Gesamtqualität) und das Match-JSON im Storage-Bucket `team_matches`.

Daneben protokolliert `logBattleAction` jede Aktion mit Zeitstempel in die `battle_log` – die erste Grundlage für ein späteres Schiri-Protokoll.

> **Hinweis:** Ein aktives „Beobachten“ und „Strafen ahnden“ findet derzeit **nicht** statt. Es fehlen die in `6_Die Regeln des Spiels.md` beschlossenen Bausteine: Viertel-/Spielzug-Logik, Strafen-Engine und Schiedsrichter-Abbruch (Siegbedingung 3).

### Anknüpfungspunkte im Code

- **`CharacterStatus`** (`lib/objects/object_player.dart`) hält den Verletzungszustand (`fine` … `overkilled`) und eignet sich als Konsequenz-Träger für Strafen (Treffer/Abschuss → Status).
- **`ObjectPlayer.fame`** (= `matchRecord.score + specialPlayFame`) ist der vorhandene Ruhm-Messwert und damit die natürliche Basis für eine „Superstar“-Perspektive.
- **Siegbedingung „Schiedsrichter-Abbruch“** – in `6_Die Regeln des Spiels.md` beschlossen (Übergriff von außen → Abbruch; Zerstörung/Brandstiftung → automatische Niederlage), im Code offen.
- **Markt-Trennung:** `ProviderMarket` (`lib/provider/provider_market.dart`) liest/synchronisiert ausschließlich die Tabelle `character_market` – Service-NPCs (Referees) bekommen eine eigene Speicherung (Details im Design-Teil).

---

## Design: Referee-NPC

Aus dem SR-Kanon folgt, dass ein Schiedsrichter **zwei Rollen** in sich vereint, die getrennt modelliert werden sollten:

### 1. `ObjectReferee` bleibt die Match-Leitung (Dienst)

Die bestehende Klasse orchestriert den Match-Lebenszyklus (Regeln, DB, Storage) und ist bewusst **kein** Spiel-Charakter. Diese Trennung verhindert, dass Regel-Logik an das „Befinden“ eines Schiri-Charakters gekoppelt wird.

### 2. Referee-NPC mit Spieler-Eigenschaften (Beschluss)

> **Beschluss (30.08.2026):** Referees sind **NPCs** – weder im Charaktermarkt käuflich noch aktive Spieler. Laut SR-Kanon überwachen sie das Spiel über **Drohnen** (als Token auf der Karte dargestellt). Sie patrouillieren die **Sektoren**, bemerken Regelbrüche der Spieler und ahnden sie – unter Beachtung ihrer **Persönlichkeit** (natürlich hat jeder Schiri eine). Es gibt eine **feste Anzahl von ~20 Schiris**, die bei den Spielen immer wieder auftreten.

Dafür eignet sich ein eigenes NPC-Modell **analog zu `ObjectPlayer`** (gleiche Werte-/Status-Struktur, aber ohne Vermarktung):

| Feld / Konzept | Bemerkung |
|---|---|
| `id`, `name`, `image` | Wie bei `ObjectPlayer`. |
| `CharacterStatus status` | Auch Schiedsrichter können ausfallen (z. B. durch „Übergriff von außen“). |
| Attribute | Relevante Werte: `attention` (Wahrnehmung), `edge` (Schlüsselentscheidungen), `morale` – über sie laufen Entdecken und Bewerten von Regelbrüchen. |
| `personality` | Jeder Schiri hat eine Persönlichkeit (analog `ObjectPlayer.personality`); sie fließt in die Strafentscheidung ein (Freeze/Treffer/Abschuss). |
| Drohnen-Token / Patrouille | Dargestellt als Token auf der Karte; patrouilliert die Sektoren (Fog of War beachten, vgl. `6_Die Regeln des Spiels.md`). |
| `fame` / `specialPlayFame` | Ruhm durch geleitete Spiele und besondere Schiri-Momente → „Superstar-Werdung“ als bekannte NPC-Persönlichkeit. |
| `RefereeMatchRecord` | Analog `PlayerMatchRecord` (gewertete Spiele). |

**Persistenz (zentrale Service-NPC-DB):** Referees werden zusammen mit weiteren, noch zu implementierenden **Service-NPCs** in einer **zentralen Datenbank** gespeichert (eigene Tabelle, z. B. `service_npcs`, statt `character_market`). Das ist ein eigener Baustein: Der Charaktermarkt (`ProviderMarket` in `provider_market.dart`) lädt und synchronisiert ausschließlich die Tabelle `character_market` mit `ObjectPlayer` – Service-NPCs dürfen dort **nie** auftauchen und müssen über die Speicherung/den Provider klar getrennt werden. Langfristig bietet sich ein gemeinsames Basis-Modell für Service-NPCs an (z. B. `ObjectServiceNpc` mit `kind`/`role`), bei dem der Schiri eine Instanz ist (Rolle `referee`).

---

## Nächste Schritte

| # | Punkt | Status |
|---|---|---|
| 1 | **Strafen-Engine** – Regelverstoß-Katalog aus `6_Die Regeln des Spiels.md`: Strafarten (Freeze/Treffer/Abschuss), „Ball tot“, „Strafverdrahtung“, Protokollierung in der `battle_log` | ❌ |
| 2 | **Schiedsrichter-Abbruch** als Siegbedingung 3 abbilden („Übergriff von außen“; automatische Niederlage bei Zerstörung/Brandstiftung) | ❌ |
| 3 | **Viertel-/Spielzug-Logik** im `ObjectReferee` (4 × 30 Min., 5-Min-Spielzüge) – Voraussetzung fürs Timing der Strafen | ❌ |
| 4 | **Zentrale Service-NPC-DB** – Referees (~20, fest) + weitere Service-NPCs in eigener Tabelle (z. B. `service_npcs`) speichern; klare Trennung vom `character_market` (keine Ausgabe im Charaktermarkt) | ❌ |
| 5 | **Referee-NPC-Modell & Simulation** – Spieler-NPC mit Drohnen-Token, Sektor-Patrouille und Persönlichkeit; Regelbruch-Erkennung & Strafverteilung in die Strafen-Engine integrieren | ❌ |

---

*Stand: 30.08.2026*


