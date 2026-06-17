enum EquipmentSlot {
  head, // Kopf
  torso, // Torso
  arms, // Arme
  legs, // Beine
  hands, // Hände
  feet, // Füße
  accessory, // Accessoire (Gürtel, Uhr, etc.)
  weapon, // Waffe
  weaponTwo, // Zweite Waffe
  cyberware, // Cyberware
  bioware, // Bioware
  general, // Allgemein (Taschenlampe, Kommlink, etc.)
}

enum WeaponType {
  pistol, // Pistole
  revolver, // Revolver
  smg, // Maschinenpistole
  assaultRifle, // Sturmgewehr
  shotgun, // Schrotflinte
  sniperRifle, // Scharfschützengewehr
  heavyWeapon, // Schwere Waffe
  melee, // Nahkampf
  thrown, // Wurfwaffe
}

enum WeaponCategory {
  projectile, // Projektilwaffen
  energy, // Energiewaffen
  melee, // Nahkampf
  thrown, // Wurf
  exotic, // Exotisch
}

enum ArmorType {
  clothing, // Kleidung (kein Schutz)
  armoredClothing, // Panzerkleidung
  lightArmor, // Leichte Panzerung
  mediumArmor, // Mittlere Panzerung
  heavyArmor, // Schwere Panzerung
}

class Weapon {
  String name;
  WeaponType type;
  WeaponCategory category;
  int damage; // Schadenscode (z.B. 5K)
  int armorPenetration; // Rüstungsdurchdringung
  int accuracy; // Genauigkeit (max. Erfolge)
  int reach; // Reichweite (Nahkampf)
  int rangeClose; // Nahbereich
  int rangeMedium; // Mittelbereich
  int rangeLong; // Fernbereich
  int rangeExtreme; // Extrembereich
  int ammo; // Munition
  String ammoType; // Munitionstyp
  int conceal; // Tarnbarkeit
  double weight; // Gewicht
  double cost; // Preis (in Nuyen)
  String availability; // Verfügbarkeit
  String description; // Beschreibung

  Weapon({
    required this.name,
    required this.type,
    required this.category,
    this.damage = 0,
    this.armorPenetration = 0,
    this.accuracy = 0,
    this.reach = 0,
    this.rangeClose = 0,
    this.rangeMedium = 0,
    this.rangeLong = 0,
    this.rangeExtreme = 0,
    this.ammo = 0,
    this.ammoType = "Standard",
    this.conceal = 0,
    this.weight = 0,
    this.cost = 0,
    this.availability = "",
    this.description = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.index,
      'category': category.index,
      'damage': damage,
      'armorPenetration': armorPenetration,
      'accuracy': accuracy,
      'reach': reach,
      'rangeClose': rangeClose,
      'rangeMedium': rangeMedium,
      'rangeLong': rangeLong,
      'rangeExtreme': rangeExtreme,
      'ammo': ammo,
      'ammoType': ammoType,
      'conceal': conceal,
      'weight': weight,
      'cost': cost,
      'availability': availability,
      'description': description,
    };
  }

  factory Weapon.fromMap(Map<String, dynamic> map) {
    return Weapon(
      name: map['name'] as String,
      type: WeaponType.values[map['type'] as int],
      category: WeaponCategory.values[map['category'] as int],
      damage: map['damage'] as int,
      armorPenetration: map['armorPenetration'] as int,
      accuracy: map['accuracy'] as int,
      reach: map['reach'] as int,
      rangeClose: map['rangeClose'] as int,
      rangeMedium: map['rangeMedium'] as int,
      rangeLong: map['rangeLong'] as int,
      rangeExtreme: map['rangeExtreme'] as int,
      ammo: map['ammo'] as int,
      ammoType: map['ammoType'] as String,
      conceal: map['conceal'] as int,
      weight: map['weight'] as double,
      cost: map['cost'] as double,
      availability: map['availability'] as String,
      description: map['description'] as String,
    );
  }

  Weapon copyWith({
    String? name,
    WeaponType? type,
    WeaponCategory? category,
    int? damage,
    int? armorPenetration,
    int? accuracy,
    int? reach,
    int? rangeClose,
    int? rangeMedium,
    int? rangeLong,
    int? rangeExtreme,
    int? ammo,
    String? ammoType,
    int? conceal,
    double? weight,
    double? cost,
    String? availability,
    String? description,
  }) {
    return Weapon(
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      damage: damage ?? this.damage,
      armorPenetration: armorPenetration ?? this.armorPenetration,
      accuracy: accuracy ?? this.accuracy,
      reach: reach ?? this.reach,
      rangeClose: rangeClose ?? this.rangeClose,
      rangeMedium: rangeMedium ?? this.rangeMedium,
      rangeLong: rangeLong ?? this.rangeLong,
      rangeExtreme: rangeExtreme ?? this.rangeExtreme,
      ammo: ammo ?? this.ammo,
      ammoType: ammoType ?? this.ammoType,
      conceal: conceal ?? this.conceal,
      weight: weight ?? this.weight,
      cost: cost ?? this.cost,
      availability: availability ?? this.availability,
      description: description ?? this.description,
    );
  }
}

class Armor {
  String name;
  ArmorType type;
  int rating; // Rüstungswert
  int capacity; // Kapazität für Modifikationen
  int socialModifier; // Sozialmodifikator (negativ bei schwerer Rüstung)
  double weight;
  double cost;
  String availability;
  String description;

  Armor({
    required this.name,
    required this.type,
    this.rating = 0,
    this.capacity = 0,
    this.socialModifier = 0,
    this.weight = 0,
    this.cost = 0,
    this.availability = "",
    this.description = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.index,
      'rating': rating,
      'capacity': capacity,
      'socialModifier': socialModifier,
      'weight': weight,
      'cost': cost,
      'availability': availability,
      'description': description,
    };
  }

  factory Armor.fromMap(Map<String, dynamic> map) {
    return Armor(
      name: map['name'] as String,
      type: ArmorType.values[map['type'] as int],
      rating: map['rating'] as int,
      capacity: map['capacity'] as int,
      socialModifier: map['socialModifier'] as int,
      weight: map['weight'] as double,
      cost: map['cost'] as double,
      availability: map['availability'] as String,
      description: map['description'] as String,
    );
  }
}

class Gear {
  String name;
  EquipmentSlot slot;
  String description;
  double weight;
  double cost;
  int quantity;
  bool isEquipped;

  Gear({
    required this.name,
    required this.slot,
    this.description = "",
    this.weight = 0,
    this.cost = 0,
    this.quantity = 1,
    this.isEquipped = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slot': slot.index,
      'description': description,
      'weight': weight,
      'cost': cost,
      'quantity': quantity,
      'isEquipped': isEquipped,
    };
  }

  factory Gear.fromMap(Map<String, dynamic> map) {
    return Gear(
      name: map['name'] as String,
      slot: EquipmentSlot.values[map['slot'] as int],
      description: map['description'] as String,
      weight: map['weight'] as double,
      cost: map['cost'] as double,
      quantity: map['quantity'] as int,
      isEquipped: map['isEquipped'] as bool,
    );
  }
}
