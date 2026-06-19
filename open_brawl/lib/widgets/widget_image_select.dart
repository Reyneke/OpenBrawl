import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:universal_file_picker/universal_file_picker.dart';

class WidgetImageSelect extends StatefulWidget {
  final String titleText;
  const WidgetImageSelect({super.key, required this.titleText});

  @override
  State<WidgetImageSelect> createState() => _WidgetImageSelectState();
}

class _WidgetImageSelectState extends State<WidgetImageSelect> {
  bool _isUploading = false;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: 600,
        child: (_imageUrl != null)
            ? Image.file(File(_imageUrl!), height: 150)
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
      // 1. WICHTIG: Die Bytes aus der Datei lesen!
      // Der universial_file_picker gibt nur den Pfad, nicht immer die Bytes direkt.
      final File file = File(imageFile.path ?? "");
      if (!await file.exists()) {
        throw Exception('Datei existiert nicht: ${imageFile.path}');
      }

      // 2. Bytes einlesen
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Datei ist leer');
      }

      // 3. App-Ordner finden
      final appDirectory = await getApplicationDocumentsDirectory();
      final teamImageDir = Directory(
        path.join(appDirectory.path, 'team_images'),
      );
      if (!await teamImageDir.exists()) {
        await teamImageDir.create(recursive: true);
      }

      // 4. Eindeutigen Dateinamen generieren
      final extension = path.extension(imageFile.path ?? ""); // z.B. ".jpg"
      final fileName =
          'team_${widget.titleText}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = path.join(teamImageDir.path, fileName);

      // 5. Datei schreiben
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(bytes);

      //print('Bild gespeichert unter: $filePath');
      return filePath;
    } catch (e) {
      //print('Fehler beim Speichern: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
      return null;
    }
  }

  Future<void> _selectAndUploadImage() async {
    setState(() => _isUploading = true);

    try {
      // Bild auswählen
      final file = await UniversalFilePicker().pickFile();
      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Debug-Ausgabe: Pfad prüfen
      //print('Ausgewählte Datei: ${file.path}');
      //print('Datei existiert? ${await File(file.path).exists()}');

      // Lokal speichern
      final localPath = await _saveImageLocally(file);
      if (localPath == null) {
        throw Exception('Fehler beim Speichern des Bildes');
      }

      setState(() {
        _imageUrl = localPath;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team-Bild erfolgreich gespeichert!')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }
}
