import 'dart:convert';

import 'package:crypto/crypto.dart';

enum TeamPositions { inactive, scout, banger, heavy, blaster, outrider, medico }

enum CharacterStatus {
  fine,
  reeling,
  hurt,
  afraid,
  injured,
  dying,
  dead,
  overkilled,
}

class ObjectPlayer {
  static const String defaultImage = 'urbanbrawl_frame_leer.png';
  int id;
  String name;
  String image = defaultImage;
  int price = 3000;
  TeamPositions position = TeamPositions.inactive;
  CharacterStatus status = CharacterStatus.fine;

  ObjectPlayer({
    required this.id,
    required this.name,
    String? image,
  }) : image = image ?? defaultImage;

  factory ObjectPlayer.newPlayer(String name, String image) {
    final bytes = utf8.encode(name);
    final digest = sha256.convert(bytes);

    return ObjectPlayer(
      id: digest.hashCode,
      name: name,
      image: image,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'price': price,
    'position': position.name,
    'status': status.name,
  };

  factory ObjectPlayer.fromJson(Map<String, dynamic> json) {
    final player = ObjectPlayer(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String? ?? defaultImage,
    );
    player.price = json['price'] as int? ?? 3000;
    player.position = TeamPositions.values.firstWhere(
      (e) => e.name == json['position'],
      orElse: () => TeamPositions.inactive,
    );
    player.status = CharacterStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => CharacterStatus.fine,
    );
    return player;
  }
}
