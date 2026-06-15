import 'skill.dart';
import 'ub_player.dart';

class SkillManager {
  List<Skill> _skills = [];

  // Getter für alle Skills
  List<Skill> get allSkills => List.unmodifiable(_skills);

  // Skills nach Kategorie filtern
  List<Skill> getSkillsByCategory(SkillCategory category) {
    return _skills.where((s) => s.category == category).toList();
  }

  // Skills nach Attribut filtern
  List<Skill> getSkillsByAttribute(SkillAttribute attribute) {
    return _skills.where((s) => s.linkedAttribute == attribute).toList();
  }

  // Bestimmten Skill finden
  Skill? findSkill(String name) {
    try {
      return _skills.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  // Skill-Rang erhöhen
  bool increaseSkillRank(String skillName) {
    final skill = findSkill(skillName);
    if (skill != null && skill.rank < 12) {
      final index = _skills.indexOf(skill);
      _skills[index] = skill.copyWith(rank: skill.rank + 1);
      return true;
    }
    return false;
  }

  // Skill-Rang verringern
  bool decreaseSkillRank(String skillName) {
    final skill = findSkill(skillName);
    if (skill != null && skill.rank > 0) {
      final index = _skills.indexOf(skill);
      _skills[index] = skill.copyWith(rank: skill.rank - 1);
      return true;
    }
    return false;
  }

  // Spezialisierung umschalten
  void toggleSpecialization(String skillName) {
    final skill = findSkill(skillName);
    if (skill != null) {
      final index = _skills.indexOf(skill);
      _skills[index] = skill.copyWith(
        isSpecialization: !skill.isSpecialization,
      );
    }
  }

  // Verfügbare Skill-Punkte berechnen (vereinfacht)
  int getAvailableSkillPoints(UbPlayer player) {
    // Beispiel: (Intuition + Logik) * 2 als Basis
    return (player.intuition + player.logic) * 2;
  }

  // Investierte Skill-Punkte berechnen
  int getInvestedPoints() {
    return _skills.fold(0, (sum, skill) => sum + skill.rank);
  }

  // Skill-Würfelpool für eine Probe berechnen
  int getSkillPool(UbPlayer player, String skillName) {
    final skill = findSkill(skillName);
    if (skill == null) return 0;
    return skill.calculatePool(player);
  }

  // Standard-Skills initialisieren
  void initializeDefaultSkills() {
    _skills = [
      // Kampf-Skills
      Skill(
        name: 'Schusswaffen',
        description: 'Pistolen, Gewehre, etc.',
        category: SkillCategory.combat,
        linkedAttribute: SkillAttribute.agility,
      ),
      Skill(
        name: 'Nahkampf',
        description: 'Schwerter, Messer, Fäuste',
        category: SkillCategory.combat,
        linkedAttribute: SkillAttribute.strength,
      ),
      Skill(
        name: 'Ausweichen',
        description: 'Angriffen ausweichen',
        category: SkillCategory.combat,
        linkedAttribute: SkillAttribute.reaction,
      ),
      Skill(
        name: 'Granaten',
        description: 'Sprengstoff werfen',
        category: SkillCategory.combat,
        linkedAttribute: SkillAttribute.agility,
      ),

      // Körperliche Skills
      Skill(
        name: 'Athletik',
        description: 'Laufen, Springen, Klettern',
        category: SkillCategory.physical,
        linkedAttribute: SkillAttribute.agility,
      ),
      Skill(
        name: 'Schleichen',
        description: 'Lautlos bewegen',
        category: SkillCategory.physical,
        linkedAttribute: SkillAttribute.agility,
      ),
      Skill(
        name: 'Diebesgut',
        description: 'Schlösser knacken',
        category: SkillCategory.physical,
        linkedAttribute: SkillAttribute.agility,
      ),
      Skill(
        name: 'Fahrzeuge lenken',
        description: 'Autos, Motorräder',
        category: SkillCategory.vehicle,
        linkedAttribute: SkillAttribute.reaction,
      ),

      // Soziale Skills
      Skill(
        name: 'Überreden',
        description: 'Andere überzeugen',
        category: SkillCategory.social,
        linkedAttribute: SkillAttribute.charisma,
      ),
      Skill(
        name: 'Einschüchtern',
        description: 'Angst einflößen',
        category: SkillCategory.social,
        linkedAttribute: SkillAttribute.charisma,
      ),
      Skill(
        name: 'Lügen',
        description: 'Täuschen und bluffen',
        category: SkillCategory.social,
        linkedAttribute: SkillAttribute.charisma,
      ),
      Skill(
        name: 'Etikette',
        description: 'Sich richtig verhalten',
        category: SkillCategory.social,
        linkedAttribute: SkillAttribute.charisma,
      ),

      // Technische Skills
      Skill(
        name: 'Computer',
        description: 'Grundlegende Computernutzung',
        category: SkillCategory.technical,
        linkedAttribute: SkillAttribute.logic,
      ),
      Skill(
        name: 'Hardware',
        description: 'Reparieren von Geräten',
        category: SkillCategory.technical,
        linkedAttribute: SkillAttribute.logic,
      ),
      Skill(
        name: 'Software',
        description: 'Programmieren',
        category: SkillCategory.technical,
        linkedAttribute: SkillAttribute.logic,
      ),
      Skill(
        name: 'Erste Hilfe',
        description: 'Wunden versorgen',
        category: SkillCategory.technical,
        linkedAttribute: SkillAttribute.logic,
      ),

      // Magische Skills (für Magier/Geomanten)
      Skill(
        name: 'Zauberwirken',
        description: 'Magie anwenden',
        category: SkillCategory.magic,
        linkedAttribute: SkillAttribute.willpower,
      ),
      Skill(
        name: 'Beschwörung',
        description: 'Geister rufen',
        category: SkillCategory.magic,
        linkedAttribute: SkillAttribute.charisma,
      ),
      Skill(
        name: 'Alchemie',
        description: 'Tränke und Salben',
        category: SkillCategory.magic,
        linkedAttribute: SkillAttribute.logic,
      ),

      // Matrix-Skills (für Technomancer/Hacker)
      Skill(
        name: 'Hacking',
        description: 'In Systeme eindringen',
        category: SkillCategory.matrix,
        linkedAttribute: SkillAttribute.logic,
      ),
      Skill(
        name: 'Cybercombat',
        description: 'Matrix-Kämpfe',
        category: SkillCategory.matrix,
        linkedAttribute: SkillAttribute.logic,
      ),
      Skill(
        name: 'Elektronische Kriegsführung',
        description: 'Signale stören',
        category: SkillCategory.matrix,
        linkedAttribute: SkillAttribute.intuition,
      ),

      // Straßenwissen
      Skill(
        name: 'Straßenwissen',
        description: 'Unterwelt kennen',
        category: SkillCategory.street,
        linkedAttribute: SkillAttribute.intuition,
      ),
      Skill(
        name: 'Gang-Identifikation',
        description: 'Gangstrukturen',
        category: SkillCategory.street,
        linkedAttribute: SkillAttribute.intuition,
      ),
    ];
  }

  // Skills in Map für Datenbank speichern
  List<Map<String, dynamic>> toMapList() {
    return _skills.map((skill) => skill.toMap()).toList();
  }

  // Skills aus Datenbank laden
  void fromMapList(List<Map<String, dynamic>> maps) {
    _skills = maps.map((map) => Skill.fromMap(map)).toList();
  }
}
