import 'dart:math';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/ub_player.dart';

import 'dice_roller.dart';
//import 'equipment.dart';
//import 'ub_player.dart';

enum CombatAction {
  attack, // Normale Attacke
  fullAuto, // Vollautomatisch (-2 Pool, +2 Schaden)
  calledShot, // Gezielter Schuss (-4 Pool, Effekt abhängig)
  meleeAttack, // Nahkampf
  dodge, // Ausweichen (volle Verteidigung)
  takeCover, // Deckung suchen
  reload, // Nachladen
  aim, // Zielen (+1 Pool pro Aktion, max +3)
  useSkill, // Fertigkeit einsetzen (z.B. Erste Hilfe)
}

enum CombatRange {
  close, // Nah (0-10m)
  medium, // Mittel (11-50m)
  long, // Fern (51-100m)
  extreme, // Extrem (101+m)
}

class Combatant {
  final UbPlayer player;
  int currentInitiative;
  int currentInitiativeScore;
  int initiativePass; // Aktueller Initiative-Durchgang
  int wounds; // Wundmalus
  bool isActing;
  bool hasActedThisPass;

  // Temporäre Kampfmodifikatoren
  int defenseModifier;
  int attackModifier;
  bool isInCover;
  int aimBonus;

  Combatant({
    required this.player,
    this.currentInitiative = 0,
    this.currentInitiativeScore = 0,
    this.initiativePass = 0,
    this.wounds = 0,
    this.isActing = true,
    this.hasActedThisPass = false,
    this.defenseModifier = 0,
    this.attackModifier = 0,
    this.isInCover = false,
    this.aimBonus = 0,
  });

  int get totalDefensePool {
    int pool = player.reaction + player.intuition;
    pool += defenseModifier;
    pool -= wounds;
    if (isInCover) pool += 4;
    return pool.clamp(0, 40);
  }

  int get totalAttackPool {
    int pool =
        player.agility +
        player.skillManager.getSkillPool(player, 'Schusswaffen');
    pool += attackModifier;
    pool += aimBonus;
    pool -= wounds;
    return pool.clamp(0, 40);
  }

  void resetForNewPass() {
    hasActedThisPass = false;
  }

  void applyDamage(int physicalDamage, int mentalDamage) {
    player.bodyDamage += physicalDamage;
    player.mentalDamage += mentalDamage;
    wounds = player.woundPenalty;
  }

  bool get isConscious => player.isConscious;
  bool get isDead => player.isDead;

  @override
  String toString() => player.name;
}

class AttackResult {
  final Combatant attacker;
  final Combatant defender;
  final bool hit;
  final int netHits;
  final int damageValue;
  final int resistedDamage;
  final int finalDamage;
  final bool isCriticalHit;
  final CombatAction action;
  final String message;

  AttackResult({
    required this.attacker,
    required this.defender,
    required this.hit,
    required this.netHits,
    required this.damageValue,
    required this.resistedDamage,
    required this.finalDamage,
    required this.isCriticalHit,
    required this.action,
    required this.message,
  });

  bool get isLethal => finalDamage > 0;

  String get summary {
    if (!hit) return "Verfehlt! 🎯";
    if (isCriticalHit) return "Kritischer Treffer! 💥";
    if (finalDamage > 0) return "Treffer! $finalDamage Schaden";
    return "Abgewehrt! 🛡️";
  }
}

class CombatRound {
  final int roundNumber;
  final List<Combatant> combatants;
  final List<AttackResult> attacks;
  final DateTime timestamp;

  CombatRound({
    required this.roundNumber,
    required this.combatants,
    required this.attacks,
    required this.timestamp,
  });
}

class CombatSimulator extends ChangeNotifier {
  final DiceRoller _diceRoller = DiceRoller();
  final Random _random = Random();

  final List<Combatant> _combatants = [];
  final List<CombatRound> _roundHistory = [];
  int _currentRound = 0;
  bool _combatActive = false;
  Combatant? _currentActor;
  final List<Combatant> _initiativeOrder = [];
  int _currentInitiativePass = 0;

