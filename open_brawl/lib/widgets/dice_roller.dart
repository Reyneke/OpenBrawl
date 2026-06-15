import 'dart:math';

import 'package:flutter/material.dart';

class DiceResult {
  final List<int> rolls;
  final int successes;
  final bool isGlitch;
  final bool isCriticalGlitch;
  final int ones;
  final int fives;
  final int sixes;
  final int rerolledSixes;

  DiceResult({
    required this.rolls,
    required this.successes,
    required this.isGlitch,
    required this.isCriticalGlitch,
    required this.ones,
    required this.fives,
    required this.sixes,
    this.rerolledSixes = 0,
  });

  bool get hasGlitch => isGlitch || isCriticalGlitch;
  bool get isSuccess => successes > 0;

  String get summary {
    if (isCriticalGlitch) return "KRITISCHER GLITCH! 💀";
    if (isGlitch) return "Glitch! 🤡";
    if (successes >= 5) return "Phänomenal! ⭐";
    if (successes >= 3) return "Gut gemacht! 👍";
    if (successes >= 1) return "Erfolg! ✓";
    return "Fehlschlag! ✗";
  }

  @override
  String toString() {
    return 'DiceResult(rolls: $rolls, successes: $successes, glitch: $isGlitch, critical: $isCriticalGlitch)';
  }
}

class DiceRoller extends ChangeNotifier {
  final Random _random = Random();

  final List<DiceResult> _history = [];
  int _currentPool = 0;
  int _threshold = 1;
  int _explodingSixes =
      0; // Wie oft werden Sechsen wiederholt (0 = nie, 1 = einmal, etc.)

  List<DiceResult> get history => List.unmodifiable(_history);
  int get currentPool => _currentPool;
  int get threshold => _threshold;

  void setPool(int pool) {
    _currentPool = pool.clamp(1, 40);
    notifyListeners();
  }

  void setThreshold(int threshold) {
    _threshold = threshold.clamp(1, 20);
    notifyListeners();
  }

