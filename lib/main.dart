import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/theme/app_theme.dart';
import 'ui/views/home_view.dart';
import 'viewmodels/player_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerViewModel()),
      ],
      child: const AntigravityMusicApp(),
    ),
  );
}

class AntigravityMusicApp extends StatelessWidget {
  const AntigravityMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity Music Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeView(),
    );
  }
}
