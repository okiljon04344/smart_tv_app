import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_tv_app/data/sample_data.dart';
import 'package:smart_tv_app/main.dart';
import 'package:smart_tv_app/screens/login_screen.dart';
import 'package:smart_tv_app/services/auth_provider.dart';
import 'package:smart_tv_app/services/favorites_provider.dart';
import 'package:smart_tv_app/services/locale_provider.dart';

void main() {
  testWidgets('Login screen is shown first for signed out user', (
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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: favoritesProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const SmartTvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
  });
}
