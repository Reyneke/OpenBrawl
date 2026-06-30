import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_market.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ScreenCharacterMarket extends StatefulWidget {
  final ObjectTeam currentTeam;
  const ScreenCharacterMarket({super.key, required this.currentTeam});

  @override
  State<ScreenCharacterMarket> createState() => _ScreenCharacterMarketState();
}

class _ScreenCharacterMarketState extends State<ScreenCharacterMarket> {
  List<ObjectPlayer> buyList = [];
  List<ObjectPlayer> sellList = [];
  Set<int> selectedIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initMarket();
  }

  Future<void> _initMarket() async {
    final market = context.read<ProviderMarket>();
    if (!_isInitialized) {
      await market.initialize(context);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          selectedIds.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Character Market"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final marketPlayers = context.watch<ProviderMarket>().availiblePlayers;
    final teamPlayers = widget.currentTeam.teamPlayers;

    return Scaffold(
      appBar: AppBar(
        title: Text("Character Market"),
      ),
      body: Column(
        children: [
          Card(
            child: Text("Bank: ${widget.currentTeam.teamNuyen} €"),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: marketPlayers.length,
                    itemBuilder: (context, index) {
                      var listItem = marketPlayers[index];

                      return GestureDetector(
                        child: Card(
                          color: selectedIds.contains(listItem.id)
                              ? Colors.green.shade900
                              : AppTheme.darkTheme.cardColor,
                          child: ListTile(
                            title: Text(listItem.name),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (selectedIds.contains(listItem.id)) {
                              selectedIds.remove(listItem.id);
                              buyList.removeAt(
                                buyList.indexWhere(
                                  (item) => item.id == listItem.id,
                                ),
                              );
                            } else {
                              selectedIds.add(listItem.id);
                              buyList.add(listItem);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: teamPlayers.length,
                    itemBuilder: (context, index) {
                      var listItem = teamPlayers[index];

                      return GestureDetector(
                        child: Card(
                          color: selectedIds.contains(listItem.id)
                              ? Colors.green.shade900
                              : AppTheme.darkTheme.cardColor,
                          child: ListTile(
                            title: Text(listItem.name),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (selectedIds.contains(listItem.id)) {
                              selectedIds.remove(listItem.id);
                              sellList.removeAt(
                                sellList.indexWhere(
                                  (item) => item.id == listItem.id,
                                ),
                              );
                            } else {
                              selectedIds.add(listItem.id);
                              sellList.add(listItem);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _handleTransfer();
        },
        child: const Icon((Icons.currency_yen)),
      ),
    );
  }

  Future<void> _handleTransfer() async {
    bool? confirmed = await showConfirmDialog(context);
    int deductable = 0;
    if (confirmed == true) {
      for (var character in buyList) {
        deductable -= character.price;
        if (mounted) {
          await context.read<ProviderMarket>().removeCharacter(
            context,
            character,
          );
          await context.read<ProviderTeam>().addCharacterToTeam(
            widget.currentTeam,
            character,
          );
        }
      }

      for (var character in sellList) {
        deductable += character.price;
        if (mounted) {
          await context.read<ProviderMarket>().addCharacter(context, character);
          await context.read<ProviderTeam>().removeCharacterfromTeam(
            widget.currentTeam,
            character,
          );
        }
      }

      if (mounted) {
        await context.read<ProviderTeam>().adjustMoney(
          widget.currentTeam,
          deductable,
        );
        Navigator.pop(context);
      }
    }
  }

  Future<bool?> showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // verhindert Schließen durch Tippen außerhalb
      builder: (context) => AlertDialog(
        title: const Text('Confirm transfer'),
        content: const Text(
          'Do you really want to transfer the selected players?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Transfer',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
