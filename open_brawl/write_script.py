
import os

content = """import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:universal_file_picker/universal_file_picker.dart';

class WidgetImageSelect extends StatefulWidget {
  final Object rootObject;
  final String titleText;
  const WidgetImageSelect({
    super.key,
    required this.titleText,
    required this.rootObject,
  });

  @override
  State<WidgetImageSelect> createState() => _WidgetImageSelectState();
}

class _WidgetImageSelectState extends State<WidgetImageSelect> {
  bool _isUploading = false;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    if (widget.rootObject is ObjectPlayer) {
      final imageObject = widget.rootObject as ObjectPlayer;
      if (imageObject.image.isNotEmpty) {
        _imageUrl = imageObject.image;
      }
    } else if (widget.rootObject is ObjectTeam) {
      final imageObject = widget.rootObject as ObjectTeam;
      if (imageObject.teamLogo.isNotEmpty) {
        _imageUrl = imageObject.teamLogo;
      }
    }

    return GestureDetector(
      child: SizedBox(
        height: 600,
        child: (_imageUrl != null)
            ? (_imageUrl!.startsWith("http")
                ? Image.network(_imageUrl!, height: 150)
                : Image.file(File(_imageUrl!), height: 150))
            : Container(
                width: 175,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: Text("No image availible - yet"),
              ),
      ),
      onTap: () {
        _selectAndUploadImage();
      },
    );
  }

  Future<String?> _saveImageLocally(UFile imageFile) async {
    try {
      final File file = File(imageFile.path ?? "");
      if (!await file.exists()) {
        throw Exception('Datei existiert nicht: ${imageFile.path}');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Datei ist leer');
      }

      final appDirectory = await getApplicationDocumentsDirectory();
      final teamImageDir = Directory(
        path.join(appDirectory.path, 'team_images'),
      );
      if (!await teamImageDir.exists()) {
        await teamImageDir.create(recursive: true);
      }

      final extension = path.extension(imageFile.path ?? "");
      final fileName =
          'team_${widget.titleText}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = path.join(teamImageDir.path, fileName);

      final savedFile = File(filePath);
      await savedFile.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
      return null;
    }
  }

  Future<String> _uploadTeamLogoToSupabase(UFile imageFile, ObjectTeam team) async {
    final server = context.read<ProviderServer>();
    final userId = server.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final file = File(imageFile.path ?? "");
    if (!await file.exists()) {
      throw Exception('Datei existiert nicht: ${imageFile.path}');
    }

    // Sanitize team name for folder path
    final sanitizedName = team.teamName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .toLowerCase();

    final extension = path.extension(imageFile.path ?? "");
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final storagePath = '$sanitizedName/$fileName';

    // Upload to Supabase Storage bucket "teambanners"
    await server.client.storage
        .from('teambanners')
        .upload(storagePath, file);

    // Get public URL
    final publicUrl = server.client.storage
        .from('teambanners')
        .getPublicUrl(storagePath);

    return publicUrl;
  }

  Future<void> _selectAndUploadImage() async {
    setState(() => _isUploading = true);

    try {
      final file = await UniversalFilePicker().pickFile();
      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      if (widget.rootObject is ObjectTeam) {
        // Upload team logo to Supabase Storage
        final imageObject = widget.rootObject as ObjectTeam;
        final publicUrl = await _uploadTeamLogoToSupabase(file, imageObject);

        _imageUrl = publicUrl;

        final index = context.read<ProviderTeam>().getTeamPosition(
          imageObject,
        );

        if (index >= 0) {
          context.read<ProviderTeam>().teams[index].teamLogo = publicUrl;
          await context.read<ProviderTeam>().updateTeamInDatabase(
            context.read<ProviderTeam>().teams[index],
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team-Bild erfolgreich in die Cloud hochgeladen!'),
          ),
        );
      } else if (widget.rootObject is ObjectPlayer) {
        // Save player image locally
        final localPath = await _saveImageLocally(file);
        if (localPath == null) {
          throw Exception('Fehler beim Speichern des Bildes');
        }

        _imageUrl = localPath;
        final imageObject = widget.rootObject as ObjectPlayer;
        final teamObject = context.read<ProviderTeam>().getCharacterInTeam(
          imageObject,
        );
        imageObject.image = localPath;

        if (teamObject != null) {
          await context.read<ProviderTeam>().modifyCharacterInTeam(
            teamObject,
            imageObject,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spieler-Bild erfolgreich gespeichert!')),
        );
      }

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }
}
"""

with open(r'd:\dev\OpenBrawl\open_brawl\lib\widgets\widget_image_select.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('File written successfully')
