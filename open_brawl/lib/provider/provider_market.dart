import 'package:flutter/material.dart';
import 'package:open_brawl/objects/object_player.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:provider/provider.dart';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderMarket extends ChangeNotifier {
  final List<ObjectPlayer> _availablePlayers = [];
  List<ObjectPlayer> get availablePlayers => _availablePlayers;
  final randomNames = RandomNames(Zone.germany);

  RealtimeChannel? _marketChannel;
  bool _isLoaded = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Call this once during app startup to load initial data and subscribe to
  /// realtime changes on the `character_market` table.
  Future<void> initialize(BuildContext context) async {
    if (_isLoaded) return;

    final server = context.read<ProviderServer>();
    final client = server.client;

    try {
      // --- 1. Load existing market characters from Supabase ---
      final response = await client
          .from('character_market')
          .select('id, character, profile_picture_url')
          .order('created_at', ascending: true);

      _availablePlayers.clear();
      final seenIds = <int>{};
      for (final row in response) {
        final characterJson = row['character'] as Map<String, dynamic>?;
        if (characterJson != null) {
          final player = ObjectPlayer.fromJson(characterJson);
          // Skip duplicate character IDs
          if (!seenIds.add(player.id)) continue;
          // Update image if stored at row level
          final imageUrl = row['profile_picture_url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            player.image = imageUrl;
          }
          _availablePlayers.add(player);
        }
      }
      _isLoaded = true;
      notifyListeners();

      // --- 2. Subscribe to Realtime changes ---
      _marketChannel = client
          .channel('character_market_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            table: 'character_market',
            callback: (payload) {
              _handleRealtimeChange(payload);
            },
          )
          .subscribe();
    } catch (e) {
      _errorMessage = 'Failed to load market: $e';
      debugPrint(_errorMessage);
    }
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        final characterJson = newRecord['character'] as Map<String, dynamic>?;
        if (characterJson != null) {
          final player = ObjectPlayer.fromJson(characterJson);
          // Skip if a character with this ID already exists
          if (_availablePlayers.any((p) => p.id == player.id)) break;
          final imageUrl = newRecord['profile_picture_url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            player.image = imageUrl;
          }
          _availablePlayers.add(player);
          notifyListeners();
        }
        break;

      case PostgresChangeEvent.delete:
        final oldId = oldRecord['id'] as int?;
        if (oldId != null) {
          _availablePlayers.removeWhere((p) => p.id == oldId);
          notifyListeners();
        }
        break;

      case PostgresChangeEvent.update:
        final updatedId = newRecord['id'] as int?;
        final characterJson = newRecord['character'] as Map<String, dynamic>?;
        if (updatedId != null && characterJson != null) {
          final idx = _availablePlayers.indexWhere((p) => p.id == updatedId);
          if (idx >= 0) {
            _availablePlayers[idx] = ObjectPlayer.fromJson(characterJson);
            final imageUrl = newRecord['profile_picture_url'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _availablePlayers[idx].image = imageUrl;
            }
            notifyListeners();
          }
        }
        break;

      case PostgresChangeEvent.all:
        // 'all' subscription type; individual events are dispatched separately
        // by the Realtime engine, so this case is never reached.
        break;
    }
  }

  int getListPosition(ObjectPlayer characterItem) {
    return _availablePlayers.indexWhere(
      (character) => character.id == characterItem.id,
    );
  }

  /// Creates dummy characters and persists them to Supabase.
  /// After insertion they will arrive via the Realtime subscription.
  /// Queries the actual DB count to avoid exceeding 40 across all clients.
  Future<void> createDummyCharacters(SupabaseClient client) async {
    // First check how many characters are actually in the DB (not just local)
    final countResponse = await client
        .from('character_market')
        .select('id')
        .count(CountOption.exact);

    final currentCount = countResponse.count;
    final maxNumOfCharacters = 40 - currentCount;

    if (maxNumOfCharacters <= 0) return;

    for (int i = 0; i < maxNumOfCharacters; ++i) {
      final player = ObjectPlayer.create(
        randomNames.name(),
        "urbanbrawl_frame_leer.png",
      );
      await client.from('character_market').insert({
        'character': player.toJson(),
        'profile_picture_url': '',
      });
    }
  }

  /// Removes a character from Supabase and refills the market to maintain
  /// a minimum of 40 characters. The Realtime subscription will
  /// automatically remove it from the local list.
  Future<void> removeCharacter(
    SupabaseClient client,
    ObjectPlayer oldPlayer,
  ) async {
    // Remove from local list immediately so the length is accurate for refill
    _availablePlayers.removeWhere((p) => p.id == oldPlayer.id);
    notifyListeners();

    // Find the Supabase row by matching the character id inside the jsonb column
    await client
        .from('character_market')
        .delete()
        .filter('character->>id', 'eq', oldPlayer.id.toString());

    // Top the market back up to 40 characters.
    // createDummyCharacters checks the actual DB count first.
    await createDummyCharacters(client);
  }

  /// Adds a character to Supabase if it doesn't already exist there.
  /// The Realtime subscription will automatically add it to the local list.
  Future<void> addCharacter(
    SupabaseClient client,
    ObjectPlayer newPlayer,
  ) async {

    // Check if a character with this ID already exists in the market
    final existing = await client
        .from('character_market')
        .select('id')
        .filter('character->>id', 'eq', newPlayer.id.toString())
        .maybeSingle();

    // Only insert if no existing character with this ID was found
    if (existing == null) {
      await client.from('character_market').insert({
        'character': newPlayer.toJson(),
        'profile_picture_url': newPlayer.image,
      });
    }
  }

  /// Removes all market characters from Supabase (for cleanup / testing).
  Future<void> clearAllCharacters(SupabaseClient client) async {
    await client.from('character_market').delete().neq('id', 0);
  }

  @override
  void dispose() {
    _marketChannel?.unsubscribe();
    super.dispose();
  }
}
