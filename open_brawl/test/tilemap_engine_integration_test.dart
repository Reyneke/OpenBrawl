import 'package:flutter_test/flutter_test.dart';
import 'package:tilemap_engine/tilemap_engine.dart';

/// Integrationstest: Die Tilemap-Engine (Git-Submodul) lädt die OpenBrawl-Karte
/// `test.tmj` inkl. externem TSX-Tileset und erzeugt eine sinnvolle HexGrid-Utility.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tilemap-Engine Integration (OpenBrawl test.tmj)', () {
    late MapData mapData;
    late HexGrid hexGrid;

    setUpAll(() async {
      const mapPath = 'assets/maps/test.tmj';
      final parser = MapParser.forPath(mapPath);
      mapData = await parser.loadFromAsset(mapPath);

      hexGrid = HexGrid(
        tileWidth: mapData.tileWidth,
        tileHeight: mapData.tileHeight,
        mapWidth: mapData.width,
        mapHeight: mapData.height,
      );
    });

    test('Karte wird geladen: 30x20 Hex, tileWidth/tileHeight 32', () {
      expect(mapData.width, 30);
      expect(mapData.height, 20);
      expect(mapData.tileWidth, 32);
      expect(mapData.tileHeight, 32);
      expect(mapData.orientation, MapOrientation.hexagonal);
    });

    test('Tile-Ebene "Kachelebene 1" enthaelt 600 Tiles (alle 73)', () {
      final layer = mapData.layerByName('Kachelebene 1');
      expect(layer, isNotNull);
      expect(layer!.width, 30);
      expect(layer.height, 20);
      expect(layer.isEmpty, isFalse);
      // Flaches Array: 30 x 20 = 600 GIDs
      expect(layer.tileData.length, 600);
      // Alle Eintraege sind 73 (Gras)
      expect(layer.tileData.every((id) => id == 73), isTrue);
    });

    test('Externes Tileset wird als Referenz geparst (source gesetzt)', () {
      expect(mapData.tilesets, isNotEmpty);
      final ts = mapData.tilesets.first;
      expect(ts.firstGid, 1);
      expect(ts.source, 'Thespazztikone_tilemaps_005_neu.tsx');
    });

    test('Externes Tileset-TSX kann ueber die Engine nachgeladen werden', () async {
      final parser = MapParser.forPath('assets/maps/test.tmj');
      final resolved = await parser.loadExternalTileset(
        'assets/maps/Thespazztikone_tilemaps_005_neu.tsx',
      );
      expect(resolved.tileWidth, 32);
      expect(resolved.tileHeight, 32);
      expect(resolved.columns, isNotNull);
      expect(resolved.tileCount, isNotNull);
      expect(resolved.imageSource, 'Thespazztikone_tilemaps_005_neu.png');
    });

    test('HexGrid: Pixel↔Hex-Roundtrip und Map-Dimensionen', () {
      // Ecke (0,0) und Ende der Karte
      final hex = hexGrid.hexToPixel(x: 0, y: 0);
      expect(hexGrid.pixelToHex(hex), (x: 0, y: 0));

      final last = hexGrid.hexToPixel(
        x: hexGrid.mapWidth - 1,
        y: hexGrid.mapHeight - 1,
      );
      expect(hexGrid.pixelToHex(last), (
        x: hexGrid.mapWidth - 1,
        y: hexGrid.mapHeight - 1,
      ));

      expect(hexGrid.mapPixelWidth, 30 * 32 + 16);
      expect(hexGrid.mapPixelHeight, (20 * 32 * 3 ~/ 4) + 32 ~/ 4);
    });

    test('Objektgruppen: spawn_1/spawn_2 sind vorhanden', () {
      final group = mapData.objectGroups.isNotEmpty
          ? mapData.objectGroups.first
          : null;
      expect(group, isNotNull);
      expect(group!.name, 'Objektebene 1');
      expect(group.objects, hasLength(2));
      expect(group.objects[0].name, 'spawn_2');
      expect(group.objects[1].name, 'spawn_1');
    });
  });
}