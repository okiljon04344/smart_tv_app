import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'services/locale_provider.dart';
import 'services/favorites_provider.dart';
import 'services/auth_provider.dart';
import 'services/catalog_provider.dart';
import 'data/sample_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Android TV remote sends KeyUpEvent for Select/OK without a prior KeyDownEvent.
  // This causes Flutter assertion errors and breaks all key handling.
  // We suppress this specific error so navigation continues working.
  final void Function(FlutterErrorDetails)? originalOnError =
      FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('KeyUpEvent is dispatched') ||
        msg.contains('_pressedKeys.containsKey')) {
      return; // silently ignore TV remote key sync errors
    }
    originalOnError?.call(details);
  };

  // Keep key events unconsumed globally so focused widgets can handle Select/OK.

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  final favoritesProvider = FavoritesProvider();
  await favoritesProvider.init(initialProgress: initialWatchProgress);

  final authProvider = AuthProvider();
  await authProvider.init();

  final catalogProvider = CatalogProvider();
  await catalogProvider.init();

  runApp(
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
}

class SmartTvApp extends StatelessWidget {
  const SmartTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        focusColor: const Color(0xFF6C63FF),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isBusy && !auth.isSignedIn) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }
    return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
