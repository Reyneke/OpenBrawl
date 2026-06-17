import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/ub_player.dart';
//import 'package:open_brawl/objects/ub_player.dart';

// Annahme: Deine Klassen sind in separaten Dateien
// import 'ub_player.dart';
// import 'player_race.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  // Formular-Validierung
  final _formKey = GlobalKey<FormState>();

  // Controller für Textfelder
  final _nameController = TextEditingController();

  // Attribute (Standardwerte für einen durchschnittlichen Menschen)
  int _body = 3;
  int _agility = 3;
  int _reaction = 3;
  int _strength = 3;
  int _willpower = 3;
  int _logic = 3;
  int _intuition = 3;
  int _charisma = 3;
  int _edge = 3;
  PlayerRace _selectedRace = PlayerRace.mensch;

  // Verfügbare Attributspunkte (z.B. 20 für Prioritätssystem)
  int _remainingAttributePoints = 20;
  int _totalAttributes = 0;

  // Berechnung der Gesamtattributspunkte
  void _updateTotalAttributes() {
    setState(() {
      _totalAttributes =
          _body +
          _agility +
          _reaction +
          _strength +
          _willpower +
          _logic +
          _intuition +
          _charisma;
      _remainingAttributePoints = 20 - _totalAttributes;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateTotalAttributes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Attributs-Änderung mit Begrenzung (1-6 für Menschen)
  void _changeAttribute(int current, Function(int) setter, int delta) {
    final newValue = current + delta;
    final maxValue = _getMaxAttributeForRace();
    if (newValue >= 1 && newValue <= maxValue) {
      setter(newValue);
      _updateTotalAttributes();
    }
  }

  int _getMaxAttributeForRace() {
    switch (_selectedRace) {
      case PlayerRace.mensch:
      case PlayerRace.elf:
        return 6;
      case PlayerRace.zwerg:
        return 6; // Zwerge haben andere Limits, aber der Übersicht halber
      case PlayerRace.ork:
        return 7; // Orks haben höhere körperliche Limits
      case PlayerRace.troll:
        return 8; // Trolle sind die stärksten
    }
  }

  // Charakter speichern
  void _saveCharacter() {
    if (!_formKey.currentState!.validate()) return;

    if (_remainingAttributePoints < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du hast zu viele Attributspunkte vergeben!'),
        ),
      );
      return;
    }

    final newPlayer = UbPlayer(
      key: DateTime.now().millisecondsSinceEpoch, // Temporärer Key
      name: _nameController.text.trim(),
      body: _body,
      agility: _agility,
      reaction: _reaction,
      strength: _strength,
      willpower: _willpower,
      logic: _logic,
      intuition: _intuition,
      charisma: _charisma,
      edge: _edge,
      playerRace: _selectedRace,
    );

    // Hier zurück zum vorherigen Screen mit dem neuen Charakter
    Navigator.pop(context, newPlayer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuen Runner erstellen'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Punkte-Anzeige in der AppBar
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingAttributePoints >= 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_remainingAttributePoints Punkte übrig',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Grundinformationen
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Attributs-Bereich
            _buildAttributesSection(),
            const SizedBox(height: 24),

            // Edge & Rasse
            _buildSpecialSection(),
            const SizedBox(height: 32),

            // Speichern-Button
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Abschnitt 1: Grundinformationen (Name, Rasse, Bild)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BASISINFORMATIONEN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name des Runners',
                hintText: 'z.B. "Ghost", "Blade", "Morgan"',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib einen Namen ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlayerRace>(
              initialValue: _selectedRace,
              decoration: const InputDecoration(
                labelText: 'Metatyp (Rasse)',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              items: PlayerRace.values.map((race) {
                return DropdownMenuItem(
                  value: race,
                  child: Row(
                    children: [
                      Icon(_getRaceIcon(race)),
                      const SizedBox(width: 8),
                      Text(_getRaceName(race)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRace = value;
                    _updateTotalAttributes();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Abschnitt 2: Attribute (Body, Agility, etc.)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAttributesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ATTRIBUTE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Punkte 1-6 (maximal abhängig von der Rasse)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(),

            // Körperliche Attribute (2-spaltiges Grid)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildAttributeTile(
                        '💪 KÖRPER',
                        'Zähigkeit & Gesundheit',
                        _body,
                        (v) => setState(() => _body = v),
                      ),
                      _buildAttributeTile(
                        '🏃 BEWEGLICHKEIT',
                        'Geschick & Koordination',
                        _agility,
                        (v) => setState(() => _agility = v),
                      ),
                      _buildAttributeTile(
                        '⚡ REAKTION',
                        'Reflexe & Ausweichen',
                        _reaction,
                        (v) => setState(() => _reaction = v),
                      ),
                      _buildAttributeTile(
                        '💢 STÄRKE',
                        'Muskelkraft',
                        _strength,
                        (v) => setState(() => _strength = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildAttributeTile(
                        '🧠 WILLENSKRAFT',
                        'Mentale Stärke',
                        _willpower,
                        (v) => setState(() => _willpower = v),
                      ),
                      _buildAttributeTile(
                        '📚 LOGIK',
                        'Rationales Denken',
                        _logic,
                        (v) => setState(() => _logic = v),
                      ),
                      _buildAttributeTile(
                        '🔮 INTUITION',
                        'Bauchgefühl',
                        _intuition,
                        (v) => setState(() => _intuition = v),
                      ),
                      _buildAttributeTile(
                        '🗣️ CHARISMA',
                        'Ausstrahlung',
                        _charisma,
                        (v) => setState(() => _charisma = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Einzelnes Attribut mit + / - Buttons
  Widget _buildAttributeTile(
    String name,
    String description,
    int value,
    Function(int) onChanged,
  ) {
    final maxValue = _getMaxAttributeForRace();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: value > 1
                      ? () => _changeAttribute(value, onChanged, -1)
                      : null,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: value < maxValue && _remainingAttributePoints > 0
                      ? () => _changeAttribute(value, onChanged, 1)
                      : null,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Abschnitt 3: Spezielle Werte (Edge, Rassenbonus)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSpecialSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPEZIELLE WERTE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Edge
            _buildAttributeTile(
              '🍀 EDGE (Glück)',
              'Schicksalspunkte',
              _edge,
              (v) => setState(() => _edge = v),
            ),

            const SizedBox(height: 8),

            // Rassenbonus anzeigen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getRaceIcon(_selectedRace), color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rassenbonus: ${_getRaceName(_selectedRace)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getRaceBonusDescription(_selectedRace),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Save-Button
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _remainingAttributePoints >= 0 ? _saveCharacter : null,
      icon: const Icon(Icons.save),
      label: const Text('CHARAKTER ERSTELLEN', style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Hilfsmethoden für Rassen
  // ═══════════════════════════════════════════════════════════════

  IconData _getRaceIcon(PlayerRace race) {
    switch (race) {
      case PlayerRace.mensch:
        return Icons.person;
      case PlayerRace.elf:
        return Icons.self_improvement;
      case PlayerRace.zwerg:
        return Icons.engineering;
      case PlayerRace.ork:
        return Icons.sports_mma;
      case PlayerRace.troll:
        return Icons.bolt;
    }
  }

  String _getRaceName(PlayerRace race) {
    switch (race) {
      case PlayerRace.mensch:
        return 'Mensch';
      case PlayerRace.elf:
        return 'Elf';
      case PlayerRace.zwerg:
        return 'Zwerg';
      case PlayerRace.ork:
        return 'Ork';
      case PlayerRace.troll:
        return 'Troll';
    }
  }

  String _getRaceBonusDescription(PlayerRace race) {
    switch (race) {
      case PlayerRace.mensch:
        return '+1 Edge (max. 7)';
      case PlayerRace.elf:
        return '+2 Charisma, niedrigere Lebenserwartung';
      case PlayerRace.zwerg:
        return '+2 Body, +2 Willpower, Resistenz gegen Toxine';
      case PlayerRace.ork:
        return '+3 Body, +2 Strength, niedrigere Maximalwerte für Charisma & Logik';
      case PlayerRace.troll:
        return '+4 Body, +3 Strength, +1 Reach, -1 Agility & Charisma (max. 5)';
    }
  }
}