  List<Combatant> get combatants => List.unmodifiable(_combatants);
  List<CombatRound> get roundHistory => List.unmodifiable(_roundHistory);
  bool get combatActive => _combatActive;
  Combatant? get currentActor => _currentActor;
  List<Combatant> get initiativeOrder => List.unmodifiable(_initiativeOrder);
  int get currentRound => _currentRound;
  int get currentInitiativePass => _currentInitiativePass;

  void addCombatant(UbPlayer player) {
    _combatants.add(Combatant(player: player));
    notifyListeners();
  }

  void removeCombatant(Combatant combatant) {
    _combatants.remove(combatant);
    if (_currentActor == combatant) _currentActor = null;
    notifyListeners();
  }

  void clearCombatants() {
    _combatants.clear();
    _initiativeOrder.clear();
    _currentActor = null;
    notifyListeners();
  }

  /// Initiative für alle Kämpfer würfeln
  void rollInitiative() {
    for (var combatant in _combatants) {
      int initiative = combatant.player.intuition + combatant.player.reaction;
      int diceRoll = _random.nextInt(6) + 1;
      combatant.currentInitiative = initiative;
      combatant.currentInitiativeScore = initiative + diceRoll;
      combatant.initiativePass = 0;
      combatant.hasActedThisPass = false;
    }

    _sortInitiativeOrder();
    _currentInitiativePass = 1;
    _combatActive = true;
    _updateCurrentActor();
    notifyListeners();
  }

  void _sortInitiativeOrder() {
    _initiativeOrder.sort(
      (a, b) => b.currentInitiativeScore.compareTo(a.currentInitiativeScore),
    );
  }

  void _updateCurrentActor() {
    // Finde den nächsten Kämpfer, der noch nicht in diesem Durchgang gehandelt hat
    for (var combatant in _initiativeOrder) {
      if (!combatant.hasActedThisPass && combatant.isConscious) {
        _currentActor = combatant;
        notifyListeners();
        return;
      }
    }

    // Wenn alle gehandelt haben, nächsten Initiative-Durchgang starten
    _advanceToNextPass();
  }

  void _advanceToNextPass() {
    // Neue Initiative für neuen Durchgang (nur -10 für alle)
    for (var combatant in _initiativeOrder) {
      combatant.currentInitiativeScore -= 10;
      combatant.hasActedThisPass = false;

      // Wenn Initiative <= 0, ist der Kämpfer für diese Runde fertig
      if (combatant.currentInitiativeScore <= 0) {
        combatant.hasActedThisPass = true;
      }
    }

    _currentInitiativePass++;

    // Prüfen, ob noch jemand handeln kann
    bool anyoneCanAct = _initiativeOrder.any(
      (c) => !c.hasActedThisPass && c.isConscious,
    );

    if (anyoneCanAct) {
      _sortInitiativeOrder();
      _updateCurrentActor();
    } else {
      // Nächste Kampfrunde
      _advanceToNextRound();
    }
  }

  void _advanceToNextRound() {
    _currentRound++;
    _currentInitiativePass = 0;

    // Initiative für neue Runde neu würfeln
    for (var combatant in _combatants) {
      int initiative = combatant.player.intuition + combatant.player.reaction;
      int diceRoll = _random.nextInt(6) + 1;
      combatant.currentInitiativeScore = initiative + diceRoll;
      combatant.hasActedThisPass = false;
    }

    _sortInitiativeOrder();
    _currentInitiativePass = 1;
    _updateCurrentActor();
    notifyListeners();
  }

