import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/ub_player.dart';

//import 'package:open_brawl/objects/ub_player.dart';

import 'combat_simulator.dart';
//import 'ub_player.dart';

class CombatScreen extends StatefulWidget {
  final List<UbPlayer> players;

  const CombatScreen({
    super.key,
    required this.players,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late CombatSimulator _simulator;
  late TabController _tabController;

  AttackResult? _lastAttackResult;
  Combatant? _selectedDefender;
  CombatAction _selectedAction = CombatAction.attack;
  CombatRange _selectedRange = CombatRange.medium;
  final int _customModifier = 0;

  @override
  void initState() {
    super.initState();
    _simulator = CombatSimulator();
    for (var player in widget.players) {
      _simulator.addCombatant(player);
    }
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Kampfsimulator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Kämpfer'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Kampf-Statusleiste
          if (_simulator.combatActive) _buildCombatStatusBar(),

          // Aktuelle Aktion (wenn Kampf aktiv)
          if (_simulator.combatActive && _simulator.currentActor != null)
            _buildActionPanel(_simulator.currentActor!),

          // Letztes Ergebnis
          if (_lastAttackResult != null)
            _buildAttackResultCard(_lastAttackResult!),

          // Hauptinhalt
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCombatantsList(),
                _buildHistoryList(),
              ],
            ),
          ),

