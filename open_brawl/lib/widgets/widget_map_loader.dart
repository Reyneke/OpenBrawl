import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:tilemap_engine/tilemap_engine.dart';
import 'widget_hex_map_renderer.dart';

/// Lädt eine TMX/TMJ-Karte (über die Tilemap-Engine) und rendert sie als
/// Hex-Grid. Unterstützt die Auswahl von Kacheln und das Platzieren von
/// Tokens auf der Karte.
class WidgetMapLoader extends StatefulWidget {
  final ObjectTeam activeTeam;

  const WidgetMapLoader({super.key, required this.activeTeam});

  @override
  State<WidgetMapLoader> createState() => _WidgetMapLoaderState();
}

class _WidgetMapLoaderState extends State<WidgetMapLoader> {
  static const String _mapAssetPath = 'assets/maps/test.tmj';

  Future<MapData>? _mapFuture;
  Future<ui.Image>? _tilesetImageFuture;
  HexGrid? _hexGrid;
  int? _selectedCol;
  int? _selectedRow;
  List<ObjectToken> _tokens = [];

  @override
  void initState() {
    super.initState();
    _mapFuture = _loadMapAndGenerateTokens();
  }

  /// Lädt die TMJ-Karte über die Engine, löst externe TSX-Tilesets auf,
  /// baut die [HexGrid]-Utility und generiert ein ObjectToken pro Spieler.
  Future<MapData> _loadMapAndGenerateTokens() async {
    final parser = MapParser.forPath(_mapAssetPath);
    var mapData = await parser.loadFromAsset(_mapAssetPath);

    // Externe TSX-Tilesets auflösen: Die Engine speichert bei externen
    // Referenzen nur `source` (ohne Bild-Metadaten). Wir laden die TSX
    // nach, damit `imageSource`, `columns` usw. für Rendering verfügbar sind.
    final resolvedTilesets = <TilesetInfo>[];
    for (final ts in mapData.tilesets) {
      if (ts.source != null && ts.imageSource == null) {
        final tsxPath =
            '${MapParser.basePath(_mapAssetPath)}/${ts.source}';
        final resolved = await parser.loadExternalTileset(tsxPath);
        final baseDir = MapParser.basePath(_mapAssetPath);
        resolvedTilesets.add(TilesetInfo(
          firstGid: resolved.firstGid,
          source: ts.source,
          name: resolved.name,
          tileWidth: resolved.tileWidth,
          tileHeight: resolved.tileHeight,
          tileCount: resolved.tileCount,
          columns: resolved.columns,
          imageSource: resolved.imageSource != null
              ? '$baseDir/${resolved.imageSource}'
              : null,
          imageWidth: resolved.imageWidth,
          imageHeight: resolved.imageHeight,
        ));
      } else {
        resolvedTilesets.add(ts);
      }
    }
    if (resolvedTilesets.isNotEmpty) {
      mapData = mapData.copyWith(tilesets: resolvedTilesets);
    }

    final hexGrid = HexGrid(
      tileWidth: mapData.tileWidth,
      tileHeight: mapData.tileHeight,
      mapWidth: mapData.width,
      mapHeight: mapData.height,
    );
    _hexGrid = hexGrid;

    _tilesetImageFuture = _loadTilesetImage(mapData.tilesets);

    final centerCol = mapData.width ~/ 2;
    final centerRow = mapData.height ~/ 2;

    final generatedTokens = <ObjectToken>[];
    for (final player in widget.activeTeam.players) {
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

    return mapData;
  }

  /// Lädt das erste Tileset-Bild und dekodiert es als [ui.Image].
  Future<ui.Image> _loadTilesetImage(List<TilesetInfo> tilesets) async {
    final imagePath = tilesets.isNotEmpty && tilesets.first.imageSource != null
        ? tilesets.first.imageSource!
        : 'assets/maps/Thespazztikone_tilemaps_005_neu.png';
    final data = await rootBundle.load(imagePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  void _onTileTap((int, int) tile) {
    final (col, row) = tile;
    setState(() {
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
    return FutureBuilder<MapData>(
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

        final mapData = snapshot.data!;
        final hexGrid = _hexGrid;
        if (hexGrid == null) {
          return const Center(
            child: Text('HexGrid konnte nicht erstellt werden.'),
          );
        }

        return FutureBuilder<ui.Image>(
          future: _tilesetImageFuture,
          builder: (context, imageSnapshot) {
            final tilesetImage = imageSnapshot.data;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: HexMapRenderer(
                  map: mapData,
                  hexGrid: hexGrid,
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