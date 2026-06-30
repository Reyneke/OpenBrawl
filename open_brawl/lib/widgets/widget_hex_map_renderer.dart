import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:open_brawl/utils/tmx_parser.dart';

/// Renders a hex grid map loaded from a TMX file.
class HexMapRenderer extends StatelessWidget {
  final TmxMap map;
  final int? selectedCol;
  final int? selectedRow;
  final ValueChanged<(int col, int row)>? onTileTap;
  final List<ObjectToken> tokens;

  const HexMapRenderer({
    super.key,
    required this.map,
    this.selectedCol,
    this.selectedRow,
    this.onTileTap,
    this.tokens = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate widget size based on map dimensions
        final hexWidth = map.tileWidth.toDouble();
        final hexHeight = map.tileHeight.toDouble();
        final rowSpacing = hexHeight * 0.75;
        final totalWidth = map.width * hexWidth + hexWidth / 2; // extra half for odd row offset
        final totalHeight = map.height * rowSpacing + hexHeight / 4;

        return GestureDetector(
          onTapDown: (details) {
            if (onTileTap == null) return;
            final pos = details.localPosition;
            final tile = hitTest(pos);
            if (tile != null) {
              onTileTap!.call(tile);
            }
          },
          child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: CustomPaint(
              painter: _HexMapPainter(
                map: map,
                tokens: tokens,
                selectedCol: selectedCol,
                selectedRow: selectedRow,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hit-test pixel position against the hex grid.
  (int, int)? hitTest(Offset position) {
    final hexWidth = map.tileWidth.toDouble();
    final hexHeight = map.tileHeight.toDouble();
    final hexSize = map.hexSideLength.toDouble();
    final rowSpacing = hexHeight * 0.75;

    for (int row = 0; row < map.height; row++) {
      for (int col = 0; col < map.width; col++) {
        final center = getHexCenter(col, row, hexWidth, hexHeight, rowSpacing);
        if (_isPointInHex(position, center, hexSize)) {
          return (col, row);
        }
      }
    }
    return null;
  }

  /// Get the pixel center of a hex tile at (col, row).
  static Offset getHexCenter(
    int col,
    int row,
    double hexWidth,
    double hexHeight,
    double rowSpacing,
  ) {
    final x = col * hexWidth + (row.isOdd ? hexWidth / 2 : 0) + hexWidth / 2;
    final y = row * rowSpacing + hexHeight / 2;
    return Offset(x, y);
  }

  /// Check if a point is inside a regular hexagon.
  static bool _isPointInHex(Offset point, Offset center, double hexSize) {
    final dx = (point.dx - center.dx).abs();
    final dy = (point.dy - center.dy).abs();

    // Quick bounding box rejection
    if (dx > hexSize * math.sqrt(3) / 2 || dy > hexSize) return false;

    // The hex extends from top point to bottom point
    // For pointy-top hex: the left/right edges are slanted lines
    // Testing against the two diagonal edges:
    // The right edge has slope dy/dx = 1/sqrt(3) for the upper-right line
    return dy <= hexSize * (1 - dx / (hexSize * math.sqrt(3) / 2) * 0.5) * 2 - hexSize;
    // Simplified version: just check bounding box for now
    // This is a rough check sufficient for most purposes
  }
}

class _HexMapPainter extends CustomPainter {
  final TmxMap map;
  final int? selectedCol;
  final int? selectedRow;
  final List<ObjectToken> tokens;

  _HexMapPainter({
    required this.map,
    this.selectedCol,
    this.selectedRow,
    this.tokens = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hexWidth = map.tileWidth.toDouble();
    final hexHeight = map.tileHeight.toDouble();
    final hexSize = map.hexSideLength.toDouble();
    final rowSpacing = hexHeight * 0.75;

    // Build hexagon path (pointy-top)
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (90 - 60 * i);
      final px = hexSize * math.cos(angle);
      final py = hexSize * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(px, py);
      } else {
        hexPath.lineTo(px, py);
      }
    }
    hexPath.close();

    final tilePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black45;

    // Colors for different tile GIDs
    const tileColors = {
      0: Color(0xFF2D2D2D), // empty
      73: Color(0xFF4A7C4F), // grass
    };

    for (int row = 0; row < map.height; row++) {
      for (int col = 0; col < map.width; col++) {
        final center = HexMapRenderer.getHexCenter(
          col, row, hexWidth, hexHeight, rowSpacing,
        );

        canvas.save();
        canvas.translate(center.dx, center.dy);

        final gid = map.getTileGid(col, row);
        final isSelected = col == selectedCol && row == selectedRow;

        // Draw fill
        tilePaint.color = tileColors[gid] ?? const Color(0xFF6B8E6B);
        canvas.drawPath(hexPath, tilePaint);

        // Draw selection highlight
        if (isSelected) {
          final selPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.amber.withAlpha(100);
          canvas.drawPath(hexPath, selPaint);
        }

        // Draw border
        canvas.drawPath(hexPath, borderPaint);

        // Draw tile GID number for debugging (optional)
        // Can be removed later
        if (gid != 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '$gid',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 9,
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

        canvas.restore();
      }
    }

    // Draw tokens on top of the tiles
    final tokenRadius = math.min(hexWidth, hexHeight) * 0.3;
    final tokenLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black54;

    for (final token in tokens) {
      final tokenCenter = HexMapRenderer.getHexCenter(
        token.hexCol, token.hexRow, hexWidth, hexHeight, rowSpacing,
      );

      // Draw token circle with a distinct fill color (light blue)
      final tokenFillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.lightBlue.shade300;
      canvas.save();
      canvas.translate(tokenCenter.dx, tokenCenter.dy);

      canvas.drawCircle(Offset.zero, tokenRadius, tokenFillPaint);
      canvas.drawCircle(Offset.zero, tokenRadius, tokenLinePaint);

      // Draw player initial
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

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HexMapPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.tokens != tokens;
  }
}