  /// Führt eine Angriffsaktion aus
  AttackResult performAttack(
    Combatant attacker,
    Combatant defender, {
    CombatAction action = CombatAction.attack,
    CombatRange range = CombatRange.medium,
    int customModifier = 0,
  }) {
    // Berechne Angriffspool
    int attackPool = _calculateAttackPool(
      attacker,
      action,
      range,
      customModifier,
    );

    // Berechne Verteidigungspool
    int defensePool = _calculateDefensePool(defender, action);

    // Würfle Angriff
    DiceResult attackRoll = _diceRoller.rollDice(
      pool: attackPool,
      recordHistory: false,
    );

    // Würfle Verteidigung
    DiceResult defenseRoll = _diceRoller.rollDice(
      pool: defensePool,
      recordHistory: false,
    );

    // Nettoerfolge berechnen
    int netHits = (attackRoll.successes - defenseRoll.successes).clamp(0, 999);
    bool hit = netHits > 0;

    // Schaden berechnen
    int baseDamage = _getBaseDamage(attacker, action);
    int damageValue = baseDamage + netHits;

    // Schadenswiderstand
    int resistedDamage = 0;
    int finalDamage = 0;
    bool isCriticalHit = attackRoll.sixes >= 3 && hit;

    if (hit) {
      int resistancePool = defender.player.body + defender.player.armor;
      DiceResult resistanceRoll = _diceRoller.rollDice(
        pool: resistancePool,
        recordHistory: false,
      );
      resistedDamage = resistanceRoll.successes;
      finalDamage = (damageValue - resistedDamage).clamp(0, 999);

      // Schaden anwenden
      if (finalDamage > 0) {
        defender.applyDamage(finalDamage, 0);
      }
    }

    // Nachricht generieren
    String message = _generateAttackMessage(
      attacker,
      defender,
      hit,
      netHits,
      finalDamage,
      isCriticalHit,
    );

    // Reset Aktion-Modifikatoren
    attacker.aimBonus = 0;
    attacker.hasActedThisPass = true;

    AttackResult result = AttackResult(
      attacker: attacker,
      defender: defender,
      hit: hit,
      netHits: netHits,
      damageValue: damageValue,
      resistedDamage: resistedDamage,
      finalDamage: finalDamage,
      isCriticalHit: isCriticalHit,
      action: action,
      message: message,
    );

    // Rundenverlauf speichern
    _addAttackToHistory(result);

    notifyListeners();

    // Nach dem Angriff zum nächsten Akteur wechseln
    _updateCurrentActor();

    return result;
  }

  int _calculateAttackPool(
    Combatant attacker,
    CombatAction action,
    CombatRange range,
    int customModifier,
  ) {
    int pool = attacker.totalAttackPool;

    // Aktionsmodifikatoren
    switch (action) {
      case CombatAction.fullAuto:
        pool -= 2;
        break;
      case CombatAction.calledShot:
        pool -= 4;
        break;
      case CombatAction.aim:
        pool = 0; // Zielen gibt keinen sofortigen Angriff
        break;
      default:
        break;
    }

    // Reichweitenmodifikatoren
    switch (range) {
      case CombatRange.close:
        pool += 2;
        break;
      case CombatRange.long:
        pool -= 2;
        break;
      case CombatRange.extreme:
        pool -= 4;
        break;
      default:
        break;
    }

    pool += customModifier;
    return pool.clamp(1, 40);
  }

  int _calculateDefensePool(Combatant defender, CombatAction action) {
    int pool = defender.totalDefensePool;

    if (action == CombatAction.dodge) {
      pool += 4; // Volle Verteidigung
    }

    return pool.clamp(0, 40);
  }

  int _getBaseDamage(Combatant attacker, CombatAction action) {
    // Basis-Schaden (später aus Waffe auslesen)
    int baseDamage = 6;

    if (action == CombatAction.fullAuto) {
      baseDamage += 2;
    }

    return baseDamage;
  }

  String _generateAttackMessage(
    Combatant attacker,
    Combatant defender,
    bool hit,
    int netHits,
    int damage,
    bool isCritical,
  ) {
    if (!hit) {
      return "${attacker.player.name} verfehlt ${defender.player.name}!";
    }

    if (isCritical) {
      return "⭐ KRITISCHER TREFFER! ${attacker.player.name} trifft ${defender.player.name} für $damage Schaden!";
    }

    if (damage > 0) {
      return "${attacker.player.name} trifft ${defender.player.name} für $damage Schaden ($netHits Nettoerfolge)!";
    }

    return "${attacker.player.name} trifft, aber ${defender.player.name} wehrt den Schaden komplett ab!";
  }

