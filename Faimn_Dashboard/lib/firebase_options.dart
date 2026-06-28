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
    apiKey:            "AIzaSyAhESyck8FiL3pN63AaNEOe_zO00NQXij0",
    appId:             "1:97421584129:web:dfbe7d26867071dbb8dd00",
    messagingSenderId: "1087218451143",
    projectId:         "faimn3-c39c8",
    databaseURL:       "https://faimn3-c39c8-default-rtdb.firebaseio.com/",
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            "AIzaSyAhESyck8FiL3pN63AaNEOe_zO00NQXij0",
    appId:             "1:97421584129:android:dfbe7d26867071dbb8dd00",
    messagingSenderId: "1087218451143",
    projectId:         "faimn3-c39c8",
    databaseURL:       "https://faimn3-c39c8-default-rtdb.firebaseio.com/",
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            "AIzaSyAhESyck8FiL3pN63AaNEOe_zO00NQXij0",
    appId:             "1:97421584129:ios:dfbe7d26867071dbb8dd00",
    messagingSenderId: "1087218451143",
    projectId:         "faimn3-c39c8",
    databaseURL:       "https://faimn3-c39c8-default-rtdb.firebaseio.com/",
  );
}
