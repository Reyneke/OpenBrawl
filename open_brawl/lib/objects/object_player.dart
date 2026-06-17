import 'dart:convert';

import 'package:crypto/crypto.dart';

class ObjectPlayer {
  int id;
  String name;
  String image;
  int price = 3000;

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
