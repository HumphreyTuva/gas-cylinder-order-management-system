// File generated normally by the FlutterFire CLI. This is a PLACEHOLDER.
//
// To generate the real version for your Firebase project:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
// This will overwrite this file with your actual project's API keys/IDs
// and register your Android/iOS apps with Firebase automatically.
//
// Do NOT ship this placeholder to production -- Firebase Messaging will not
// work until this file contains your real project configuration.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. Run `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. Run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    appId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    projectId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    storageBucket: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    appId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    projectId: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    storageBucket: 'REPLACE_WITH_flutterfire_configure_OUTPUT',
    iosBundleId: 'com.example.gasCylinderApp',
  );
}
