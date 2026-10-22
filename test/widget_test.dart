import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_tv_app/data/sample_data.dart';
import 'package:smart_tv_app/main.dart';
import 'package:smart_tv_app/screens/home_screen.dart';
import 'package:smart_tv_app/screens/login_screen.dart';
import 'package:smart_tv_app/services/auth_provider.dart';
import 'package:smart_tv_app/services/catalog_provider.dart';
import 'package:smart_tv_app/services/favorites_provider.dart';
import 'package:smart_tv_app/services/locale_provider.dart';

void main() {
  testWidgets('Login screen and TV Demo / Guest Mode navigation work with D-Pad', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});

    final localeProvider = LocaleProvider();
    await localeProvider.init();

    final favoritesProvider = FavoritesProvider();
    await favoritesProvider.init(initialProgress: initialWatchProgress);

    final authProvider = AuthProvider();
    final catalogProvider = CatalogProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: favoritesProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: catalogProvider),
        ],
        child: const SmartTvApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byIcon(Icons.tv_rounded), findsOneWidget);

    // Activate Guest Mode and verify HomeScreen renders and handles D-Pad keys
    authProvider.signInAsGuest();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeScreen), findsOneWidget);

    // Send D-Pad Down and Select key events
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
