import 'package:flutter/material.dart';
import 'package:open_brawl/objects/legacy/equipment.dart';
import 'package:open_brawl/objects/legacy/equipment_manager.dart';
import 'package:open_brawl/objects/legacy/ub_player.dart';
//import 'package:open_brawl/objects/equipment.dart';
//import 'package:open_brawl/objects/equipment_manager.dart';
//import 'package:open_brawl/objects/ub_player.dart';

/*import 'equipment.dart';
import 'equipment_manager.dart';
import 'ub_player.dart';*/

class EquipmentManagerScreen extends StatefulWidget {
  final UbPlayer player;
  final EquipmentManager equipmentManager;

  const EquipmentManagerScreen({
    super.key,
    required this.player,
    required this.equipmentManager,
  });

  @override
  State<EquipmentManagerScreen> createState() => _EquipmentManagerScreenState();
}

class _EquipmentManagerScreenState extends State<EquipmentManagerScreen> {
  int _selectedTab = 0; // 0: Waffen, 1: Rüstung, 2: Ausrüstung

  @override
  void initState() {
    super.initState();
    if (widget.equipmentManager.weapons.isEmpty) {
      widget.equipmentManager.loadStarterEquipment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausrüstungsmanager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          tabs: const [
            Tab(icon: Icon(Icons.sports_mma), text: 'Waffen'),
            Tab(icon: Icon(Icons.shield), text: 'Rüstung'),
            Tab(icon: Icon(Icons.backpack), text: 'Ausrüstung'),
          ],
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Ausgerüstete Gegenstände anzeigen
          _buildEquippedBar(),
          // Hauptinhalt
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildWeaponsTab(),
                _buildArmorTab(),
                _buildGearTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEquippedBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.deepPurple.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Primäre Waffe
          _buildEquippedWeaponTile(
            widget.equipmentManager.equippedWeapon,
            true,
          ),
          const VerticalDivider(),
          // Sekundäre Waffe
          _buildEquippedWeaponTile(
            widget.equipmentManager.equippedWeaponTwo,
            false,
          ),
          const VerticalDivider(),
          // Rüstung
          _buildEquippedArmorTile(),
        ],
      ),
    );
  }

  Widget _buildEquippedWeaponTile(Weapon? weapon, bool isPrimary) {
    if (weapon == null) {
      return GestureDetector(
        onTap: () => _showWeaponSelectionDialog(isPrimary),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text('Keine Waffe'),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showWeaponSelectionDialog(isPrimary),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_mma, color: Colors.deepPurple),
          ),
          const SizedBox(height: 4),
          Text(
            weapon.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Schaden: ${weapon.damage}K',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedArmorTile() {
    final armor = widget.equipmentManager.equippedArmor;

    if (armor == null) {
      return GestureDetector(
        onTap: () => _showArmorSelectionDialog(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text('Keine Rüstung'),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showArmorSelectionDialog(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            armor.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Rüstung: ${armor.rating}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponsTab() {
    final weapons = widget.equipmentManager.weapons;

    if (weapons.isEmpty) {
      return const Center(
        child: Text('Keine Waffen im Inventar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weapons.length,
      itemBuilder: (context, index) {
        final weapon = weapons[index];
        final isEquipped =
            widget.equipmentManager.equippedWeapon == weapon ||
            widget.equipmentManager.equippedWeaponTwo == weapon;

        return Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.sports_mma,
              color: isEquipped ? Colors.deepPurple : Colors.grey,
            ),
            title: Text(weapon.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schaden: ${weapon.damage}K | AP: ${weapon.armorPenetration}',
                ),
                Text(
                  'Reichweite: ${weapon.rangeClose}/${weapon.rangeMedium}/${weapon.rangeLong}m',
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEquipped)
                  const Chip(
                    label: Text('Ausgerüstet'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeWeapon(weapon),
                ),
              ],
            ),
            onTap: () => _showWeaponDetails(weapon),
          ),
        );
      },
    );
  }

  Widget _buildArmorTab() {
    final armors = widget.equipmentManager.armors;

    if (armors.isEmpty) {
      return const Center(
        child: Text('Keine Rüstung im Inventar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: armors.length,
      itemBuilder: (context, index) {
        final armor = armors[index];
        final isEquipped = widget.equipmentManager.equippedArmor == armor;

        return Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.shield,
              color: isEquipped ? Colors.blue : Colors.grey,
            ),
            title: Text(armor.name),
            subtitle: Text(
              'Rüstung: ${armor.rating} | Kapazität: ${armor.capacity}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEquipped)
                  const Chip(
                    label: Text('Ausgerüstet'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeArmor(armor),
                ),
              ],
            ),
            onTap: () => _showArmorDetails(armor),
          ),
        );
      },
    );
  }

  Widget _buildGearTab() {
    final gear = widget.equipmentManager.gear;

    if (gear.isEmpty) {
      return const Center(
        child: Text('Keine Ausrüstung im Inventar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gear.length,
      itemBuilder: (context, index) {
        final item = gear[index];

        return Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.backpack),
            title: Text(item.name),
            subtitle: Text(item.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeGear(item),
            ),
            onTap: () => _showGearDetails(item),
          ),
        );
      },
    );
  }

  // Dialoge für Auswahl und Details
  void _showWeaponSelectionDialog(bool isPrimary) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isPrimary ? 'Primäre Waffe wählen' : 'Sekundäre Waffe wählen',
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: widget.equipmentManager.weapons.length,
              itemBuilder: (context, index) {
                final weapon = widget.equipmentManager.weapons[index];
                return ListTile(
                  title: Text(weapon.name),
                  subtitle: Text('Schaden: ${weapon.damage}K'),
                  onTap: () {
                    widget.equipmentManager.equipWeapon(
                      weapon,
                      isPrimary: isPrimary,
                    );
                    Navigator.pop(context);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showArmorSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rüstung wählen'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: widget.equipmentManager.armors.length,
              itemBuilder: (context, index) {
                final armor = widget.equipmentManager.armors[index];
                return ListTile(
                  title: Text(armor.name),
                  subtitle: Text('Rüstung: ${armor.rating}'),
                  onTap: () {
                    widget.equipmentManager.equipArmor(armor);
                    Navigator.pop(context);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showWeaponDetails(Weapon weapon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(weapon.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schaden: ${weapon.damage}K'),
              Text('Rüstungsdurchdringung: ${weapon.armorPenetration}'),
              Text('Genauigkeit: ${weapon.accuracy}'),
              Text(
                'Reichweite: ${weapon.rangeClose}/${weapon.rangeMedium}/${weapon.rangeLong}m',
              ),
              Text('Munition: ${weapon.ammo} (${weapon.ammoType})'),
              Text('Preis: ${weapon.cost}¥'),
              const SizedBox(height: 8),
              Text(weapon.description),
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

  void _showArmorDetails(Armor armor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(armor.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rüstungswert: ${armor.rating}'),
              Text('Kapazität: ${armor.capacity}'),
              Text('Sozialmodifikator: ${armor.socialModifier}'),
              Text('Preis: ${armor.cost}¥'),
              const SizedBox(height: 8),
              Text(armor.description),
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

  void _showGearDetails(Gear item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              const SizedBox(height: 8),
              Text('Gewicht: ${item.weight}kg'),
              Text('Preis: ${item.cost}¥'),
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

  void _showAddItemDialog() {
    // Einfacher Dialog zum Hinzufügen von Gegenständen
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        int selectedType = 0;

        return AlertDialog(
          title: const Text('Neuen Gegenstand hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Waffe')),
                  DropdownMenuItem(value: 1, child: Text('Rüstung')),
                  DropdownMenuItem(value: 2, child: Text('Ausrüstung')),
                ],
                onChanged: (value) {
                  if (value != null) selectedType = value;
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
                // Hier könntest du einen detaillierteren Dialog öffnen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Detaillierte Gegenstandserstellung kommt später',
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  void _removeWeapon(Weapon weapon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Waffe entfernen'),
          content: Text('Möchtest du "${weapon.name}" wirklich entfernen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.equipmentManager.removeWeapon(weapon);
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

  void _removeArmor(Armor armor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rüstung entfernen'),
          content: Text('Möchtest du "${armor.name}" wirklich entfernen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.equipmentManager.removeArmor(armor);
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

  void _removeGear(Gear gear) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ausrüstung entfernen'),
          content: Text('Möchtest du "${gear.name}" wirklich entfernen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                widget.equipmentManager.removeGear(gear);
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
}
