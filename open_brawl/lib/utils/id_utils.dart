import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Stabile, sitzungsunabhängige Int-IDs für persistierte Spielobjekte.
///
/// Motiviert durch `doc/plan/1_grundzuege/3_Object_Player.md`: Der frühere
/// Einsatz von `String.hashCode` (bzw. `Digest.hashCode`) ist fehlerhaft,
/// weil solche Hashcodes pro Isolate/Sitzung(randomisiert) sind und damit
/// nicht über Sessions/Supabase hinweg stabil bleiben.
abstract final class IdUtils {
  /// Deterministische 32-bit-ID aus den ersten 4 Bytes des SHA-256-Digests.
  /// Für "stabile" Werte, z. B. einen UUID-String → teamId beim Laden.
  static int stableIdFromString(String input) {
    final digest = sha256.convert(utf8.encode(input)).bytes;
    var value = 0;
    for (final byte in digest.take(4)) {
      value = (value << 8) | byte;
    }
    return value.toSigned(32);
  }

  /// Praktisch eindeutige ID für neu erzeugte Entitäten.
  ///
  /// Kombiniert einen stabilen Startwert (Seed) mit Mikrosekunden-Zeitstempel
  /// und Zufall. So kollidieren gleichnamige Spieler (Fälle wie "Zwei
  /// Lizenzname → gleiche ID") nicht mehr. Für absolute Eindeutigkeit über
  /// alle Clients hinweg empfiehlt sich langfristig eine UUID (offener Punkt).
  static int uniqueId(String seed, {Random? random}) {
    final rng = random ?? Random();
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return stableIdFromString(
      '$seed|$microseconds|${rng.nextInt(1 << 30)}',
    );
  }
}