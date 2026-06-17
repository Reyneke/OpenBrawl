import 'dart:math';

import 'package:flutter/material.dart';
import 'package:open_brawl/widgets/dice_roller.dart';

// ============================================================
// ENUMS & BASISKLASSEN
// ============================================================

enum MagicUserType {
  mundane, // Normaler Mensch (keine Magie)
  adept, // Adept (magische Körperverbesserung)
  magician, // Magier (vollwertiger Zauberwirker)
  mysticAdept, // Mystischer Adept (Mischung)
  technomancer, // Technomancer (Resonanz)
}

enum SpellCategory {
  combat, // Kampfzauber
  detection, // Wahrnehmungszauber
  health, // Heilzauber
  illusion, // Illusionszauber
  manipulation, // Manipulationszauber
}

enum SpellRange {
  touch, // Berührung
  lineOfSight, // Sichtlinie
  lineOfSightEnhanced, // Verstärkte Sichtlinie (via Spiegel, Kameras)
  area, // Flächenzauber
}

enum SpellDuration {
  instant, // Sofort
  sustained, // Aufrechterhalten
  permanent, // Permanent
}

enum DamageType {
  physical, // Körperlicher Schaden
  stun, // Betäubungsschaden
  direct, // Direkter Schaden (keine Widerstandsprobe)
}

enum AdeptPowerCategory {
  physical, // Körperliche Verbesserung
  mental, // Geistige Verbesserung
  stealth, // Heimlichkeit
  combat, // Kampf
  social, // Sozial
}

enum ComplexFormCategory {
  hacking, // Hacking
  sleaze, // Heimlichkeit
  attack, // Angriff
  perception, // Wahrnehmung
}

// ============================================================
// ZAUBER KLASSE
// ============================================================

class Spell {
  final String name;
  final String description;
  final SpellCategory category;
  final SpellRange range;
  final SpellDuration duration;
  final DamageType damageType;
  final int drainValue; // Entzugswert
  final int force; // Kraft (min 1, max Magic x 2)
  final bool isPhysical;

  Spell({
    required this.name,
    required this.description,
    required this.category,
    required this.range,
    required this.duration,
    this.damageType = DamageType.stun,
    this.drainValue = 2,
    this.force = 3,
    this.isPhysical = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.index,
      'range': range.index,
      'duration': duration.index,
      'damageType': damageType.index,
      'drainValue': drainValue,
      'force': force,
      'isPhysical': isPhysical,
    };
  }

  factory Spell.fromMap(Map<String, dynamic> map) {
    return Spell(
      name: map['name'] as String,
      description: map['description'] as String,
      category: SpellCategory.values[map['category'] as int],
      range: SpellRange.values[map['range'] as int],
      duration: SpellDuration.values[map['duration'] as int],
      damageType: DamageType.values[map['damageType'] as int],
      drainValue: map['drainValue'] as int,
      force: map['force'] as int,
      isPhysical: map['isPhysical'] as bool,
    );
  }
}

// ============================================================
// ADEPTENKRAFT KLASSE
// ============================================================

class AdeptPower {
  final String name;
  final String description;
  final AdeptPowerCategory category;
  final double powerPointCost; // Kosten in Magiepunkten
  int level; // Stufe (1-6)

  AdeptPower({
    required this.name,
    required this.description,
    required this.category,
    required this.powerPointCost,
    this.level = 1,
  });

  int get totalCost => (powerPointCost * level).ceil();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.index,
      'powerPointCost': powerPointCost,
      'level': level,
    };
  }

  factory AdeptPower.fromMap(Map<String, dynamic> map) {
    return AdeptPower(
      name: map['name'] as String,
      description: map['description'] as String,
      category: AdeptPowerCategory.values[map['category'] as int],
      powerPointCost: map['powerPointCost'] as double,
      level: map['level'] as int,
    );
  }
}

// ============================================================
// KOMPLEXE FORM (TECHNOMANCER) KLASSE
// ============================================================

class ComplexForm {
  final String name;
  final String description;
  final ComplexFormCategory category;
  final int fadeValue; // Verblassungswert (wie Entzug)
  int level; // Stufe

  ComplexForm({
    required this.name,
    required this.description,
    required this.category,
    required this.fadeValue,
    this.level = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.index,
      'fadeValue': fadeValue,
      'level': level,
    };
  }

  factory ComplexForm.fromMap(Map<String, dynamic> map) {
    return ComplexForm(
      name: map['name'] as String,
      description: map['description'] as String,
      category: ComplexFormCategory.values[map['category'] as int],
      fadeValue: map['fadeValue'] as int,
      level: map['level'] as int,
    );
  }
}

// ============================================================
// ZAUBER-/RESONANZERGEBNIS
// ============================================================

