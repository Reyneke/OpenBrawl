# Team Management

In diesem Kapitel geht es um das **Team Management** und die Konzepte, welche daraus resultieren: Kaderaufbau, Rollenverteilung, Teamkapitän, Statistik und die Bildschirme, über die all das verwaltet wird.

> **Status-Legende:** ✅ beschlossen & im Code umgesetzt · 🔶 beschlossen, aber noch nicht (vollständig) umgesetzt · ❌ offen / fehlt noch

---

## Aktueller Stand

Das Team-Management ist funktional weitgehend vollständig: Teams, Kader und Statistiken leben im Modell `ObjectTeam` (`lib/objects/object_team.dart`), die Persistenz übernimmt `ProviderTeam` (`lib/provider/provider_team.dart`, Supabase-Tabelle `teams`), und zwei Bildschirme bilden die Verwaltung ab. Die Frage aus der ursprünglichen Notiz („Bildschirm: screen_team_editor.dart?“) ist damit beantwortet: **ja** – ergänzt um `screen_team_select.dart`.

| Aspekt | Status | Details |
|---|---|---|
| **Team-Auswahl** | ✅ | `ScreenTeamSelect` (`lib/screens/screen_team_select.dart`) lädt die Teams via `loadTeamsFromDatabase()` und navigiert in den Editor. Einstieg über `main_app.dart`. |
| **Team-Editor** | ✅ | `ScreenTeamEditor` (`lib/screens/screen_team_editor.dart`): Umbenennen, Logo-Upload, Statistik, Kaderliste, Rollen/Kapitän, „Enter Battle“. |
| **Datenmodell** | ✅ | `ObjectTeam` mit gekapseltem Kader (`players`), `nuyen`, `captainId`, `record`, `dbId`; Validierung über `isTeamValid`. |
| **Kader-Regeln** | ✅ | `requiredRoster` (4/4/2/1/1/1 = 13 aktive Spieler), `maxRosterSize` (= 20), `isTeamValid`, `isRoleFree`. |
| **Kapitän** | ✅ | `setCaptain()` / `hasCaptain`; Pflichtprüfung in `ObjectReferee.setTeamReadyForBattle`. |
| **Persistenz** | ✅ | `ProviderTeam`: `addTeam`, `removeTeam`, `addCharacterToTeam`, `modifyCharacterInTeam`, `removeCharacterFromTeam`, `adjustMoney`, `updateTeamInDatabase`, `setTeamReadyForBattle`. |
| **Statistik / Qualität** | ✅ | `TeamMatchRecord` (3-1-0-Schema, `quality = Siege × 3 + Unentschieden`); Eintragung über `recordMatchResult(winner, loser)`. |
| **Teams erstellen/löschen (UI)** | ❌ | `addTeam()` / `removeTeam()` existieren im Provider, haben aber aktuell **keinen UI-Aufrufer** – `ScreenTeamSelect` zeigt nur den „No team yet“-Zustand. |
| **Unentschieden** | 🔶 | `TeamMatchRecord.drawn` / `recordDraw()` existieren, aber `ObjectReferee.endMatch` → `recordMatchResult` kennt nur Winner/Loser (vgl. offener Punkt 17 in `6_Die Regeln des Spiels.md`). |
| **Passives Einkommen** | ❌ | **Vorschlag:** täglich 06:00 UTC, `100 + 100 × Qualität` Nuyen (Details unten). |
| **Passive Heilung** | ❌ | **Vorschlag:** täglich eine Verletzungsstufe je Spieler; Zusammenspiel mit der Sani-Rettungs-Kette offen. |
| **Anheuerbare NSC** | ❌ | **Vorschlag:** Teamarzt, Buchhalter, Fixer … – Persistenz in der zentralen Service-NPC-DB (vgl. `7_Referees.md`). |

### Screen-Fluss

```
main_app.dart → ScreenTeamSelect ─→ ScreenTeamEditor ─┬→ ScreenCharacterMarket (Kader auffüllen/kaufen)
                                                     ├→ ScreenBattleMap (Icon oben rechts = Vorschau)
                                                     └→ ScreenBattleMap („Enter Battle“ = Match vorbereiten)
```

### Anknüpfungspunkte im Code

