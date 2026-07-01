import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_token.dart';
import 'package:open_brawl/utils/tmx_parser.dart';
import 'package:open_brawl/widgets/widget_hex_map_renderer.dart';
//NOTE This widget is currently not used anywhere in the app. It was replaced by WidgetMapLoader, which also handles token generation and selection.
//NOTE Outdated: This widget loads a TMX map and renders it as a hex grid. It supports tile selection and placing tokens on the map.
/// Widget that loads and displays the hex tile map from "assets/maps/test.tmx".
class WidgetMaploader extends StatefulWidget {
  final List<ObjectToken> tokens;

  const WidgetMaploader({super.key, this.tokens = const []});

  @override
  State<WidgetMaploader> createState() => _WidgetMaploaderState();
}

class _WidgetMaploaderState extends State<WidgetMaploader> {
  Future<TmxMap>? _mapFuture;

  @override
  void initState() {
    super.initState();
    _mapFuture = TmxMap.loadFromAsset('assets/maps/test.tmx');
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: HexMapRenderer(
              map: tmxMap,
              tokens: widget.tokens,
            ),
          ),
        );
      },
    );
  }
}