  void _addAttackToHistory(AttackResult result) {
    // Prüfen, ob bereits eine Runde existiert
    if (_roundHistory.isEmpty ||
        _roundHistory.last.roundNumber != _currentRound) {
      _roundHistory.add(
        CombatRound(
          roundNumber: _currentRound,
          combatants: List.from(_combatants),
          attacks: [],
          timestamp: DateTime.now(),
        ),
      );
    }

    _roundHistory.last.attacks.add(result);
    notifyListeners();
  }

  /// Führt eine Nicht-Angriffsaktion aus (Zielen, Nachladen, etc.)
  void performNonCombatAction(Combatant actor, CombatAction action) {
    switch (action) {
      case CombatAction.aim:
        actor.aimBonus = (actor.aimBonus + 1).clamp(0, 3);
        break;
      case CombatAction.takeCover:
        actor.isInCover = true;
        break;
      case CombatAction.reload:
        // Munition nachladen
        break;
      default:
        break;
    }

    actor.hasActedThisPass = true;
    _updateCurrentActor();
    notifyListeners();
  }

  /// Gibt eine Statusübersicht aller Kämpfer zurück
  String getCombatStatus() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("=== Kampfrunde $_currentRound ===");
    buffer.writeln("Initiative-Durchgang: $_currentInitiativePass");
    buffer.writeln();

    for (var combatant in _initiativeOrder) {
      String status = combatant.isConscious ? "👍" : "💀";
      buffer.writeln(
        "$status ${combatant.player.name}: Initiative ${combatant.currentInitiativeScore}",
      );
      buffer.writeln(
        "   Schaden: ${combatant.player.bodyDamage}/${combatant.player.maxPhysicalDamage}",
      );
      buffer.writeln("   Wundmalus: -${combatant.wounds}");
    }

    return buffer.toString();
  }

  /// Beendet den Kampf und gibt eine Zusammenfassung
  CombatSummary endCombat() {
    _combatActive = false;

    int totalAttacks = _roundHistory.fold(
      0,
      (sum, round) => sum + round.attacks.length,
    );
    int totalHits = _roundHistory.fold(
      0,
      (sum, round) => sum + round.attacks.where((a) => a.hit).length,
    );
    int totalDamage = _roundHistory.fold(
      0,
      (sum, round) => sum + round.attacks.fold(0, (s, a) => s + a.finalDamage),
    );

    List<Combatant> survivors = _combatants.where((c) => !c.isDead).toList();
    List<Combatant> casualties = _combatants.where((c) => c.isDead).toList();

    return CombatSummary(
      rounds: _currentRound,
      totalAttacks: totalAttacks,
      totalHits: totalHits,
      totalDamage: totalDamage,
      survivors: survivors,
      casualties: casualties,
    );
  }
}

class CombatSummary {
  final int rounds;
  final int totalAttacks;
  final int totalHits;
  final int totalDamage;
  final List<Combatant> survivors;
  final List<Combatant> casualties;

  CombatSummary({
    required this.rounds,
    required this.totalAttacks,
    required this.totalHits,
    required this.totalDamage,
    required this.survivors,
    required this.casualties,
  });

  double get hitRate => totalAttacks > 0 ? totalHits / totalAttacks : 0;

  String get summary {
    return """
    === Kampf beendet ===
    Runden: $rounds
    Angriffe: $totalAttacks
    Treffer: $totalHits (${(hitRate * 100).toStringAsFixed(1)}%)
    Gesamtschaden: $totalDamage
    
    Überlebende: ${survivors.map((c) => c.player.name).join(', ')}
    Verluste: ${casualties.map((c) => c.player.name).join(', ')}
    """;
  }
}