          // Kampf-Buttons
          _buildCombatControls(),
        ],
      ),
    );
  }

  Widget _buildCombatStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Runde',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${_simulator.currentRound}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'Durchgang',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${_simulator.currentInitiativePass}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'Akteur',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _simulator.currentActor?.player.name ?? '-',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(Combatant actor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                '${actor.player.name} ist am Zug',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Aktion auswählen
          const Text('Aktion:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(
                  CombatAction.attack,
                  'Angriff',
                  Icons.sports_mma,
                ),
                _buildActionChip(
                  CombatAction.fullAuto,
                  'Vollauto',
                  Icons.flash_on,
                ),
                _buildActionChip(
                  CombatAction.calledShot,
                  'Gezielter Schuss',
                  Icons.track_changes,
                ),
                _buildActionChip(CombatAction.aim, 'Zielen', Icons.ads_click),
                _buildActionChip(
                  CombatAction.dodge,
                  'Ausweichen',
                  Icons.run_circle,
                ),
                _buildActionChip(
                  CombatAction.takeCover,
                  'Deckung',
                  Icons.shield,
                ),
                _buildActionChip(CombatAction.reload, 'Nachladen', Icons.loop),
              ],
            ),
          ),

          // Reichweite (nur bei Angriffen)
          if (_selectedAction == CombatAction.attack ||
              _selectedAction == CombatAction.fullAuto ||
              _selectedAction == CombatAction.calledShot) ...[
            const SizedBox(height: 12),
            const Text(
              'Reichweite:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRangeChip(
                    CombatRange.close,
                    'Nah (+2)',
                    Icons.touch_app,
                  ),
                  _buildRangeChip(
                    CombatRange.medium,
                    'Mittel',
                    Icons.remove_red_eye,
                  ),
                  _buildRangeChip(
                    CombatRange.long,
                    'Fern (-2)',
                    Icons.zoom_out_map,
                  ),
                  _buildRangeChip(
                    CombatRange.extreme,
                    'Extrem (-4)',
                    Icons.satellite_alt,
                  ),
                ],
              ),
            ),
          ],

          // Ziel auswählen (nur bei Angriffen)
          if (_selectedAction == CombatAction.attack ||
              _selectedAction == CombatAction.fullAuto ||
              _selectedAction == CombatAction.calledShot) ...[
            const SizedBox(height: 12),
            const Text('Ziel:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _simulator.combatants
                    .where((c) => c != actor && c.isConscious)
                    .map((target) => _buildTargetChip(target))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Ausführen-Button
          ElevatedButton.icon(
            onPressed:
                _selectedDefender != null ||
                    _selectedAction != CombatAction.attack
                ? _executeAction
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Aktion ausführen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(CombatAction action, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        //icon: Icon(icon, size: 16),
        selected: _selectedAction == action,
        onSelected: (_) {
          setState(() {
            _selectedAction = action;
          });
        },
      ),
    );
  }

  Widget _buildRangeChip(CombatRange range, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        //icon: Icon(icon, size: 16),
        selected: _selectedRange == range,
        onSelected: (_) {
          setState(() {
            _selectedRange = range;
          });
        },
      ),
    );
  }

  Widget _buildTargetChip(Combatant target) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(target.player.name),
        selected: _selectedDefender == target,
        onSelected: (_) {
          setState(() {
            _selectedDefender = target;
          });
        },
      ),
    );
  }

  Widget _buildCombatantsList() {
    if (_simulator.combatants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Kämpfer im Kampf'),
            SizedBox(height: 8),
            Text(
              'Füge Charaktere mit + hinzu',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _simulator.combatants.length,
      itemBuilder: (context, index) {
        final combatant = _simulator.combatants[index];
        final isCurrentActor = _simulator.currentActor == combatant;

        return Card(
          elevation: isCurrentActor ? 4 : 1,
          color: isCurrentActor ? Colors.deepPurple.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: combatant.isConscious
                  ? Colors.green
                  : Colors.red,
              child: Text(combatant.player.name[0]),
            ),
            title: Text(
              combatant.player.name,
              style: TextStyle(
                fontWeight: isCurrentActor
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Initiative: ${combatant.currentInitiativeScore}'),
                if (combatant.wounds > 0)
                  Text(
                    'Wundmalus: -${combatant.wounds}',
                    style: const TextStyle(color: Colors.red),
                  ),
                LinearProgressIndicator(
                  value:
                      combatant.player.bodyDamage /
                      combatant.player.maxPhysicalDamage,
                  backgroundColor: Colors.grey.shade300,
                  color:
                      combatant.player.bodyDamage >
                          combatant.player.maxPhysicalDamage / 2
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _simulator.removeCombatant(combatant),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_simulator.roundHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Kampfgeschichte'),
            SizedBox(height: 8),
            Text(
              'Beginne einen Kampf, um Aktionen aufzuzeichnen',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _simulator.roundHistory.length,
      itemBuilder: (context, roundIndex) {
        final round = _simulator.roundHistory[roundIndex];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              'Runde ${round.roundNumber} - ${round.attacks.length} Angriffe',
            ),
            subtitle: Text(
              '${round.timestamp.hour}:${round.timestamp.minute}:${round.timestamp.second}',
            ),
            children: round.attacks.map((attack) {
              return ListTile(
                leading: Icon(
                  attack.hit ? Icons.check_circle : Icons.close,
                  color: attack.hit ? Colors.green : Colors.red,
                ),
                title: Text(attack.message),
                subtitle: Text(
                  'Nettoerfolge: ${attack.netHits} | Schaden: ${attack.finalDamage}',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAttackResultCard(AttackResult result) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hit
            ? (result.isCriticalHit
                  ? Colors.red.shade100
                  : Colors.green.shade100)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            result.hit ? Icons.sports_mma : Icons.shield,
            color: result.hit ? Colors.red : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(result.message)),
          if (result.finalDamage > 0)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                result.finalDamage.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCombatControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!_simulator.combatActive) ...[
            ElevatedButton.icon(
              onPressed: _simulator.combatants.length >= 2
                  ? _startCombat
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Kampf starten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _endCombat,
              icon: const Icon(Icons.stop),
              label: const Text('Kampf beenden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],

          if (_simulator.combatActive && _simulator.currentActor == null)
            ElevatedButton.icon(
              onPressed: _skipTurn,
              icon: const Icon(Icons.skip_next),
              label: const Text('Zug überspringen'),
            ),
        ],
      ),
    );
  }

  void _executeAction() {
    if (_simulator.currentActor == null) return;

    final actor = _simulator.currentActor!;

    // Nicht-Kampfaktionen
    if (_selectedAction == CombatAction.aim ||
        _selectedAction == CombatAction.takeCover ||
        _selectedAction == CombatAction.reload) {
      _simulator.performNonCombatAction(actor, _selectedAction);
      setState(() {
        _lastAttackResult = null;
      });
      return;
    }

    // Angriffsaktion
    if (_selectedDefender != null) {
      final result = _simulator.performAttack(
        actor,
        _selectedDefender!,
        action: _selectedAction,
        range: _selectedRange,
        customModifier: _customModifier,
      );

      setState(() {
        _lastAttackResult = result;
        _selectedDefender = null;
      });

      // Prüfen, ob der Kampf vorbei ist
      if (_selectedDefender?.isDead == true) {
        _showDefeatMessage(_selectedDefender!);
      }
    }
  }

  void _startCombat() {
    _simulator.rollInitiative();
    setState(() {});
  }

  void _endCombat() {
    final summary = _simulator.endCombat();
    _showCombatSummary(summary);
    setState(() {});
  }

  void _skipTurn() {
    if (_simulator.currentActor != null) {
      _simulator.currentActor!.hasActedThisPass = true;
      // Manuell zum nächsten Akteur wechseln
      // (In einer vollständigen Implementierung würde _updateCurrentActor aufgerufen)
      setState(() {});
    }
  }

  void _showDefeatMessage(Combatant defeated) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${defeated.player.name} wurde besiegt!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCombatSummary(CombatSummary summary) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kampf beendet'),
          content: SingleChildScrollView(
            child: Text(summary.summary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
