import 'package:flutter/material.dart';
import 'package:open_brawl/main_app.dart';
import 'package:open_brawl/provider/provider_team.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ProviderTeam>(create: (_) => ProviderTeam()),
        //Provider<SomethingElse>(create: (_) => SomethingElse()),
        //Provider<AnotherThing>(create: (_) => AnotherThing()),
      ],
      child: MainApp(),
    ),
  );
}
