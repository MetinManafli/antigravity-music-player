import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:antigravity_music/main.dart';
import 'package:antigravity_music/viewmodels/player_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall call) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall call) async => 1,
    );
  });

  testWidgets('Music Player App loads and renders all 6 navigation tabs without overflow at 1280x800', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Set desktop screen size for testing (1280x800 to also verify no bottom bar or layout overflow)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlayerViewModel()),
        ],
        child: const AntigravityMusicApp(),
      ),
    );

    // Pump frames to initialize providers
    await tester.pump(const Duration(milliseconds: 100));

    // Verify main components & all 6 sidebar navigation items exist
    expect(find.text('Antigravity'), findsOneWidget);
    expect(find.text('Kütüphanem'), findsWidgets);
    expect(find.text('YouTube İndirici'), findsWidgets);
    expect(find.text('Favoriler'), findsWidgets);
    expect(find.text('Çalma Listeleri'), findsWidgets);
    expect(find.text('Son Çalınanlar'), findsWidgets);
    expect(find.text('Ayarlar'), findsWidgets);
    expect(find.byIcon(Icons.queue_music_rounded), findsWidgets);

    // Verify removed Discover/Radio tabs do not exist
    expect(find.text('Keşfet & Radyo'), findsNothing);
    expect(find.text('Çevrim İçi Keşfet'), findsNothing);

    // Tap through all 6 sidebar navigation items and verify no RenderFlex overflow occurs
    final navTabs = [
      'YouTube İndirici',
      'Favoriler',
      'Çalma Listeleri',
      'Son Çalınanlar',
      'Ayarlar',
      'Kütüphanem',
    ];

    for (final tabLabel in navTabs) {
      await tester.tap(find.text(tabLabel).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'Tab "$tabLabel" caused an exception or overflow');
    }

    // Navigate back to Ayarlar (index 5) and verify SettingsView header & Equalizer section render
    await tester.tap(find.text('Ayarlar').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ayarlar & Stüdyo Ekolayzer'), findsOneWidget);
    expect(find.text('Bass Boost'), findsOneWidget);
  });
}
