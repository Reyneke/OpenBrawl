import 'package:flutter/material.dart';
import 'package:open_brawl/main_app.dart';
import 'package:open_brawl/provider/provider_market.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProviderTeam>(create: (_) => ProviderTeam()),
        ChangeNotifierProvider<ProviderMarket>(create: (_) => ProviderMarket()),
        //Provider<SomethingElse>(create: (_) => SomethingElse()),
        //Provider<AnotherThing>(create: (_) => AnotherThing()),
      ],
      child: MainApp(),
    ),
  );
}
