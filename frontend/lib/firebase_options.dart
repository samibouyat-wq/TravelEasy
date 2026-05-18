import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Valeurs de développement local — remplacer par les vraies clés Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'local-dev-key',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'traveleasy-local',
    storageBucket: 'traveleasy-local.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'local-dev-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'traveleasy-local',
    storageBucket: 'traveleasy-local.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'local-dev-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'traveleasy-local',
    storageBucket: 'traveleasy-local.appspot.com',
    iosBundleId: 'com.traveleasy.app',
  );
}
