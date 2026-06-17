import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/skill.dart';
import 'package:open_brawl/objects/legacy/skll_manager.dart';
import 'package:open_brawl/objects/legacy/ub_player.dart';
/*import 'package:open_brawl/objects/skill.dart';
import 'package:open_brawl/objects/skll_manager.dart';
import 'package:open_brawl/objects/ub_player.dart';*/
//import 'skill.dart';
//import 'skill_manager.dart';
//import 'ub_player.dart';

class SkillManagerScreen extends StatefulWidget {
  final UbPlayer player;
  final SkillManager skillManager;

  const SkillManagerScreen({
    super.key,
    required this.player,
    required this.skillManager,
  });

  @override
  State<SkillManagerScreen> createState() => _SkillManagerScreenState();
}

class _SkillManagerScreenState extends State<SkillManagerScreen> {
  SkillCategory _selectedCategory = SkillCategory.combat;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Standard-Skills laden, falls noch keine vorhanden
    if (widget.skillManager.allSkills.isEmpty) {
      widget.skillManager.initializeDefaultSkills();
    }
  }

  List<Skill> _getFilteredSkills() {
    var skills = widget.skillManager.getSkillsByCategory(_selectedCategory);

    if (_searchQuery.isNotEmpty) {
      skills = skills
          .where(
            (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return skills;
  }

  int _getRemainingPoints() {
    return widget.skillManager.getAvailableSkillPoints(widget.player) -
        widget.skillManager.getInvestedPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertigkeiten verwalten'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRemainingPoints() >= 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_getRemainingPoints()} Punkte übrig',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          _buildSearchBar(),
          // Kategorie-Tabs
          _buildCategoryTabs(),
          // Skill-Liste
          Expanded(
            child: _buildSkillList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Fertigkeit suchen...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SkillCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = SkillCategory.values[index];
          final isSelected = _selectedCategory == category;

          return FilterChip(
            label: Text(_getCategoryName(category)),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.deepPurple.shade100,
            checkmarkColor: Colors.deepPurple,
          );
        },
      ),
    );
  }

  Widget _buildSkillList() {
    final skills = _getFilteredSkills();

    if (skills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_martial_arts, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keine Fertigkeiten gefunden',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final pool = skill.calculatePool(widget.player);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon basierend auf Kategorie
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          skill.category,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(skill.category),
                        color: _getCategoryColor(skill.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Skill-Name und Beschreibung
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            skill.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Attribut- und Pool-Anzeige
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Attribut: ${_getAttributeName(skill.linkedAttribute)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pool: $pool Würfel',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Spezialisierung
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.skillManager.toggleSpecialization(skill.name);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: skill.isSpecialization
                              ? Colors.orange
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: skill.isSpecialization
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Spezi',
                              style: TextStyle(
                                fontSize: 10,
                                color: skill.isSpecialization
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // +/- Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: skill.rank > 0
                              ? () {
                                  setState(() {
                                    widget.skillManager.decreaseSkillRank(
                                      skill.name,
                                    );
                                  });
                                }
                              : null,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            skill.rank.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed:
                              skill.rank < 12 && _getRemainingPoints() > 0
                              ? () {
                                  setState(() {
                                    widget.skillManager.increaseSkillRank(
                                      skill.name,
                                    );
                                  });
                                }
                              : null,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hilfsmethoden für UI
  String _getCategoryName(SkillCategory category) {
    switch (category) {
      case SkillCategory.combat:
        return 'Kampf';
      case SkillCategory.physical:
        return 'Körperlich';
      case SkillCategory.social:
        return 'Sozial';
      case SkillCategory.technical:
        return 'Technisch';
      case SkillCategory.magic:
        return 'Magisch';
      case SkillCategory.matrix:
        return 'Matrix';
      case SkillCategory.vehicle:
        return 'Fahrzeuge';
      case SkillCategory.street:
        return 'Straßenwissen';
    }
  }

  IconData _getCategoryIcon(SkillCategory category) {
    switch (category) {
      case SkillCategory.combat:
        return Icons.sports_mma;
      case SkillCategory.physical:
        return Icons.directions_run;
      case SkillCategory.social:
        return Icons.people;
      case SkillCategory.technical:
        return Icons.computer;
      case SkillCategory.magic:
        return Icons.auto_awesome;
      case SkillCategory.matrix:
        return Icons.memory;
      case SkillCategory.vehicle:
        return Icons.directions_car;
      case SkillCategory.street:
        return Icons.location_city;
    }
  }

  Color _getCategoryColor(SkillCategory category) {
    switch (category) {
      case SkillCategory.combat:
        return Colors.red;
      case SkillCategory.physical:
        return Colors.green;
      case SkillCategory.social:
        return Colors.blue;
      case SkillCategory.technical:
        return Colors.orange;
      case SkillCategory.magic:
        return Colors.purple;
      case SkillCategory.matrix:
        return Colors.cyan;
      case SkillCategory.vehicle:
        return Colors.brown;
      case SkillCategory.street:
        return Colors.grey;
    }
  }

  String _getAttributeName(SkillAttribute attribute) {
    switch (attribute) {
      case SkillAttribute.agility:
        return 'Beweglichkeit';
      case SkillAttribute.strength:
        return 'Stärke';
      case SkillAttribute.reaction:
        return 'Reaktion';
      case SkillAttribute.logic:
        return 'Logik';
      case SkillAttribute.intuition:
        return 'Intuition';
      case SkillAttribute.charisma:
        return 'Charisma';
      case SkillAttribute.willpower:
        return 'Willenskraft';
      case SkillAttribute.body:
        return 'Körper';
    }
  }
}
