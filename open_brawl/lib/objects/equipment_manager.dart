import 'package:flutter/material.dart';

import 'equipment.dart';
import 'ub_player.dart';

class EquipmentManager extends ChangeNotifier {
  final UbPlayer _player;

  List<Weapon> _weapons = [];
  List<Armor> _armors = [];
  List<Gear> _gear = [];

  // Ausgerüstete Gegenstände
  Weapon? _equippedWeapon;
  Weapon? _equippedWeaponTwo;
  Armor? _equippedArmor;
  final Map<EquipmentSlot, Gear> _equippedGear = {};

  EquipmentManager(this._player);

  // Getter
  List<Weapon> get weapons => List.unmodifiable(_weapons);
  List<Armor> get armors => List.unmodifiable(_armors);
  List<Gear> get gear => List.unmodifiable(_gear);
  Weapon? get equippedWeapon => _equippedWeapon;
  Weapon? get equippedWeaponTwo => _equippedWeaponTwo;
  Armor? get equippedArmor => _equippedArmor;

  // Gesamtrüstungswert berechnen
  int get totalArmorRating {
    int total = _equippedArmor?.rating ?? 0;

    // Rüstungszubehör hinzufügen
    for (var gear in _equippedGear.values) {
      // Hier könntest du Rüstungsboni von Gegenständen hinzufügen
    }

    return total;
  }

  // Initiative-Modifikator durch Rüstung
  int get armorInitiativePenalty {
    if (_equippedArmor == null) return 0;
    switch (_equippedArmor!.type) {
      case ArmorType.heavyArmor:
        return -2;
      case ArmorType.mediumArmor:
        return -1;
      default:
        return 0;
    }
  }

  // Waffen hinzufügen/entfernen
  void addWeapon(Weapon weapon) {
    _weapons.add(weapon);
    notifyListeners();
  }

  void removeWeapon(Weapon weapon) {
    _weapons.remove(weapon);
    if (_equippedWeapon == weapon) _equippedWeapon = null;
    if (_equippedWeaponTwo == weapon) _equippedWeaponTwo = null;
    notifyListeners();
  }

  // Rüstung hinzufügen/entfernen
  void addArmor(Armor armor) {
    _armors.add(armor);
    notifyListeners();
  }

  void removeArmor(Armor armor) {
    _armors.remove(armor);
    if (_equippedArmor == armor) _equippedArmor = null;
    notifyListeners();
  }

  // Ausrüstung hinzufügen/entfernen
  void addGear(Gear item) {
    _gear.add(item);
    notifyListeners();
  }

  void removeGear(Gear item) {
    _gear.remove(item);
    _equippedGear.removeWhere((key, value) => value == item);
    notifyListeners();
  }

  // Ausrüsten/Abnehmen
  void equipWeapon(Weapon weapon, {bool isPrimary = true}) {
    if (isPrimary) {
      _equippedWeapon = weapon;
    } else {
      _equippedWeaponTwo = weapon;
    }
    notifyListeners();
  }

  void unequipWeapon({bool isPrimary = true}) {
    if (isPrimary) {
      _equippedWeapon = null;
    } else {
      _equippedWeaponTwo = null;
    }
    notifyListeners();
  }

  void equipArmor(Armor armor) {
    _equippedArmor = armor;
    notifyListeners();
  }

  void unequipArmor() {
    _equippedArmor = null;
    notifyListeners();
  }

  void equipGear(Gear gear, EquipmentSlot slot) {
    _equippedGear[slot] = gear;
    notifyListeners();
  }

  void unequipGear(EquipmentSlot slot) {
    _equippedGear.remove(slot);
    notifyListeners();
  }