class SpellCastingResult {
  final Spell? spell;
  final ComplexForm? complexForm;
  final int force;
  final int successes;
  final int drainValue;
  final int drainResisted;
  final int actualDrain;
  final bool isSuccess;
  final String message;

  SpellCastingResult({
    this.spell,
    this.complexForm,
    required this.force,
    required this.successes,
    required this.drainValue,
    required this.drainResisted,
    required this.actualDrain,
    required this.isSuccess,
    required this.message,
  });

  bool get isOvercast => force > 0; // Vereinfacht
}

// ============================================================
// MAGIE/RESONANZ MANAGER
// ============================================================

class MagicResonanceManager extends ChangeNotifier {
  final DiceRoller _diceRoller = DiceRoller();
  final Random _random = Random();

  // Basiswerte
  int _magic = 1; // Magieattribut (1-6, max 6 + Initiationen)
  int _resonance = 1; // Resonanzattribut (für Technomancer)
  int _initiationGrade = 0; // Initiationsgrad (für Magier)
  int _submersionGrade = 0; // Tauchgrad (für Technomancer)

  // Gelernte Zauber/Kräfte/Formen
  List<Spell> _knownSpells = [];
  List<AdeptPower> _adeptPowers = [];
  List<ComplexForm> _complexForms = [];

  // Verfügbare Magiepunkte (für Adepten)
  double _availablePowerPoints = 6.0;
  double _usedPowerPoints = 0.0;

  MagicUserType _userType = MagicUserType.mundane;

  // Getter
  int get magic => _magic;
  int get resonance => _resonance;
  int get initiationGrade => _initiationGrade;
  int get submersionGrade => _submersionGrade;
  List<Spell> get knownSpells => List.unmodifiable(_knownSpells);
  List<AdeptPower> get adeptPowers => List.unmodifiable(_adeptPowers);
  List<ComplexForm> get complexForms => List.unmodifiable(_complexForms);
  double get availablePowerPoints => _availablePowerPoints;
  double get usedPowerPoints => _usedPowerPoints;
  double get remainingPowerPoints => _availablePowerPoints - _usedPowerPoints;
  MagicUserType get userType => _userType;

  bool get isMagical => _userType != MagicUserType.mundane;
  bool get isTechnomancer => _userType == MagicUserType.technomancer;
  bool get isAdept =>
      _userType == MagicUserType.adept ||
      _userType == MagicUserType.mysticAdept;
  bool get isMagician =>
      _userType == MagicUserType.magician ||
      _userType == MagicUserType.mysticAdept;

  void setMagicUserType(MagicUserType type) {
    _userType = type;
    notifyListeners();
  }

  void setMagic(int value) {
    _magic = value.clamp(1, 6 + _initiationGrade);
    notifyListeners();
  }

  void setResonance(int value) {
    _resonance = value.clamp(1, 6 + _submersionGrade);
    notifyListeners();
  }

  void initiate() {
    _initiationGrade++;
    _magic = (_magic + 1).clamp(1, 6 + _initiationGrade);
    _availablePowerPoints += 1; // Initiierte Adepten bekommen mehr Magiepunkte
    notifyListeners();
  }

  void submerge() {
    _submersionGrade++;
    _resonance = (_resonance + 1).clamp(1, 6 + _submersionGrade);
    notifyListeners();
  }

  // Zauber verwalten
  void learnSpell(Spell spell) {
    if (!_knownSpells.contains(spell)) {
      _knownSpells.add(spell);
      notifyListeners();
    }
  }

  void forgetSpell(Spell spell) {
    _knownSpells.remove(spell);
    notifyListeners();
  }

  // Adeptenkräfte verwalten
  void learnAdeptPower(AdeptPower power) {
    if (remainingPowerPoints >= power.totalCost) {
      _adeptPowers.add(power);
      _usedPowerPoints += power.totalCost;
      notifyListeners();
    }
  }

  void removeAdeptPower(AdeptPower power) {
    _usedPowerPoints -= power.totalCost;
    _adeptPowers.remove(power);
    notifyListeners();
  }

  // Komplexe Formen verwalten
  void learnComplexForm(ComplexForm form) {
    _complexForms.add(form);
    notifyListeners();
  }

  void forgetComplexForm(ComplexForm form) {
    _complexForms.remove(form);
    notifyListeners();
  }

  // ============================================================
  // ZAUBERWIRKEN
  // ============================================================

