import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/items_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/bookings_provider.dart';
import 'providers/messages_provider.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

// App entry point and Firebase setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// Root widget that wires providers and navigation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Builds the top-level app widget tree.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, auth, favorites) =>
              favorites!..setUser(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BookingsProvider>(
          create: (_) => BookingsProvider(),
          update: (_, auth, bookings) => bookings!..setUser(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MessagesProvider>(
          create: (_) => MessagesProvider(),
          update: (_, auth, messages) => messages!..setUser(auth.currentUser),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'JiranLink',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authProvider.isInitializing
                ? const _Splash()
                : (authProvider.isAuthenticated
                    ? const MainNavigation()
                    : const WelcomeScreen()),
          );
        },
      ),
    );
  }
}

// Simple loading screen while startup completes.
class _Splash extends StatelessWidget {
  const _Splash();

  // Shows a centered progress indicator.
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
