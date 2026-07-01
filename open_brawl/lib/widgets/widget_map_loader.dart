import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:open_brawl/utils/tmx_parser.dart';
import 'package:open_brawl/widgets/widget_hex_map_renderer.dart';

/// Lädt eine TMX-Karte und rendert sie als Hex-Grid.
/// Unterstützt die Auswahl von Kacheln und das Platzieren von Tokens auf der Karte.
class WidgetMapLoader extends StatefulWidget {
  final ObjectTeam activeTeam;

  const WidgetMapLoader({super.key, required this.activeTeam});

  @override
  State<WidgetMapLoader> createState() => _WidgetMapLoaderState();
}

class _WidgetMapLoaderState extends State<WidgetMapLoader> {
  Future<TmxMap>? _mapFuture;
  Future<ui.Image>? _tilesetImageFuture;
  int? _selectedCol;
  int? _selectedRow;
  List<ObjectToken> _tokens = [];

  @override
  void initState() {
    super.initState();
    _mapFuture = _loadMapAndGenerateTokens();
  }

  /// Lade die TMX-Karte, ermittle das Zentrum und generiere
  /// ein ObjectToken pro Spieler im aktiven Team.
  Future<TmxMap> _loadMapAndGenerateTokens() async {
    final tmxMap = await TmxMap.loadFromJsonAsset('assets/maps/test.tmj');

    // Start loading the tileset image in parallel
    _tilesetImageFuture = _loadTilesetImage(tmxMap.tileset.imageAssetPath);

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
      });
    }

    return tmxMap;
  }

  /// Load a tileset PNG image from assets and decode it to a [ui.Image].
  Future<ui.Image> _loadTilesetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  void _onTileTap((int, int) tile) {
    final (col, row) = tile;
    setState(() {
      // Toggle selection: deselect if tapping the same tile, otherwise select
      if (_selectedCol == col && _selectedRow == row) {
        _selectedCol = null;
        _selectedRow = null;
      } else {
        _selectedCol = col;
        _selectedRow = row;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmxMap>(
      future: _mapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Fehler beim Laden der Karte:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final tmxMap = snapshot.data!;
        return FutureBuilder<ui.Image>(
          future: _tilesetImageFuture,
          builder: (context, imageSnapshot) {
            final tilesetImage = imageSnapshot.data;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: HexMapRenderer(
                  map: tmxMap,
                  tokens: _tokens,
                  selectedCol: _selectedCol,
                  selectedRow: _selectedRow,
                  onTileTap: _onTileTap,
                  tilesetImage: tilesetImage,
                ),
              ),
            );
          },
        );
      },
    );
  }
}