  SpellCastingResult castSpell(Spell spell, int force, {int? magicBonus}) {
    int effectiveMagic = _magic + (magicBonus ?? 0);
    int maxForce = effectiveMagic * 2;
    int actualForce = force.clamp(1, maxForce);

    // Zauberwurf: Magie + Zauberfertigkeit
    int spellcastingPool = effectiveMagic + _getSpellcastingSkill();

    // Modifikatoren für überladenen Zauber
    bool isOvercast = actualForce > effectiveMagic;
    if (isOvercast) {
      spellcastingPool -= 2; // Erschwernis für überladen
    }

    DiceResult castingRoll = _diceRoller.rollDice(
      pool: spellcastingPool,
      recordHistory: false,
    );
    int successes = castingRoll.successes;

    // Entzug berechnen
    int drainBase = spell.drainValue;
    if (isOvercast) {
      drainBase = actualForce; // Bei überladenen Zaubern ist Entzug = Kraft
    }

    int drainValue = drainBase + (actualForce ~/ 2).floor();

    // Entzugswiderstand: Willenskraft + Logik (oder Konstitution für physische Zauber)
    int drainResistancePool = spell.isPhysical
        ? _getPhysicalDrainPool()
        : _getMentalDrainPool();

    DiceResult drainRoll = _diceRoller.rollDice(
      pool: drainResistancePool,
      recordHistory: false,
    );
    int drainResisted = drainRoll.successes;
    int actualDrain = (drainValue - drainResisted).clamp(0, 999);

    bool isSuccess = successes > 0 && actualDrain < _getMaxDrainTolerance();

    String message = _generateSpellMessage(
      spell,
      actualForce,
      successes,
      actualDrain,
      isSuccess,
    );

    return SpellCastingResult(
      spell: spell,
      force: actualForce,
      successes: successes,
      drainValue: drainValue,
      drainResisted: drainResisted,
      actualDrain: actualDrain,
      isSuccess: isSuccess,
      message: message,
    );
  }

  int _getSpellcastingSkill() {
    // In einer vollständigen Implementierung würde hier die Fertigkeit gelesen
    return 4; // Standardwert
  }

  int _getMentalDrainPool() {
    // Willenskraft + Logik + evtl. Spezialisierung
    return 6; // Platzhalter
  }

  int _getPhysicalDrainPool() {
    // Willenskraft + Konstitution
    return 6; // Platzhalter
  }

  int _getMaxDrainTolerance() {
    // Maximale aufnehmbare Entzugspunkte (sonst Schaden)
    return 8;
  }

  String _generateSpellMessage(
    Spell spell,
    int force,
    int successes,
    int actualDrain,
    bool isSuccess,
  ) {
    if (!isSuccess) {
      if (actualDrain > 0) {
        return "🎭 Zauber fehlgeschlagen! $actualDrain Entzugsschaden erlitten!";
      }
      return "❌ Zauber fehlgeschlagen! Keine Erfolge erzielt.";
    }

    if (actualDrain > 0) {
      return "✨ ${spell.name} erfolgreich (Kraft $force)! $successes Erfolge, aber $actualDrain Entzugsschaden!";
    }

    return "🌟 ${spell.name} erfolgreich (Kraft $force)! $successes Erfolge, Entzug widerstanden!";
  }

  // ============================================================
  // RESONANZ HANDLUNGEN (TECHNOMANCER)
  // ============================================================

  SpellCastingResult useComplexForm(ComplexForm form, int level) {
    int effectiveResonance = _resonance;
    int actualLevel = level.clamp(1, effectiveResonance * 2);

    // Resonanzwurf: Resonanz + Komplexe-Form-Fertigkeit
    int threadingPool = effectiveResonance + _getComplexFormSkill();

    DiceResult threadingRoll = _diceRoller.rollDice(
      pool: threadingPool,
      recordHistory: false,
    );
    int successes = threadingRoll.successes;

    // Verblassung (Fade) berechnen
    int fadeBase = form.fadeValue;
    int fadeValue = fadeBase + (actualLevel ~/ 2).floor();

    // Verblassungswiderstand: Willenskraft + Resonanz
    int fadeResistancePool = _getFadeResistancePool();

    DiceResult fadeRoll = _diceRoller.rollDice(
      pool: fadeResistancePool,
      recordHistory: false,
    );
    int fadeResisted = fadeRoll.successes;
    int actualFade = (fadeValue - fadeResisted).clamp(0, 999);

    bool isSuccess = successes > 0;

    String message = _generateComplexFormMessage(
      form,
      actualLevel,
      successes,
      actualFade,
      isSuccess,
    );

    return SpellCastingResult(
      complexForm: form,
      force: actualLevel,
      successes: successes,
      drainValue: fadeValue,
      drainResisted: fadeResisted,
      actualDrain: actualFade,
      isSuccess: isSuccess,
      message: message,
    );
  }

  int _getComplexFormSkill() {
    return 4; // Standardwert
  }

  int _getFadeResistancePool() {
    // Willenskraft + Resonanz
    return 6; // Platzhalter
  }