  void setExplodingSixes(int count) {
    _explodingSixes = count.clamp(0, 3);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Hauptwürfel-Methode für Shadowrun 5
  DiceResult rollDice({int? pool, int? threshold, bool recordHistory = true}) {
    final int diceCount = pool ?? _currentPool;
    final int requiredThreshold = threshold ?? _threshold;

    List<int> allRolls = [];
    int totalSuccesses = 0;
    int totalOnes = 0;
    int totalFives = 0;
    int totalSixes = 0;
    int totalRerolls = 0;

    // Ursprünglicher Wurf
    List<int> initialRolls = _rollDiceList(diceCount);
    allRolls.addAll(initialRolls);

    // Erfolge und 1er zählen
    for (int roll in initialRolls) {
      if (roll >= 5) totalSuccesses++;
      if (roll == 1) totalOnes++;
      if (roll == 5) totalFives++;
      if (roll == 6) totalSixes++;
    }

    // Explodierende Sechsen (wenn aktiviert)
    if (_explodingSixes > 0) {
      List<int> sixesToReroll = initialRolls.where((r) => r == 6).toList();

      for (
        int explosionLevel = 0;
        explosionLevel < _explodingSixes && sixesToReroll.isNotEmpty;
        explosionLevel++
      ) {
        List<int> newRolls = _rollDiceList(sixesToReroll.length);
        allRolls.addAll(newRolls);
        totalRerolls += newRolls.length;

        // Neue Erfolge zählen
        for (int roll in newRolls) {
          if (roll >= 5) totalSuccesses++;
          if (roll == 1) totalOnes++;
          if (roll == 5) totalFives++;
          if (roll == 6) totalSixes++;
        }

        // Nächste Generation Sechsen
        sixesToReroll = newRolls.where((r) => r == 6).toList();
      }
    }

    // Glitch-Erkennung (mehr als die Hälfte der Würfel sind 1er)
    bool isGlitch = totalOnes > (allRolls.length / 2);

    // Kritischer Glitch (Glitch UND keine Erfolge)
    bool isCriticalGlitch = isGlitch && totalSuccesses == 0;

    final result = DiceResult(
      rolls: allRolls,
      successes: totalSuccesses,
      isGlitch: isGlitch,
      isCriticalGlitch: isCriticalGlitch,
      ones: totalOnes,
      fives: totalFives,
      sixes: totalSixes,
      rerolledSixes: totalRerolls,
    );

    if (recordHistory) {
      _history.add(result);
      notifyListeners();
    }

    return result;
  }

  List<int> _rollDiceList(int count) {
    return List.generate(count, (_) => _random.nextInt(6) + 1);
  }

  /// Proben mit automatischer Berechnung (Skill + Attribut)
  DiceResult rollSkillCheck(
    int attributeValue,
    int skillRank, {
    int? modifier,
  }) {
    int pool = attributeValue + skillRank;
    if (modifier != null) pool += modifier;
    return rollDice(pool: pool.clamp(1, 40));
  }

  /// Kampfprobe (Angriff)
  DiceResult rollAttack(
    int agility,
    int weaponSkill,
    int weaponAccuracy, {
    int? modifier,
    int? defensePool,
  }) {
    int pool = agility + weaponSkill;
    if (modifier != null) pool += modifier;

    DiceResult attackResult = rollDice(
      pool: pool.clamp(1, 40),
      recordHistory: false,
    );

    // Begrenzung durch Waffengenauigkeit
    int cappedSuccesses = attackResult.successes > weaponAccuracy
        ? weaponAccuracy
        : attackResult.successes;

    // Verteidigungswurf
    int netHits = 0;
    if (defensePool != null && defensePool > 0) {
      DiceResult defenseResult = rollDice(
        pool: defensePool,
        recordHistory: false,
      );
      netHits = (cappedSuccesses - defenseResult.successes).clamp(0, 999);
    } else {
      netHits = cappedSuccesses;
    }

    return DiceResult(
      rolls: attackResult.rolls,
      successes: cappedSuccesses,
      isGlitch: attackResult.isGlitch,
      isCriticalGlitch: attackResult.isCriticalGlitch,
      ones: attackResult.ones,
      fives: attackResult.fives,
      sixes: attackResult.sixes,
      rerolledSixes: attackResult.rerolledSixes,
    );
  }

  /// Schadenswiderstand (Körper + Rüstung vs. Schadenscode)
  int rollDamageResistance(
    int body,
    int armor,
    int damageValue,
    int armorPenetration,
  ) {
    int modifiedArmor = (armor - armorPenetration).clamp(0, 999);
    int resistancePool = body + modifiedArmor;

    DiceResult resistance = rollDice(
      pool: resistancePool,
      recordHistory: false,
    );

    int netDamage = (damageValue - resistance.successes).clamp(0, 999);
    return netDamage;
  }

  /// Initiative würfeln (Intuition + Reaktion + 1W6)
  int rollInitiative(int intuition, int reaction) {
    int baseInitiative = intuition + reaction;
    int diceRoll = _random.nextInt(6) + 1;
    return baseInitiative + diceRoll;
  }
}

// Erweiterte DiceRoller mit zusätzlichen Utilities
class ShadowrunDiceRoller extends DiceRoller {
  /// Würfelt eine bestimmte Anzahl von Würfeln und gibt die Details aus
  Future<DiceResult> rollWithAnimation(
    int pool, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    // Für Animationen - hier simuliert
    await Future.delayed(duration);
    return rollDice(pool: pool);
  }

  /// Berechnet den durchschnittlichen Erfolgswert für einen Pool
  double averageSuccesses(int pool) {
    return pool * (1 / 3); // 5 und 6 sind Erfolge = 2/6 = 1/3
  }

  /// Wahrscheinlichkeit für mindestens X Erfolge
  double probabilityOfSuccess(int pool, int requiredSuccesses) {
    // Vereinfachte Berechnung - in einer echten App würdest du hier
    // eine Binomialverteilung implementieren
    if (requiredSuccesses <= 0) return 1.0;
    if (pool < requiredSuccesses) return 0.0;

    // Faustregel: ~33% Erfolgschance pro Würfel
    double chance = 1.0;
    for (int i = 0; i < requiredSuccesses; i++) {
      chance *= (pool - i) / pool * 0.33;
    }
    return chance.clamp(0.0, 1.0);
  }
}