- `lib/objects/object_team.dart` – Modell, Kader-Kapselung, `requiredRoster`, `isTeamValid`, `setCaptain`, `TeamMatchRecord`, `toJson` / `fromJson`.
- `lib/provider/provider_team.dart` – DB-Zugriff (Tabellen-Schema im Klassen-Kommentar), Nuyen-Verwaltung, Statistik, `ready_for_battle`.
- `lib/screens/screen_team_select.dart` bzw. `lib/screens/screen_team_editor.dart` – UI.
- `lib/objects/object_referee.dart` – Match-Vorbereitung (`setTeamReadyForBattle`) und -Auswertung (`endMatch` → `recordMatchResult`).
- `lib/widgets/character_list_item.dart` – Zeile je Kaderspieler (Rolle, Kapitän, Ausrüstung).
- `lib/provider/provider_market.dart` – Kauf/Verkauf liefert Spieler ins Team (`adjustMoney`).
- Enge Verwandte: `4_Object_Team.md` (Modell-Details), `2_Aktueller_Stand.md` (Bestandsaufnahme), `6_Die Regeln des Spiels.md` (Kader-/Rollenregeln), `7_Referees.md` (Referees und zentrale Service-NPC-DB).

---

## Konzept-Entscheidungen

- **Der Klassenname trägt den Kontext:** Die Klasse heißt `ObjectTeam` – Felder heißen deshalb `name`, `logo`, `nuyen`, `players` (ohne `team`-Präfix; vgl. `4_Object_Team.md`).
- **Das Modell erzwingt die Regeln:** Kaderobergrenze, Duplikat-Verhinderung und Rollenzählung (`isTeamValid`, `isRoleFree`) liegen im Modell, nicht in den Screens.
- **UI = Zustand des Providers:** Screens beziehen den Kader über `ProviderTeam`; direkte Mutationen an `widget.selectedTeam` brechen diese Einbahnstraße (siehe Refactoring 2).

---

## Neue Konzepte (Vorschläge)

Die folgenden Mechanismen sind **Vorschläge** – noch nicht beschlossen und ohne Umsetzung im Code. Sie erweitern das Team-Management um eine langfristige Wirtschafts- und Personal-Sicht.

### Passives Einkommen

**Idee:** Teams generieren passives Einkommen, täglich um **06:00 Uhr UTC** (der Vorschlag nannte „GMZ“ – gemeint ist die koordinierte Weltzeit).

| Baustein | Wert |
|---|---|
| Täglicher Trigger | **06:00 Uhr UTC** |
| Basisbetrag | **100 Nuyen** |
| Qualitätsbonus | **+100 Nuyen × Gesamtqualität** (`TeamMatchRecord.quality` = Siege × 3 + Unentschieden) |
| Beispiel | Qualität 4 → `100 + 100 × 4` = **500 Nuyen/Tag** |

> ❌ **Status:** Vorschlag, nicht beschlossen – kein Code. Anknüpfung: `ObjectTeam.nuyen`, `TeamMatchRecord.quality`, täglicher Trigger (z. B. Cron-Job oder `ProviderTeam`).

### Passive Heilung

**Idee:** Im selben Zyklus wie das passive Einkommen heilen die Spieler des Teams je **eine Verletzungsstufe** (`CharacterStatus` rückwärts).

**Offene Fragen:**

