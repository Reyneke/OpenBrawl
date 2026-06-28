import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/objects/object_team.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String? _displayUrl;
  String? _storedPath;

  /// Returns true if [path] is a Supabase storage path (not a URL, not a local file path).
  bool _isStoragePath(String path) {
    // Local file paths typically contain ':' (Windows: C:\) or start with '/' (Unix /data/...)
    // HTTP URLs start with 'http'
    // Storage paths look like: "folderId/filename.ext"
    return !path.startsWith('http') &&
        !path.contains(':') &&
        !path.startsWith('/');
  }

  /// Generates and caches a signed URL for a Supabase storage path.
  Future<void> _refreshSignedUrl(String storagePath) async {
    try {
      final signedUrl = await _getSignedUrl(storagePath);
      if (mounted && _storedPath == storagePath) {
        setState(() {
          _displayUrl = signedUrl;
        });
      }
    } catch (e) {
      // If signed URL fails, keep whatever was there before
      debugPrint('Failed to generate signed URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the raw stored value from the root object
    String? rawValue;
    String? resolvedStoragePath;
    if (widget.rootObject is ObjectPlayer) {
      final imageObject = widget.rootObject as ObjectPlayer;
      if (imageObject.image.isNotEmpty) {
        rawValue = imageObject.image;
      }
    } else if (widget.rootObject is ObjectTeam) {
      final imageObject = widget.rootObject as ObjectTeam;
      if (imageObject.teamLogo.isNotEmpty) {
        rawValue = imageObject.teamLogo;
        // If it's an old public URL (e.g. from before the signed URL fix),
        // extract the storage path so we can generate a signed URL.
        final extracted = _extractStoragePath(rawValue);
        if (extracted != null) {
          resolvedStoragePath = extracted;
        }
      }
    }

    // If the raw value changed, re-evaluate what to display
    final effectivePath = resolvedStoragePath ?? rawValue;
    if (effectivePath != null && effectivePath != _storedPath) {
      _storedPath = effectivePath;
      if (_isStoragePath(effectivePath)) {
        // It's a Supabase storage path – generate a signed URL for display
        _displayUrl = null; // Clear while loading
        _refreshSignedUrl(effectivePath);
      } else {
        // It's either a local file path or an HTTP URL – use directly
        _displayUrl = effectivePath;
      }
    }

    return GestureDetector(
      child: SizedBox(
        height: 600,
        child: (_displayUrl != null)
            ? (_displayUrl!.startsWith('http')
                  ? Image.network(_displayUrl!, height: 150)
                  : Image.file(File(_displayUrl!), height: 150))
            : Container(
                width: 175,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
                child: _storedPath != null && _displayUrl == null
                    ? const CircularProgressIndicator()
                    : const Text("No image availible - yet"),
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

  /// Generates a signed URL for the given storage path in the "teambanners" bucket.
  /// The URL is valid for 60 minutes and includes the authentication token,
  /// so it works with Supabase policies that require authenticated access.
  Future<String> _getSignedUrl(String storagePath) async {
    final server = context.read<ProviderServer>();
    return await server.client.storage
        .from('teambanners')
        .createSignedUrl(storagePath, 60 * 60); // 60 Minuten gültig
  }

  /// Returns the storage path for a given signed or public URL, or null if not a Supabase URL.
  /// The returned path is relative to the "teambanners" bucket (e.g. "uuid/filename.ext").
  String? _extractStoragePath(String url) {
    // Pattern: https://<project>.supabase.co/storage/v1/object/<type>/teambanners/<path>
    final supabaseUrl = context.read<ProviderServer>().supabaseUrl;
    final prefix = '$supabaseUrl/storage/v1/object/';
    if (!url.startsWith(prefix)) return null;
    // Find "teambanners/" and return everything after it (the path within the bucket)
    final bucketPrefix = 'teambanners/';
    final bucketIndex = url.indexOf(bucketPrefix);
    if (bucketIndex == -1) return null;
    return url.substring(bucketIndex + bucketPrefix.length);
  }

  Future<String> _uploadTeamLogoToSupabase(
    UFile imageFile,
    ObjectTeam team,
  ) async {
    final server = context.read<ProviderServer>();
    final userId = server.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final file = File(imageFile.path ?? "");
    if (!await file.exists()) {
      throw Exception('Datei existiert nicht: ${imageFile.path}');
    }

    // Use the team's unique ID (dbId UUID) as the folder name.
    // This ensures banners are organized by the team's stable identifier,
    // not by the team name (which the user can rename at any time).
    // Falls back to teamId (int) if dbId is not yet set (new unsaved team).
    final teamFolderId = team.dbId ?? team.teamId.toString();

    final extension = path.extension(imageFile.path ?? "");
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final storagePath = '$teamFolderId/$fileName';

    // Upload to Supabase Storage bucket "teambanners"
    // Pass owner metadata so the Supabase Storage INSERT policy
    // ("owner_can_insert") can verify auth.uid() == owner.
    await server.client.storage
        .from('teambanners')
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            upsert: false,
            metadata: {'owner': userId},
          ),
        );

    // Return the storage path (not a public URL) so callers can generate
    // a signed URL on demand. This avoids the HTTP 400 error caused by
    // fetching a /public/ URL without an auth token while the bucket's
    // policy requires authentication.
    return storagePath;
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
        final storagePath = await _uploadTeamLogoToSupabase(file, imageObject);

        // Store the storage path; the build() method will generate a signed URL
        _storedPath = storagePath;
        _displayUrl = null;
        _refreshSignedUrl(storagePath);

        final index = context.read<ProviderTeam>().getTeamPosition(
          imageObject,
        );

        if (index >= 0) {
          // Store the storage path (not a public URL) in teamLogo
          context.read<ProviderTeam>().teams[index].teamLogo = storagePath;
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

        _storedPath = localPath;
        _displayUrl = localPath;
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
          const SnackBar(
            content: Text('Spieler-Bild erfolgreich gespeichert!'),
          ),
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
