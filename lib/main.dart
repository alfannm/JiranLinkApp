import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/items_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/bookings_provider.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/welcome/auth_screen.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For "real auth" (FirebaseAuth) you MUST initialize Firebase.
  // If you haven't added Firebase config files yet, the app will fail at runtime.
  // See the setup steps at the end of this message.
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => BookingsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'JiranLink',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authProvider.isInitializing
                ? const _Splash()
                : (!authProvider.hasCompletedOnboarding
                    ? const WelcomeScreen()
                    : (authProvider.isAuthenticated
                        ? const MainNavigation()
                        : const AuthScreen())),
          );
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
