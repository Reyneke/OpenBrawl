import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/magic_resonance.dart';
//import 'package:open_brawl/objects/magic_resonance.dart';
//import 'magic_resonance.dart';

class MagicResonanceScreen extends StatefulWidget {
  final MagicResonanceManager manager;

  const MagicResonanceScreen({
    super.key,
    required this.manager,
  });

  @override
  State<MagicResonanceScreen> createState() => _MagicResonanceScreenState();
}

class _MagicResonanceScreenState extends State<MagicResonanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SpellCastingResult? _lastCastResult;

  // Zauberwirken UI
  Spell? _selectedSpell;
  int _selectedForce = 3;
  final bool _isOvercasting = false;

  // Komplexe Form UI
  ComplexForm? _selectedForm;
  int _selectedLevel = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Starter-Inhalt laden, falls nichts vorhanden
    if (widget.manager.knownSpells.isEmpty &&
        widget.manager.adeptPowers.isEmpty &&
        widget.manager.complexForms.isEmpty) {
      _loadStarterContent();
    }
  }

  void _loadStarterContent() {
    if (widget.manager.isMagician) {
      widget.manager.initializeStarterSpells();
    }
    if (widget.manager.isAdept) {
      widget.manager.initializeStarterAdeptPowers();
    }
    if (widget.manager.isTechnomancer) {
      widget.manager.initializeStarterComplexForms();
    }
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
        title: const Text('Magie & Resonanz'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs(),
        ),
      ),
      body: Column(
        children: [
          // Letztes Ergebnis
          if (_lastCastResult != null) _buildResultCard(_lastCastResult!),

          // Hauptinhalt
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _getTabViews(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  List<Tab> _getTabs() {
    List<Tab> tabs = [];

    if (widget.manager.isMagician) {
      tabs.add(const Tab(icon: Icon(Icons.auto_awesome), text: 'Zauber'));
      tabs.add(const Tab(icon: Icon(Icons.book), text: 'Zauberbuch'));
    }

    if (widget.manager.isAdept) {
      tabs.add(const Tab(icon: Icon(Icons.fitness_center), text: 'Kräfte'));
    }

    if (widget.manager.isTechnomancer) {
      tabs.add(const Tab(icon: Icon(Icons.memory), text: 'Resonanz'));
      tabs.add(const Tab(icon: Icon(Icons.list), text: 'Formen'));
    }

    tabs.add(const Tab(icon: Icon(Icons.settings), text: 'Einstellungen'));

    return tabs;
  }

  List<Widget> _getTabViews() {
    List<Widget> views = [];

    if (widget.manager.isMagician) {
      views.add(_buildSpellcastingTab());
      views.add(_buildSpellbookTab());
    }

    if (widget.manager.isAdept) {
      views.add(_buildAdeptPowersTab());
    }

    if (widget.manager.isTechnomancer) {
      views.add(_buildComplexFormTab());
      views.add(_buildComplexFormListTab());
    }

    views.add(_buildSettingsTab());

    return views;
  }

  // ============================================================
  // ZAUBERWIRKEN TAB
  // ============================================================

  Widget _buildSpellcastingTab() {
    if (widget.manager.knownSpells.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Zauber bekannt'),
            Text(
              'Lerne Zauber im Zauberbuch-Tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Zauber auswählen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zauber wählen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Spell>(
                    initialValue: _selectedSpell,
                    hint: const Text('Wähle einen Zauber'),
                    items: widget.manager.knownSpells.map((spell) {
                      return DropdownMenuItem(
                        value: spell,
                        child: Row(
                          children: [
                            Icon(_getSpellIcon(spell.category)),
                            const SizedBox(width: 8),
                            Text(spell.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpell = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedSpell != null) ...[
            // Kraft (Force)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kraft (Force)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              _selectedForce = (_selectedForce - 1).clamp(
                                1,
                                12,
                              );
                            });
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: _selectedForce.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label: _selectedForce.toString(),
                            onChanged: (value) {
                              setState(() {
                                _selectedForce = value.toInt();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _selectedForce = (_selectedForce + 1).clamp(
                                1,
                                12,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Kraft: $_selectedForce',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedForce > widget.manager.magic)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Überladener Zauber! Erhöhter Entzug und Erschwernis.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Zauberdetails
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSpell!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedSpell!.description),
                    const Divider(),
                    _buildInfoRow(
                      'Kategorie',
                      _getCategoryName(_selectedSpell!.category),
                    ),
                    _buildInfoRow(
                      'Reichweite',
                      _getRangeName(_selectedSpell!.range),
                    ),
                    _buildInfoRow(
                      'Dauer',
                      _getDurationName(_selectedSpell!.duration),
                    ),
                    _buildInfoRow(
                      'Entzug',
                      '${_selectedSpell!.drainValue} + (Kraft/2)',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Zauberwirken Button
            ElevatedButton.icon(
              onPressed: () => _castSpell(),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Zauber wirken!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ZAUBERBUCH TAB
  // ============================================================

  Widget _buildSpellbookTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.manager.knownSpells.length,
      itemBuilder: (context, index) {
        final spell = widget.manager.knownSpells[index];
        return Card(
          child: ListTile(
            leading: Icon(
              _getSpellIcon(spell.category),
              color: Colors.deepPurple,
            ),
            title: Text(spell.name),
            subtitle: Text(spell.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _forgetSpell(spell),
            ),
            onTap: () => _showSpellDetails(spell),
          ),
        );
      },
    );
  }

  // ============================================================
  // ADEPTENKRÄFTE TAB
  // ============================================================

  Widget _buildAdeptPowersTab() {
    return Column(
      children: [
        // Magiepunkt-Anzeige
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Magiepunkte',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${widget.manager.remainingPowerPoints.toStringAsFixed(1)} / ${widget.manager.availablePowerPoints}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              LinearProgressIndicator(
                value:
                    widget.manager.usedPowerPoints /
                    widget.manager.availablePowerPoints,
                backgroundColor: Colors.white30,
                color: Colors.yellow,
              ),
            ],
          ),
        ),

        // Verfügbare Kräfte
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.manager.adeptPowers.length,
            itemBuilder: (context, index) {
              final power = widget.manager.adeptPowers[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(power.name),
                  subtitle: Text(
                    '${power.description} | Kosten: ${power.totalCost} MP',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: power.level < 6
                            ? () => _upgradeAdeptPower(power)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeAdeptPower(power),
                      ),
                    ],
                  ),
                  onTap: () => _showAdeptPowerDetails(power),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESONANZ (KOMPLEXE FORMEN) TAB
  // ============================================================

  Widget _buildComplexFormTab() {
    if (widget.manager.complexForms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine komplexen Formen bekannt'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Komplexe Form auswählen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komplexe Form wählen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ComplexForm>(
                    initialValue: _selectedForm,
                    hint: const Text('Wähle eine Form'),
                    items: widget.manager.complexForms.map((form) {
                      return DropdownMenuItem(
                        value: form,
                        child: Row(
                          children: [
                            Icon(_getComplexFormIcon(form.category)),
                            const SizedBox(width: 8),
                            Text(form.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedForm = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedForm != null) ...[
            // Stufe (Level)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stufe (Level)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              _selectedLevel = (_selectedLevel - 1).clamp(
                                1,
                                12,
                              );
                            });
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: _selectedLevel.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label: _selectedLevel.toString(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value.toInt();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _selectedLevel = (_selectedLevel + 1).clamp(
                                1,
                                12,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Stufe: $_selectedLevel',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedForm!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedForm!.description),
                    const Divider(),
                    _buildInfoRow(
                      'Kategorie',
                      _getComplexFormCategoryName(_selectedForm!.category),
                    ),
                    _buildInfoRow(
                      'Verblassung',
                      '${_selectedForm!.fadeValue} + (Stufe/2)',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _useComplexForm(),
              icon: const Icon(Icons.memory),
              label: const Text('Komplexe Form anwenden!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplexFormListTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.manager.complexForms.length,
      itemBuilder: (context, index) {
        final form = widget.manager.complexForms[index];
        return Card(
          child: ListTile(
            leading: Icon(
              _getComplexFormIcon(form.category),
              color: Colors.cyan,
            ),
            title: Text(form.name),
            subtitle: Text(form.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _forgetComplexForm(form),
            ),
            onTap: () => _showComplexFormDetails(form),
          ),
        );
      },
    );
  }

  // ============================================================
  // EINSTELLUNGEN TAB
  // ============================================================

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Magie/Resonanz-Typ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MagicUserType>(
                    initialValue: widget.manager.userType,
                    items: MagicUserType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getUserTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        widget.manager.setMagicUserType(value);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (widget.manager.isMagical) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Magie-Attribut',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('1'),
                        Expanded(
                          child: Slider(
                            value: widget.manager.magic.toDouble(),
                            min: 1,
                            max: (6 + widget.manager.initiationGrade)
                                .toDouble(),
                            divisions: 5 + widget.manager.initiationGrade,
                            label: widget.manager.magic.toString(),
                            onChanged: (value) {
                              widget.manager.setMagic(value.toInt());
                              setState(() {});
                            },
                          ),
                        ),
                        Text('${6 + widget.manager.initiationGrade}'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Magie: ${widget.manager.magic}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.manager.isMagician)
              Card(
                child: ListTile(
                  title: const Text('Initiation'),
                  subtitle: Text(
                    'Aktueller Grad: ${widget.manager.initiationGrade}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _initiate(),
                    child: const Text('Initiieren'),
                  ),
                ),
              ),
          ],

          if (widget.manager.isTechnomancer) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resonanz-Attribut',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('1'),
                        Expanded(
                          child: Slider(
                            value: widget.manager.resonance.toDouble(),
                            min: 1,
                            max: (6 + widget.manager.submersionGrade)
                                .toDouble(),
                            divisions: 5 + widget.manager.submersionGrade,
                            label: widget.manager.resonance.toString(),
                            onChanged: (value) {
                              widget.manager.setResonance(value.toInt());
                              setState(() {});
                            },
                          ),
                        ),
                        Text('${6 + widget.manager.submersionGrade}'),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Resonanz: ${widget.manager.resonance}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text('Tauchgang'),
                subtitle: Text(
                  'Aktueller Grad: ${widget.manager.submersionGrade}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => _submerge(),
                  child: const Text('Tauchen'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HILFSMETHODEN & UI-HELPER
  // ============================================================

  Widget _buildResultCard(SpellCastingResult result) {
    Color bgColor;
    IconData icon;

    if (result.isSuccess) {
      bgColor = Colors.green.shade100;
      icon = Icons.check_circle;
    } else if (result.actualDrain > 0) {
      bgColor = Colors.orange.shade100;
      icon = Icons.warning;
    } else {
      bgColor = Colors.red.shade100;
      icon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(result.message)),
          if (result.actualDrain > 0)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                result.actualDrain.toString(),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget? _buildFAB() {
    if (_tabController.index == 1 && widget.manager.isMagician) {
      return FloatingActionButton(
        onPressed: () => _addSpellDialog(),
        child: const Icon(Icons.add),
      );
    }
    if (_tabController.index == 3 && widget.manager.isTechnomancer) {
      return FloatingActionButton(
        onPressed: () => _addComplexFormDialog(),
        child: const Icon(Icons.add),
      );
    }
    if (_tabController.index == 2 &&
        widget.manager.isAdept &&
        _tabController.length > 3) {
      return FloatingActionButton(
        onPressed: () => _addAdeptPowerDialog(),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // Aktionen
  void _castSpell() {
    if (_selectedSpell == null) return;

    final result = widget.manager.castSpell(_selectedSpell!, _selectedForce);
    setState(() {
      _lastCastResult = result;
    });

    _showResultSnackBar(result);
  }

  void _useComplexForm() {
    if (_selectedForm == null) return;

    final result = widget.manager.useComplexForm(
      _selectedForm!,
      _selectedLevel,
    );
    setState(() {
      _lastCastResult = result;
    });

    _showResultSnackBar(result);
  }

  void _showResultSnackBar(SpellCastingResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _initiate() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Initiation'),
          content: const Text(
            'Möchtest du eine Initiation durchführen? Dies erhöht deinen Magiegrad und ermöglicht neue Fähigkeiten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.manager.initiate();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Initiieren'),
            ),
          ],
        );
      },
    );
  }

  void _submerge() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tauchgang'),
          content: const Text(
            'Möchtest du einen Tauchgang durchführen? Dies erhöht deine Resonanz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.manager.submerge();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Tauchen'),
            ),
          ],
        );
      },
    );
  }

  void _addSpellDialog() {
    // Einfacher Dialog - in einer vollständigen App mit mehr Details
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        SpellCategory selectedCategory = SpellCategory.combat;

        return AlertDialog(
          title: const Text('Neuen Zauber lernen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Zaubername'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SpellCategory>(
                initialValue: selectedCategory,
                items: SpellCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(_getCategoryName(cat)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newSpell = Spell(
                  name: nameController.text,
                  description: 'Neuer Zauber',
                  category: selectedCategory,
                  range: SpellRange.lineOfSight,
                  duration: SpellDuration.instant,
                );
                widget.manager.learnSpell(newSpell);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Lernen'),
            ),
          ],
        );
      },
    );
  }

  void _addAdeptPowerDialog() {
    // Vereinfachter Dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neue Adeptenkraft'),
          content: const Text(
            'Adeptenkraft-Hinzufügung kommt in vollständiger Version',
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

  void _addComplexFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();

        return AlertDialog(
          title: const Text('Neue komplexe Form'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name der Form'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newForm = ComplexForm(
                  name: nameController.text,
                  description: 'Neue komplexe Form',
                  category: ComplexFormCategory.hacking,
                  fadeValue: 2,
                );
                widget.manager.learnComplexForm(newForm);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Lernen'),
            ),
          ],
        );
      },
    );
  }

  void _forgetSpell(Spell spell) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Zauber vergessen'),
          content: Text('Möchtest du "${spell.name}" wirklich vergessen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.manager.forgetSpell(spell);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text(
                'Vergessen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _forgetComplexForm(ComplexForm form) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Komplexe Form vergessen'),
          content: Text('Möchtest du "${form.name}" wirklich vergessen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.manager.forgetComplexForm(form);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text(
                'Vergessen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeAdeptPower(AdeptPower power) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adeptenkraft entfernen'),
          content: Text('Möchtest du "${power.name}" wirklich entfernen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.manager.removeAdeptPower(power);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text(
                'Entfernen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _upgradeAdeptPower(AdeptPower power) {
    if (widget.manager.remainingPowerPoints >= power.powerPointCost) {
      power.level++;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nicht genügend Magiepunkte!')),
      );
    }
  }

  void _showSpellDetails(Spell spell) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(spell.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spell.description),
              const Divider(),
              _buildInfoRow('Kategorie', _getCategoryName(spell.category)),
              _buildInfoRow('Reichweite', _getRangeName(spell.range)),
              _buildInfoRow('Dauer', _getDurationName(spell.duration)),
              _buildInfoRow('Entzug', spell.drainValue.toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  void _showAdeptPowerDetails(AdeptPower power) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(power.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(power.description),
              const Divider(),
              _buildInfoRow(
                'Kategorie',
                _getAdeptPowerCategoryName(power.category),
              ),
              _buildInfoRow(
                'Kosten',
                '${power.totalCost} MP (Stufe ${power.level})',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  void _showComplexFormDetails(ComplexForm form) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(form.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(form.description),
              const Divider(),
              _buildInfoRow(
                'Kategorie',
                _getComplexFormCategoryName(form.category),
              ),
              _buildInfoRow('Verblassung', form.fadeValue.toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  // Text-Konvertierungen
  String _getUserTypeName(MagicUserType type) {
    switch (type) {
      case MagicUserType.mundane:
        return 'Normal (keine Magie)';
      case MagicUserType.adept:
        return 'Adept';
      case MagicUserType.magician:
        return 'Magier';
      case MagicUserType.mysticAdept:
        return 'Mystischer Adept';
      case MagicUserType.technomancer:
        return 'Technomancer';
    }
  }

  String _getCategoryName(SpellCategory category) {
    switch (category) {
      case SpellCategory.combat:
        return 'Kampf';
      case SpellCategory.detection:
        return 'Wahrnehmung';
      case SpellCategory.health:
        return 'Heilung';
      case SpellCategory.illusion:
        return 'Illusion';
      case SpellCategory.manipulation:
        return 'Manipulation';
    }
  }

  String _getRangeName(SpellRange range) {
    switch (range) {
      case SpellRange.touch:
        return 'Berührung';
      case SpellRange.lineOfSight:
        return 'Sichtlinie';
      case SpellRange.lineOfSightEnhanced:
        return 'Verstärkte Sichtlinie';
      case SpellRange.area:
        return 'Fläche';
    }
  }

  String _getDurationName(SpellDuration duration) {
    switch (duration) {
      case SpellDuration.instant:
        return 'Sofort';
      case SpellDuration.sustained:
        return 'Aufrechterhalten';
      case SpellDuration.permanent:
        return 'Permanent';
    }
  }

  String _getAdeptPowerCategoryName(AdeptPowerCategory category) {
    switch (category) {
      case AdeptPowerCategory.physical:
        return 'Körperlich';
      case AdeptPowerCategory.mental:
        return 'Geistig';
      case AdeptPowerCategory.stealth:
        return 'Heimlichkeit';
      case AdeptPowerCategory.combat:
        return 'Kampf';
      case AdeptPowerCategory.social:
        return 'Sozial';
    }
  }

  String _getComplexFormCategoryName(ComplexFormCategory category) {
    switch (category) {
      case ComplexFormCategory.hacking:
        return 'Hacking';
      case ComplexFormCategory.sleaze:
        return 'Heimlichkeit';
      case ComplexFormCategory.attack:
        return 'Angriff';
      case ComplexFormCategory.perception:
        return 'Wahrnehmung';
    }
  }

  IconData _getSpellIcon(SpellCategory category) {
    switch (category) {
      case SpellCategory.combat:
        return Icons.whatshot;
      case SpellCategory.detection:
        return Icons.remove_red_eye;
      case SpellCategory.health:
        return Icons.favorite;
      case SpellCategory.illusion:
        return Icons.style;
      case SpellCategory.manipulation:
        return Icons.touch_app;
    }
  }

  IconData _getComplexFormIcon(ComplexFormCategory category) {
    switch (category) {
      case ComplexFormCategory.hacking:
        return Icons.code;
      case ComplexFormCategory.sleaze:
        return Icons.visibility_off;
      case ComplexFormCategory.attack:
        return Icons.bug_report;
      case ComplexFormCategory.perception:
        return Icons.gesture;
    }
  }
}
