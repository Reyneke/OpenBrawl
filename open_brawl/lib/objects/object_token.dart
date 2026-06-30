import 'package:open_brawl/objects/object_player.dart';

class ObjectToken {
  static const String defaultImage = 'playerToken.png';
  int id;
  String image;
  ObjectPlayer player;
  int hexCol;
  int hexRow;

  ObjectToken({
    required this.id,
    required this.player,
    required this.hexCol,
    required this.hexRow,
    String? image,
  }) : image = image ?? defaultImage;

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'player': player.toJson(),
    'hexCol': hexCol,
    'hexRow': hexRow,
  };

  factory ObjectToken.fromJson(Map<String, dynamic> json) {
    return ObjectToken(
      id: json['id'] as int,
      player: ObjectPlayer.fromJson(json['player'] as Map<String, dynamic>),
      hexCol: json['hexCol'] as int,
      hexRow: json['hexRow'] as int,
      image: json['image'] as String? ?? defaultImage,
    );
  }
}