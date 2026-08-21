import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_gate.dart';
import 'services/push_notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // With google-services.json present, Android sometimes auto-initializes
  // the default Firebase app natively before this explicit call runs. When
  // that happens, initializeApp() throws "duplicate-app" -- which is fine,
  // it just means Firebase is already ready, so we catch and ignore only
  // that specific case (anything else still surfaces as a real error).
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  await PushNotificationService.initialize();

  runApp(const GasCylinderApp());
}

class GasCylinderApp extends StatelessWidget {
  const GasCylinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Gas Cylinder Orders',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthGate(),
      ),
    );
  }
}
