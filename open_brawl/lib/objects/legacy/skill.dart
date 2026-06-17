//import 'package:open_brawl/objects/ub_player.dart';

import 'package:open_brawl/objects/legacy/ub_player.dart';

enum SkillCategory {
  combat, // Kampf
  physical, // Körperlich
  social, // Sozial
  technical, // Technisch
  magic, // Magisch
  matrix, // Matrix
  vehicle, // Fahrzeuge
  street, // Straßenwissen
}

enum SkillAttribute {
  agility, // Beweglichkeit
  strength, // Stärke
  reaction, // Reaktion
  logic, // Logik
  intuition, // Intuition
  charisma, // Charisma
  willpower, // Willenskraft
  body, // Körper
}

class Skill {
  final String name;
  final String description;
  final SkillCategory category;
  final SkillAttribute linkedAttribute;
  int rank; // 0-12 (max. Stufe in Shadowrun)
  bool isSpecialization; // Spezialisierung gibt +2 Bonus

  Skill({
    required this.name,
    required this.description,
    required this.category,
    required this.linkedAttribute,
    this.rank = 0,
    this.isSpecialization = false,
  });

  /// Berechnet den Gesamtbonus (Rang + Spezialisierung)
  int get totalBonus => rank + (isSpecialization ? 2 : 0);

  /// Berechnet den Würfelpool für diese Fertigkeit
  int calculatePool(UbPlayer player) {
    int attributeValue = _getAttributeValue(player);
    return attributeValue + totalBonus;
  }

  int _getAttributeValue(UbPlayer player) {
    switch (linkedAttribute) {
      case SkillAttribute.agility:
        return player.agility;
      case SkillAttribute.strength:
        return player.strength;
      case SkillAttribute.reaction:
        return player.reaction;
      case SkillAttribute.logic:
        return player.logic;
      case SkillAttribute.intuition:
        return player.intuition;
      case SkillAttribute.charisma:
        return player.charisma;
      case SkillAttribute.willpower:
        return player.willpower;
      case SkillAttribute.body:
        return player.body;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.index,
      'linkedAttribute': linkedAttribute.index,
      'rank': rank,
      'isSpecialization': isSpecialization,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] as String,
      description: map['description'] as String,
      category: SkillCategory.values[map['category'] as int],
      linkedAttribute: SkillAttribute.values[map['linkedAttribute'] as int],
      rank: map['rank'] as int,
      isSpecialization: map['isSpecialization'] as bool,
    );
  }

  Skill copyWith({
    String? name,
    String? description,
    SkillCategory? category,
    SkillAttribute? linkedAttribute,
    int? rank,
    bool? isSpecialization,
  }) {
    return Skill(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      linkedAttribute: linkedAttribute ?? this.linkedAttribute,
      rank: rank ?? this.rank,
      isSpecialization: isSpecialization ?? this.isSpecialization,
    );
  }
}
