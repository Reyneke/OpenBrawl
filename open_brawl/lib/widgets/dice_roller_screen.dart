import 'package:flutter/material.dart';

import 'dice_roller.dart';

class DiceRollerScreen extends StatefulWidget {
  final int? initialPool;
  final bool showSkillTestMode;

  const DiceRollerScreen({
    super.key,
    this.initialPool,
    this.showSkillTestMode = true,
  });

  @override
  State<DiceRollerScreen> createState() => _DiceRollerScreenState();
}

class _DiceRollerScreenState extends State<DiceRollerScreen>
    with SingleTickerProviderStateMixin {
  late DiceRoller _diceRoller;
  late TabController _tabController;

  // Skill-Test Variablen
  int _selectedAttribute = 3;
  int _selectedSkill = 3;
  int _selectedModifier = 0;

  // Kampf-Variablen
  int _agility = 4;
  int _weaponSkill = 4;
  int _weaponAccuracy = 6;
  int _defensePool = 0;

  // Animations-Status
  bool _isRolling = false;
  DiceResult? _lastResult;

  // Vordefinierte Würfel-Pools für Schnellauswahl
  final List<int> _quickPools = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20];

  @override
  void initState() {
    super.initState();
    _diceRoller = DiceRoller();
    if (widget.initialPool != null) {
      _diceRoller.setPool(widget.initialPool!);
    }
    _tabController = TabController(
      length: widget.showSkillTestMode ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Würfelsimulator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.casino), text: 'Standard'),
            if (widget.showSkillTestMode)
              const Tab(icon: Icon(Icons.psychology), text: 'Skill-Test'),
            const Tab(icon: Icon(Icons.sports_mma), text: 'Kampf'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Letztes Ergebnis anzeigen
          if (_lastResult != null) _buildResultCard(_lastResult!),

          // Hauptinhalt
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStandardTab(),
                if (widget.showSkillTestMode) _buildSkillTestTab(),
                _buildCombatTab(),
              ],
            ),
          ),

          // Verlauf
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildResultCard(DiceResult result) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: result.isCriticalGlitch
              ? [Colors.red.shade900, Colors.red.shade700]
              : result.isGlitch
              ? [Colors.orange.shade800, Colors.orange.shade600]
              : result.successes >= 5
              ? [Colors.green.shade800, Colors.green.shade600]
              : result.successes >= 1
              ? [Colors.blue.shade700, Colors.blue.shade500]
              : [Colors.grey.shade700, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.successes} Erfolg${result.successes != 1 ? 'e' : ''}',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: result.rolls.map((roll) {
              Color color;
              if (roll >= 5) {
                color = Colors.green;
              } else if (roll == 1) {
                color = Colors.red;
              } else {
                color = Colors.white;
              }

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    roll.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '1er: ${result.ones} | 5er: ${result.fives} | 6er: ${result.sixes}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Würfelpool-Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Würfelpool',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('1'),
                      Expanded(
                        child: Slider(
                          value: _diceRoller.currentPool.toDouble(),
                          min: 1,
                          max: 40,
                          divisions: 39,
                          label: _diceRoller.currentPool.toString(),
                          onChanged: (value) {
                            _diceRoller.setPool(value.toInt());
                            setState(() {});
                          },
                        ),
                      ),
                      const Text('40'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_diceRoller.currentPool} Würfel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Schnellauswahl
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Schnellauswahl',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _quickPools.map((pool) {
                      return FilterChip(
                        label: Text(pool.toString()),
                        selected: _diceRoller.currentPool == pool,
                        onSelected: (_) {
                          _diceRoller.setPool(pool);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Explodierende Sechsen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Explodierende Sechsen (Edge-Regel)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExplodingChip(0, 'Aus'),
                      _buildExplodingChip(1, '1x'),
                      _buildExplodingChip(2, '2x'),
                      _buildExplodingChip(3, '3x'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Erfolgsschwelle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Erfolgsschwelle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('1'),
                      Expanded(
                        child: Slider(
                          value: _diceRoller.threshold.toDouble(),
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: _diceRoller.threshold.toString(),
                          onChanged: (value) {
                            _diceRoller.setThreshold(value.toInt());
                            setState(() {});
                          },
                        ),
                      ),
                      const Text('20'),
                    ],
                  ),
                  Text(
                    'Benötigt: ${_diceRoller.threshold} Erfolg${_diceRoller.threshold != 1 ? 'e' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Würfel-Button
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollStandard,
            icon: _isRolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino),
            label: Text(_isRolling ? 'Würfelt...' : 'Würfeln!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplodingChip(int value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _diceRoller._explodingSixes == value,
      onSelected: (_) {
        _diceRoller.setExplodingSixes(value);
        setState(() {});
      },
    );
  }

  Widget _buildSkillTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Attribut + Fertigkeit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSkillSlider('Attribut', _selectedAttribute, 1, 12, (v) {
                    _selectedAttribute = v;
                    setState(() {});
                  }),
                  const SizedBox(height: 16),
                  _buildSkillSlider('Fertigkeit', _selectedSkill, 0, 12, (v) {
                    _selectedSkill = v;
                    setState(() {});
                  }),
                  const SizedBox(height: 16),
                  _buildSkillSlider('Modifikator', _selectedModifier, -10, 10, (
                    v,
                  ) {
                    _selectedModifier = v;
                    setState(() {});
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gesamtpool:'),
                      Text(
                        '${_selectedAttribute + _selectedSkill + _selectedModifier}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollSkillTest,
            icon: _isRolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            label: Text(_isRolling ? 'Testet...' : 'Skill-Test durchführen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Angriffswertung',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSkillSlider('Beweglichkeit', _agility, 1, 12, (v) {
                    _agility = v;
                    setState(() {});
                  }),
                  const SizedBox(height: 16),
                  _buildSkillSlider('Waffenfertigkeit', _weaponSkill, 0, 12, (
                    v,
                  ) {
                    _weaponSkill = v;
                    setState(() {});
                  }),
                  const SizedBox(height: 16),
                  _buildSkillSlider(
                    'Waffengenauigkeit',
                    _weaponAccuracy,
                    1,
                    10,
                    (v) {
                      _weaponAccuracy = v;
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Angriffspool:'),
                      Text(
                        '${_agility + _weaponSkill}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verteidigung (optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSkillSlider('Verteidigungspool', _defensePool, 0, 20, (
                    v,
                  ) {
                    _defensePool = v;
                    setState(() {});
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollAttack,
            icon: _isRolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sports_mma),
            label: Text(_isRolling ? 'Kämpft...' : 'Angriff würfeln'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSlider(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value >= 0 ? '+$value' : value.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            Text(min.toString()),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min),
                label: value.toString(),
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
            Text(max.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_diceRoller.history.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verlauf',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _diceRoller.clearHistory();
                    setState(() {});
                  },
                  child: const Text('Löschen'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _diceRoller.history.length,
              itemBuilder: (context, index) {
                final result = _diceRoller.history.reversed.toList()[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: result.isCriticalGlitch
                        ? Colors.red.shade100
                        : result.isGlitch
                        ? Colors.orange.shade100
                        : result.successes >= 1
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.successes.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Erfolge'),
                      if (result.isGlitch)
                        const Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _rollStandard() async {
    setState(() => _isRolling = true);

    // Simuliere kurze Verzögerung für Animation
    await Future.delayed(const Duration(milliseconds: 100));

    final result = _diceRoller.rollDice();
    setState(() {
      _lastResult = result;
      _isRolling = false;
    });

    // Haptisches Feedback
    await _hapticFeedback(result);
  }

  void _rollSkillTest() async {
    setState(() => _isRolling = true);
    await Future.delayed(const Duration(milliseconds: 100));

    final result = _diceRoller.rollSkillCheck(
      _selectedAttribute,
      _selectedSkill,
      modifier: _selectedModifier,
    );

    setState(() {
      _lastResult = result;
      _isRolling = false;
    });

    await _hapticFeedback(result);
  }

  void _rollAttack() async {
    setState(() => _isRolling = true);
    await Future.delayed(const Duration(milliseconds: 100));

    final result = _diceRoller.rollAttack(
      _agility,
      _weaponSkill,
      _weaponAccuracy,
      defensePool: _defensePool,
    );

    setState(() {
      _lastResult = result;
      _isRolling = false;
    });

    await _hapticFeedback(result);
  }

  Future<void> _hapticFeedback(DiceResult result) async {
    // Für haptisches Feedback (wenn verfügbar)
    // In einer echten App könntest du hier HapticFeedback verwenden
    if (result.isCriticalGlitch) {
      // Starkes Vibrationsmuster
    } else if (result.isGlitch) {
      // Mittleres Vibrationsmuster
    } else if (result.successes > 0) {
      // Kurzes Vibrationsmuster
    }
  }
}