  // Beispielausrüstung laden
  void loadStarterEquipment() {
    // Beispiel-Waffen
    _weapons = [
      Weapon(
        name: "Colt America L36",
        type: WeaponType.pistol,
        category: WeaponCategory.projectile,
        damage: 6,
        armorPenetration: -2,
        accuracy: 5,
        rangeClose: 10,
        rangeMedium: 25,
        rangeLong: 50,
        rangeExtreme: 100,
        ammo: 15,
        ammoType: "9mm",
        conceal: 3,
        weight: 1.2,
        cost: 350,
        availability: "4R",
        description: "Standard-Pistole der mittleren Preisklasse",
      ),
      Weapon(
        name: "Ares Predator V",
        type: WeaponType.pistol,
        category: WeaponCategory.projectile,
        damage: 7,
        armorPenetration: -1,
        accuracy: 6,
        rangeClose: 12,
        rangeMedium: 30,
        rangeLong: 60,
        rangeExtreme: 120,
        ammo: 18,
        ammoType: "10mm",
        conceal: 2,
        weight: 1.5,
        cost: 725,
        availability: "6R",
        description: "Schwere Kampfpistole",
      ),
      Weapon(
        name: "Combat Knife",
        type: WeaponType.melee,
        category: WeaponCategory.melee,
        damage: 4,
        armorPenetration: -3,
        accuracy: 5,
        reach: 1,
        conceal: 4,
        weight: 0.5,
        cost: 50,
        availability: "2",
        description: "Standard-Kampfmesser",
      ),
    ];

    // Beispiel-Rüstungen
    _armors = [
      Armor(
        name: "Armierter Mantel",
        type: ArmorType.armoredClothing,
        rating: 9,
        capacity: 6,
        socialModifier: 0,
        weight: 3.5,
        cost: 800,
        availability: "4",
        description: "Leichte Panzerkleidung",
      ),
      Armor(
        name: "Leichte Panzerweste",
        type: ArmorType.lightArmor,
        rating: 12,
        capacity: 8,
        socialModifier: -1,
        weight: 6,
        cost: 1500,
        availability: "6R",
        description: "Standard-Panzerweste",
      ),
    ];

    // Beispiel-Ausrüstung
    _gear = [
      Gear(
        name: "Kommlink (Meta Link)",
        slot: EquipmentSlot.general,
        description: "Standard-Kommlink für grundlegende Matrixverbindung",
        weight: 0.2,
        cost: 100,
      ),
      Gear(
        name: "Taschenlampe",
        slot: EquipmentSlot.general,
        description: "Helle LED-Taschenlampe",
        weight: 0.3,
        cost: 25,
      ),
      Gear(
        name: "Medkit (R6)",
        slot: EquipmentSlot.general,
        description: "Erste-Hilfe-Set mit Diagnosesoftware",
        weight: 1.5,
        cost: 450,
      ),
    ];

    notifyListeners();
  }

  // Für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'weapons': _weapons.map((w) => w.toMap()).toList(),
      'armors': _armors.map((a) => a.toMap()).toList(),
      'gear': _gear.map((g) => g.toMap()).toList(),
      'equippedWeapon': _equippedWeapon?.toMap(),
      'equippedWeaponTwo': _equippedWeaponTwo?.toMap(),
      'equippedArmor': _equippedArmor?.toMap(),
      'equippedGear': _equippedGear.map(
        (key, value) => MapEntry(key.index, value.toMap()),
      ),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _weapons = (map['weapons'] as List).map((w) => Weapon.fromMap(w)).toList();
    _armors = (map['armors'] as List).map((a) => Armor.fromMap(a)).toList();
    _gear = (map['gear'] as List).map((g) => Gear.fromMap(g)).toList();

    if (map['equippedWeapon'] != null) {
      _equippedWeapon = Weapon.fromMap(map['equippedWeapon']);
    }
    if (map['equippedWeaponTwo'] != null) {
      _equippedWeaponTwo = Weapon.fromMap(map['equippedWeaponTwo']);
    }
    if (map['equippedArmor'] != null) {
      _equippedArmor = Armor.fromMap(map['equippedArmor']);
    }

    notifyListeners();
  }
}
