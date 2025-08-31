import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/illegal_activity_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/providers/connectivity_provider.dart';
import 'package:mangrove_protector/screens/splash_screen.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/utils/localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mangrove_protector/services/encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test encryption service
  try {
    print('Testing encryption service...');
    
    // Test libsodium initialization
    print('Initializing libsodium...');
    final testResult = await EncryptionService.testEncryption();
    print('Encryption test result: $testResult');
    
    if (testResult) {
      print('SUCCESS: Encryption service is working properly');
    } else {
      print('WARNING: Encryption service test failed!');
    }
    
  } catch (e) {
    print('ERROR: Encryption service test failed: $e');
    print('This might be due to platform compatibility issues with libsodium');
  }
  
  // Initialize services here
  await Supabase.initialize(
    url: 'https://pfpleplfotblkykcddwd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmcGxlcGxmb3RibGt5a2NkZHdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1MDQ0ODEsImV4cCI6MjA3MjA4MDQ4MX0.txp_L0riPzioSCPttCF0ZwXkAFrCWdmlFauX0xi-q-8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

