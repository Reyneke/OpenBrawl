import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_brawl/main_app.dart';
import 'package:open_brawl/provider/provider_market.dart';
import 'package:open_brawl/provider/provider_server.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env/.env");
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to load .env file: $e');
  }

  final providerServer = ProviderServer();
  await providerServer.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProviderServer>(create: (_) => providerServer),
        ChangeNotifierProvider<ProviderTeam>(
          create: (_) => ProviderTeam(providerServer),
        ),
        ChangeNotifierProvider<ProviderMarket>(create: (_) => ProviderMarket()),
      ],
      child: MainApp(),
    ),
  );
}
