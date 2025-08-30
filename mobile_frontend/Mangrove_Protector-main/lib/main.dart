import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/illegal_activity_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/providers/connectivity_provider.dart';
import 'package:mangrove_protector/screens/splash_screen.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize services here
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TreeProvider()),
        ChangeNotifierProvider(create: (_) => IllegalActivityProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) => MaterialApp(
          title: 'Mangrove Protector',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('es', ''), // Spanish
            Locale('fr', ''), // French
            Locale('id', ''), // Indonesian
            // Add more languages as needed
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

