import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:tilemap_engine/tilemap_engine.dart';

/// Rendert eine Hex-Karte (aus der Tilemap-Engine) mit OpenBrawl-Tokens.
///
/// Die Karten-Logik (Tileset-Zeichnung, Hit-Test, Hex-Geometrie) kommt aus
/// dem entkoppelten Paket `tilemap_engine` ([HexMapView], [HexGrid], [MapData]).
/// Die Token-Zeichnung bleibt OpenBrawl-spezifisch und wird über den
/// generischen `tokenPainter`-Callback des [HexMapView] realisiert.
class HexMapRenderer extends StatelessWidget {
  final MapData map;
  final HexGrid hexGrid;
  final int? selectedCol;
  final int? selectedRow;
  final ValueChanged<(int col, int row)>? onTileTap;
  final List<ObjectToken> tokens;
  final ui.Image? tilesetImage;

  const HexMapRenderer({
    super.key,
    required this.map,
    required this.hexGrid,
    this.selectedCol,
    this.selectedRow,
    this.onTileTap,
    this.tokens = const [],
    this.tilesetImage,
  });

  @override
  Widget build(BuildContext context) {
    // Token-Figuren für den Engine-Renderer erzeugen: hexCol/hexRow → Pixel.
    final figures = [
      for (final token in tokens)
        HexTokenFigure(
          position: hexGrid.hexToPixel(x: token.hexCol, y: token.hexRow),
          painter: (canvas, center) => _paintToken(canvas, token, hexGrid),
        ),
    ];

    return HexMapView(
      map: map,
      hexGrid: hexGrid,
      tilesetImage: tilesetImage,
      tokens: figures,
      selectedHex:
          selectedCol != null && selectedRow != null
              ? (x: selectedCol!, y: selectedRow!)
              : null,
      onTileTap: onTileTap != null ? (x, y) => onTileTap!((x, y)) : null,
    );
  }

  /// Zeichnet einen OpenBrawl-Token als farbigen Kreis mit Initialen.
  static void _paintToken(
    Canvas canvas,
    ObjectToken token,
    HexGrid hexGrid,
  ) {
    final tokenRadius = (hexGrid.tileWidth * 0.3).clamp(8.0, 18.0);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.lightBlue.shade300;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black54;

    canvas.drawCircle(Offset.zero, tokenRadius, fillPaint);
    canvas.drawCircle(Offset.zero, tokenRadius, linePaint);

    final initial = token.player.name.isNotEmpty
        ? token.player.name[0].toUpperCase()
        : '?';
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: tokenRadius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}