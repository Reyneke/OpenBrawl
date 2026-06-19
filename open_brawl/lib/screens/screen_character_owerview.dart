import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/widgets/widget_image_select.dart';

class ScreenCharacterOwerview extends StatefulWidget {
  final ObjectPlayer currentCharacter;
  const ScreenCharacterOwerview({super.key, required this.currentCharacter});

  @override
  State<ScreenCharacterOwerview> createState() =>
      _ScreenCharacterOwerviewState();
}

class _ScreenCharacterOwerviewState extends State<ScreenCharacterOwerview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Overview: ${widget.currentCharacter.name}"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetImageSelect(titleText: widget.currentCharacter.name),
              Column(
                children: [
                  Text("Player: ${widget.currentCharacter.name}"),
                  Text("Value ${widget.currentCharacter.price}"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
