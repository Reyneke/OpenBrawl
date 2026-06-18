import 'dart:convert';

import 'package:crypto/crypto.dart';

enum TeamPositions { inactive, scout, banger, heavy, blaster, outrider, medico }

class ObjectPlayer {
  int id;
  String name;
  String image;
  int price = 3000;
  TeamPositions position = TeamPositions.inactive;

  ObjectPlayer({
    required this.id,
    required this.name,
    required this.image,
  });

  factory ObjectPlayer.newPlayer(String name, String image) {
    final bytes = utf8.encode(name);
    final digest = sha256.convert(bytes);

    return ObjectPlayer(
      id: digest.hashCode,
      name: name,
      image: image,
    );
  }
}