- Gilt die passive Heilung für **alle** Stufen – auch `dead`/`overkilled`? Das würde die **Sani-Rettungs-Kette** unterlaufen (`6_Die Regeln des Spiels.md`: dort ist `dead` die Stabilisierungsschwelle, `overkilled` nur über den Sani rettbar; vgl. Offene Punkte #36/#37).
- Wie wirkt ein NSC **Teamarzt** darauf – zusätzliche Stufe, schnellere Heilung oder Heilung von `dead`-Charakteren?

> ❌ **Status:** Vorschlag, nicht beschlossen – kein Code.

### Anheuerbare NSC (Service-NPCs)

**Idee:** NSC sind **anheuerbar**, nehmen **nicht** an den Matches teil und erlauben **besondere Aktionen**, die mit **Würfelproben** verbunden sind.

**Persistenz:** NSC werden **in derselben Datenbank gehalten wie die Referees** (zentrale Service-NPC-DB, vgl. `7_Referees.md`: gemeinsames Basis-Modell `ObjectServiceNpc` mit `kind`/`role` – dort Rolle `referee`), sind aber **anheuerbar** – d. h. sie erhalten eine Vertrags-/Besitzer-Beziehung zu genau einem Team.

**Beispiele (Vorschlag):**

| NSC | Wirkung |
|---|---|
| **Teamarzt** | Beschleunigt die Heilung pro Tag eines Spielers deutlich. |
| **Buchhalter** | Verbessert das passive Einkommen des Teams und reduziert dessen Ausgaben **prozentual**. |
| **Fixer** | Kann angesprochen werden, um „externe Kräfte“ (Shadowrunner) für **Sabotageaktionen** anzuheuern – wahlweise **vor oder während eines Spiels**. |
| **– weitere –** | Noch zu definieren. |

**Offene Fragen:** Anheuer-Kosten/Gehalt pro Zyklus? Obergrenze an NSC je Team? Wie verhält sich die **Fixer-Sabotage** zu den Regeln (`6_Die Regeln des Spiels.md`: Verletzungsart „Outside Interference“, Siegbedingung 3 „Schiedsrichter-Abbruch“)?

> ❌ **Status:** Vorschlag, nicht beschlossen – kein Code.

---

## Refactorings & Optimierungen

Priorität: Crash- und Konsistenz-Potenziale zuerst, dann Performance und Wartbarkeit. Alle Angaben beziehen sich auf den Code-Stand vom 30.08.2026.

### 1. 🔴 `getTeamPosition()` erzeugt `RangeError`-Potenzial

`ProviderTeam.getTeamPosition()` gibt `-1` zurück, wenn das Team nicht in `_teams` steht. `screen_team_editor.dart` (Zeilen 28–29) reicht diesen Wert direkt an `teams.elementAt(teamIndex)` weiter → **Absturz** bei veralteter Auswahl. Auch im Provider selbst wird `_teams[getTeamPosition(teamItem)]` mehrfach ungeprüft indexiert.

```dart
// provider_team.dart – prüfender Lookup statt nacktem Index
ObjectTeam? teamById(int id) {
  final index = _teams.indexWhere((t) => t.id == id);
  return index < 0 ? null : _teams[index];
}
```

Im Editor diese Methode als Quelle der Wahrheit nutzen und auf `null` reagieren (Fehlermeldung + zurück).

### 2. 🔴 Zwei Datenquellen im Team-Editor

`ScreenTeamEditor` mischt `widget.selectedTeam` (u. a. `ListView.builder`-`itemCount` und `listItem`) mit `currentTeam` aus `context.watch<ProviderTeam>()`. Der Provider wird durch Markt-/Kapitäns-Aktionen aktualisiert, `widget.selectedTeam` bleibt die **alte Instanz** → die Kaderliste kann veraltete Spieler/Positionen rendern.

**Fix:** eine Quelle der Wahrheit: `teamById(widget.selectedTeam.id)` aus `ProviderTeam` verwenden und überall dieselbe Instanz nutzen (deckt sich mit Refactoring 1).

### 3. 🟡 `TextEditingController` wird nie disposen

`showChangeNameDialog` (Zeile 154) erzeugt pro Öffnen einen Controller und gibt ihn nie frei – ein kleines, bei häufigem Umbenennen messbares Memory-Leak.

```dart
final controller = TextEditingController(text: currentTeam.name);
final newName = await showDialog<String>(...);
controller.dispose();
```

Alternativ `TextFormField(initialValue: …)` ganz ohne Controller.

### 4. 🟡 Umbenennen: erst persistieren, dann übernehmen

Der aktuelle Ablauf mutiert `currentTeam.name` per `setState` und schließt den Dialog, **bevor** `updateTeamInDatabase` läuft. Schlägt das DB-Update fehl (Fehler wird nur `debugPrint`-et), zeigt die UI den neuen Namen, die Datenbank bleibt alt.

**Fix:** erst persistieren, dann lokal übernehmen; bei Fehler den alten Namen behalten und eine SnackBar mit Retry anbieten. Zusätzlich den Confirm-Button während des `await` deaktivieren (Doppel-Klick).

### 5. 🟡 Zwei DB-`UPDATE`s pro Kaderänderung

`addCharacterToTeam` / `modifyCharacterInTeam` / `removeCharacterFromTeam` rufen `updateTeamInDatabase` **und** `_syncReadyForBattle` (→ `setTeamReadyForBattle`) auf – also zwei aufeinanderfolgende `UPDATE`s in Supabase.

**Fix:** `ready_for_battle` in `_teamRowPayload` aufnehmen und in **einem** `UPDATE` persistieren; `_syncReadyForBattle` entfällt.

### 6. 🟡 `readyForBattle`-Prüfung doppelt gepflegt

Der Editor (Zeile 32, `currentTeam.isTeamValid && currentTeam.hasCaptain`) berechnet die Bereitschaft selbst; `ObjectReferee.setTeamReadyForBattle` (Zeilen 21–32) prüft exakt dasselbe. Beide Stellen können auseinanderlaufen.

```dart
// object_team.dart – ein zentraler Getter
bool get isReadyForBattle => isTeamValid && hasCaptain;
```

Editor **und** `ObjectReferee` nutzen künftig nur noch diesen Getter.

### 7. 🟡 Kein Unentschieden-Pfad in der Ergebnis-Erfassung

`TeamMatchRecord.drawn` und `recordDraw()` existieren, aber `recordMatchResult({winner, loser})` kennt nur Sieg/Niederlage. Ein beidseitiger Wipeout (Siegbedingung 4, siehe `6_Die Regeln des Spiels.md`, offener Punkt 17) kann dadurch nie eingetragen werden.

**Fix:** API auf drei Fälle erweitern, z. B. `recordMatchOutcome(winner, loser, {bool drawn = false})` bzw. `recordDraw(teamA, teamB)`, und in `ObjectReferee.endMatch` anbinden.

### 8. 🟢 Performance & Wartbarkeit

- `ObjectTeam.players` erzeugt **bei jedem Zugriff** eine neue `List.unmodifiable`-Kopie. Eine schreibgeschützte Sicht ohne Kopie ist `UnmodifiableListView(_players)` (mit `import 'dart:collection';`) – für lange Kaderlisten spürbar.
- Doppelte Klammern in `const Icon((Icons.insert_chart_outlined_sharp))` (Zeile 145).
- `showChangeNameDialog(context, currentTeam)` nimmt das Team aus dem Widget-State, obwohl es auch über die Provider-Instanz erreichbar wäre – nach Refactoring 2 ist der Parameter verzichtbar.
- TODO in Zeile 72 („clicking the widget to upload an image crashes the App“) – als eigenes Ticket führen und den Upload-Pfad reproduzieren.

---

## Offene Punkte

| Punkt | Bemerkung |
|---|---|
| **Teams erstellen/löschen ohne UI** | `addTeam` / `removeTeam` haben keinen Aufrufer – Dialog/Screen fehlt. |
| **Draw-Persistenz** | `TeamMatchRecord.drawn` an `endMatch` / `recordMatchResult` anbinden (offener Punkt 17 in `6_Die Regeln des Spiels.md`). |
| **Logo-Upload-Crash** | TODO in `screen_team_editor.dart` reproduzieren und beheben. |
| **DB-Fehler still** | `updateTeamInDatabase` & Co. loggen nur via `debugPrint`; die UI zeigt keine Fehler und keinen Rollback an. |
| **UUID als Primär-ID** | Offener Punkt aus `4_Object_Team.md`: `dbId` langfristig zur primären, stabilen ID machen. |
| **Passives Einkommen/Heilung verbindlich machen** | Täglich 06:00 UTC: `100 + 100 × Qualität` Nuyen + eine Verletzungsstufe. Klären: Gilt die Heilung auch für `dead`/`overkilled` (Konflikt mit der Sani-Rettungs-Kette)? Ist 06:00 UTC der verbindliche Zeitpunkt („GMZ“ im Vorschlag)? |
| **NSC-Modell & Anheuerung** | Zentrale Service-NPC-DB (`service_npcs`) für anheuerbare NSC (Teamarzt, Buchhalter, Fixer, …): Kosten, Obergrenze, Vertrag/Besitz, Würfelproben, Fixer-Sabotage vs. „Outside Interference“/„Schiedsrichter-Abbruch“. |

---

## Nächste Schritte

| # | Punkt | Status |
|---|---|---|
| 1 | `teamById()`-Guard und Editor auf eine Datenquelle umstellen (Refactorings 1 + 2) | ❌ |
| 2 | `ObjectTeam.isReadyForBattle` als gemeinsame Prüfstelle in Editor und `ObjectReferee` (Refactoring 6) | ❌ |
| 3 | `ready_for_battle` in `_teamRowPayload` aufnehmen – ein `UPDATE` statt zwei (Refactoring 5) | ❌ |
| 4 | Rename-Flow: erst persistieren, dann übernehmen; Controller disposen (Refactorings 3 + 4) | ❌ |
| 5 | `UnmodifiableListView` + Kosmetik (Refactoring 8) | ❌ |
| 6 | Draw-Fall in `recordMatchResult` / `endMatch` (Refactoring 7) | ❌ |
| 7 | UI für Team-Erstellen/-Löschen ergänzen (bisher kein Aufrufer für `addTeam`/`removeTeam`) | ❌ |
| 8 | Logo-Upload-Crash (TODO) beheben | ❌ |
| 9 | Passives Einkommen & passive Heilung umsetzen (täglicher Zyklus, `100 + 100 × Qualität`, eine Stufe Heilung; NSC-Teamarzt als Modifikator) | ❌ |
| 10 | NSC-Umsetzung: zentrale Service-NPC-DB + Anheuer-/Vertrags-Modell + erste Rollen (Teamarzt, Buchhalter, Fixer) | ❌ |

---

*Stand: 30.08.2026*