  String _generateComplexFormMessage(
    ComplexForm form,
    int level,
    int successes,
    int actualFade,
    bool isSuccess,
  ) {
    if (!isSuccess) {
      if (actualFade > 0) {
        return "💻 Komplexe Form fehlgeschlagen! $actualFade Verblassungsschaden!";
      }
      return "❌ Komplexe Form fehlgeschlagen! Keine Erfolge.";
    }

    if (actualFade > 0) {
      return "🖥️ ${form.name} (Stufe $level) erfolgreich! $successes Erfolge, aber $actualFade Verblassungsschaden!";
    }

    return "🌀 ${form.name} (Stufe $level) erfolgreich! $successes Erfolge, Verblassung widerstanden!";
  }

  // ============================================================
  // INITIALISIERUNG MIT STARTER-INHALT
  // ============================================================

  void initializeStarterSpells() {
    _knownSpells = [
      Spell(
        name: "Feuerball 🔥",
        description: "Ein Feuerball, der in der Ferne explodiert",
        category: SpellCategory.combat,
        range: SpellRange.lineOfSight,
        duration: SpellDuration.instant,
        damageType: DamageType.physical,
        drainValue: 3,
      ),
      Spell(
        name: "Heilung 💚",
        description: "Heilt körperlichen Schaden",
        category: SpellCategory.health,
        range: SpellRange.touch,
        duration: SpellDuration.instant,
        damageType: DamageType.stun,
        drainValue: 2,
      ),
      Spell(
        name: "Unsichtbarkeit 👻",
        description: "Macht das Ziel unsichtbar",
        category: SpellCategory.illusion,
        range: SpellRange.lineOfSight,
        duration: SpellDuration.sustained,
        damageType: DamageType.stun,
        drainValue: 3,
      ),
      Spell(
        name: "Levitation 🧘",
        description: "Lässt das Ziel schweben",
        category: SpellCategory.manipulation,
        range: SpellRange.lineOfSight,
        duration: SpellDuration.sustained,
        damageType: DamageType.stun,
        drainValue: 2,
      ),
    ];
    notifyListeners();
  }

  void initializeStarterAdeptPowers() {
    _adeptPowers = [
      AdeptPower(
        name: "Verbesserte Reflexe ⚡",
        description: "+1 Initiative pro Stufe",
        category: AdeptPowerCategory.physical,
        powerPointCost: 1.0,
      ),
      AdeptPower(
        name: "Verbesserte Geschicklichkeit 🏃",
        description: "+1 Beweglichkeit pro Stufe",
        category: AdeptPowerCategory.physical,
        powerPointCost: 0.5,
      ),
      AdeptPower(
        name: "Todesblick 👁️",
        description: "Schreckensausstrahlung",
        category: AdeptPowerCategory.combat,
        powerPointCost: 1.0,
      ),
    ];
    notifyListeners();
  }

  void initializeStarterComplexForms() {
    _complexForms = [
      ComplexForm(
        name: "Puppeteer 🎭",
        description: "Manipuliert Geräte aus der Ferne",
        category: ComplexFormCategory.hacking,
        fadeValue: 3,
      ),
      ComplexForm(
        name: "Resonanzfalle 🕸️",
        description: "Erstellt eine Falle im Matrixsystem",
        category: ComplexFormCategory.attack,
        fadeValue: 2,
      ),
      ComplexForm(
        name: "Stille 🦗",
        description: "Unterdrückt Matrixsignale",
        category: ComplexFormCategory.sleaze,
        fadeValue: 2,
      ),
    ];
    notifyListeners();
  }

  // Für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'userType': _userType.index,
      'magic': _magic,
      'resonance': _resonance,
      'initiationGrade': _initiationGrade,
      'submersionGrade': _submersionGrade,
      'knownSpells': _knownSpells.map((s) => s.toMap()).toList(),
      'adeptPowers': _adeptPowers.map((p) => p.toMap()).toList(),
      'complexForms': _complexForms.map((f) => f.toMap()).toList(),
      'availablePowerPoints': _availablePowerPoints,
      'usedPowerPoints': _usedPowerPoints,
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _userType = MagicUserType.values[map['userType'] as int];
    _magic = map['magic'] as int;
    _resonance = map['resonance'] as int;
    _initiationGrade = map['initiationGrade'] as int;
    _submersionGrade = map['submersionGrade'] as int;
    _knownSpells = (map['knownSpells'] as List)
        .map((s) => Spell.fromMap(s))
        .toList();
    _adeptPowers = (map['adeptPowers'] as List)
        .map((p) => AdeptPower.fromMap(p))
        .toList();
    _complexForms = (map['complexForms'] as List)
        .map((f) => ComplexForm.fromMap(f))
        .toList();
    _availablePowerPoints = map['availablePowerPoints'] as double;
    _usedPowerPoints = map['usedPowerPoints'] as double;
    notifyListeners();
  }
}
