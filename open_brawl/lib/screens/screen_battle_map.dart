import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:open_brawl/utils/tmx_parser.dart';
import 'package:open_brawl/widgets/widget_maploader.dart';
import 'package:provider/provider.dart';

class ScreenBattleMap extends StatefulWidget {
  final ObjectTeam activeTeam;

  const ScreenBattleMap({super.key, required this.activeTeam});

  @override
  State<ScreenBattleMap> createState() => _ScreenBattleMapState();
}

class _ScreenBattleMapState extends State<ScreenBattleMap> {
  List<ObjectToken> _tokens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  /// Lade jeweils ein Objekt vom Typ ObjectToken pro Spieler im Team
  /// und platziere sie im Zentrum der Map.
  Future<void> _loadTokens() async {
    try {
      final tmxMap = await TmxMap.loadFromAsset('assets/maps/test.tmx');
      final centerCol = tmxMap.width ~/ 2;
      final centerRow = tmxMap.height ~/ 2;

      final generatedTokens = <ObjectToken>[];
      for (final player in widget.activeTeam.teamPlayers) {
        generatedTokens.add(ObjectToken(
          id: player.id,
          player: player,
          hexCol: centerCol,
          hexRow: centerRow,
        ));
      }

      if (mounted) {
        setState(() {
          _tokens = generatedTokens;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<ProviderTeam>();
    final teamIndex = teamProvider.teams.indexWhere(
      (t) => t.teamId == widget.activeTeam.teamId,
    );
    final team = teamIndex >= 0 ? teamProvider.teams[teamIndex] : widget.activeTeam;

    return Scaffold(
      appBar: AppBar(
        title: Text(team.teamName),
      ),
      body: Row(
        children: [
          // Left sidebar: Team member list
          SizedBox(
            width: 200,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Teammitglieder',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: team.teamPlayers.length,
                      itemBuilder: (context, index) {
                        final player = team.teamPlayers[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            player.position.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Main content area: Map + bottom text
          Expanded(
            child: Column(
              children: [
                // Map area (scrollable and zoomable)
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: WidgetMaploader(tokens: _tokens),
                  ),
                ),
                const Divider(height: 1),
                // Bottom text box with Lorem Ipsum
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 220),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.all(16),
                  child: const SingleChildScrollView(
                    child: Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                      'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                      'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
                      'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in '
                      'culpa qui officia deserunt mollit anim id est laborum.\n\n'
                      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
                      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa '
                      'quae ab illo inventore veritatis et quasi architecto beatae vitae '
                      'dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit '
                      'aspernatur aut odit aut fugit, sed quia consequuntur magni dolores '
                      'eos qui ratione voluptatem sequi nesciunt.\n\n'
                      'At vero eos et accusamus et iusto odio dignissimos ducimus qui '
                      'blanditiis praesentium voluptatum deleniti atque corrupti quos '
                      'dolores et quas molestias excepturi sint occaecati cupiditate non '
                      'provident, similique sunt in culpa qui officia deserunt mollitia '
                      'animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis '
                      'est et expedita distinctio.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
