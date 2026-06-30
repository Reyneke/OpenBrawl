import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

class TmxTileset {
  final int firstGid;
  final String source;
  final String name;
  final int tileWidth;
  final int tileHeight;
  final int tileCount;
  final int columns;
  final String imageSource;
  final int imageWidth;
  final int imageHeight;

  TmxTileset({
    required this.firstGid,
    required this.source,
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
    required this.tileCount,
    required this.columns,
    required this.imageSource,
    required this.imageWidth,
    required this.imageHeight,
  });

  int get rows => tileCount ~/ columns;

  /// Get the source rect in the tileset image for a given tile global ID.
  /// Returns (x, y, width, height) in pixels.
  (int, int, int, int) getTileSourceRect(int gid) {
    final localId = gid - firstGid;
    final col = localId % columns;
    final row = localId ~/ columns;
    return (col * tileWidth, row * tileHeight, tileWidth, tileHeight);
  }
}

class TmxMap {
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final int hexSideLength;
  final String staggerAxis;
  final String staggerIndex;
  final String orientation;
  final List<int> tileData; // flat list of tile GIDs
  final TmxTileset tileset;

  TmxMap({
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.hexSideLength,
    required this.staggerAxis,
    required this.staggerIndex,
    required this.orientation,
    required this.tileData,
    required this.tileset,
  });

  int getTileGid(int col, int row) {
    return tileData[row * width + col];
  }

  /// Load and parse a TMX file from assets.
  static Future<TmxMap> loadFromAsset(String assetPath) async {
    final xmlString = await rootBundle.loadString(assetPath);
    final document = XmlDocument.parse(xmlString);
    final mapElement = document.rootElement;

    final width = int.parse(mapElement.getAttribute('width')!);
    final height = int.parse(mapElement.getAttribute('height')!);
    final tileWidth = int.parse(mapElement.getAttribute('tilewidth')!);
    final tileHeight = int.parse(mapElement.getAttribute('tileheight')!);
    final hexSideLength = int.parse(mapElement.getAttribute('hexsidelength') ?? '0');
    final staggerAxis = mapElement.getAttribute('staggeraxis') ?? 'y';
    final staggerIndex = mapElement.getAttribute('staggerindex') ?? 'odd';
    final orientation = mapElement.getAttribute('orientation') ?? 'hexagonal';

    // Parse tileset
    final tilesetElement = mapElement.findElements('tileset').first;
    final firstGid = int.parse(tilesetElement.getAttribute('firstgid')!);
    final source = tilesetElement.getAttribute('source') ?? '';

    // Parse tileset source if it's a reference
    TmxTileset tileset;
    if (source.isNotEmpty) {
      // Resolve relative path: source is relative to the TMX file's directory
      final tmxDir = assetPath.substring(0, assetPath.lastIndexOf('/') + 1);
      final tsxString = await rootBundle.loadString('$tmxDir$source');
      final tsxDocument = XmlDocument.parse(tsxString);
      final tsxElement = tsxDocument.rootElement;

      final name = tsxElement.getAttribute('name') ?? '';
      final tsTileWidth = int.parse(tsxElement.getAttribute('tilewidth')!);
      final tsTileHeight = int.parse(tsxElement.getAttribute('tileheight')!);
      final tileCount = int.parse(tsxElement.getAttribute('tilecount')!);
      final columns = int.parse(tsxElement.getAttribute('columns')!);

      final imageElement = tsxElement.findElements('image').first;
      final imageSource = imageElement.getAttribute('source') ?? '';
      final imageWidth = int.parse(imageElement.getAttribute('width')!);
      final imageHeight = int.parse(imageElement.getAttribute('height')!);

      tileset = TmxTileset(
        firstGid: firstGid,
        source: source,
        name: name,
        tileWidth: tsTileWidth,
        tileHeight: tsTileHeight,
        tileCount: tileCount,
        columns: columns,
        imageSource: imageSource,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
    } else {
      // Inline tileset definition (not expected for our case, but handled)
      final name = tilesetElement.getAttribute('name') ?? '';
      final tsTileWidth = int.parse(tilesetElement.getAttribute('tilewidth')!);
      final tsTileHeight = int.parse(tilesetElement.getAttribute('tileheight')!);
      final tileCount = int.parse(tilesetElement.getAttribute('tilecount')!);
      final columns = int.parse(tilesetElement.getAttribute('columns')!);

      final imageElement = tilesetElement.findElements('image').first;
      final imageSource = imageElement.getAttribute('source') ?? '';
      final imageWidth = int.parse(imageElement.getAttribute('width')!);
      final imageHeight = int.parse(imageElement.getAttribute('height')!);

      tileset = TmxTileset(
        firstGid: firstGid,
        source: source,
        name: name,
        tileWidth: tsTileWidth,
        tileHeight: tsTileHeight,
        tileCount: tileCount,
        columns: columns,
        imageSource: imageSource,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
    }

    // Parse tile layer data (CSV)
    final layerElement = mapElement.findElements('layer').first;
    final dataElement = layerElement.findElements('data').first;
    final encoding = dataElement.getAttribute('encoding') ?? 'csv';

    List<int> tileData;
    if (encoding == 'csv') {
      final csvText = dataElement.innerText.trim();
      tileData = csvText
          .split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();
    } else {
      throw UnsupportedError('Unsupported TMX encoding: $encoding');
    }

    return TmxMap(
      width: width,
      height: height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      hexSideLength: hexSideLength,
      staggerAxis: staggerAxis,
      staggerIndex: staggerIndex,
      orientation: orientation,
      tileData: tileData,
      tileset: tileset,
    );
  }
}