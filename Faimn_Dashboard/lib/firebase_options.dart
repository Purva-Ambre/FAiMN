// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:                     return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            "API_KEY",
    appId:             "YOUR_API_ID",
    messagingSenderId: "SENDER_ID",
    projectId:         "FIREBASE_PROJECT_ID",
    databaseURL:       "FIREBASE_URL",
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            "API_KEY",
    appId:             "YOUR_API_ID",
    messagingSenderId: "SENDER_ID",
    projectId:         "FIREBASE_PROJECT_ID",
    databaseURL:       "FIREBASE_URL",
  );
  static const FirebaseOptions ios = FirebaseOptions(
     apiKey:            "API_KEY",
    appId:             "YOUR_API_ID",
    messagingSenderId: "SENDER_ID",
    projectId:         "FIREBASE_PROJECT_ID",
    databaseURL:       "FIREBASE_URL",
  );
}
