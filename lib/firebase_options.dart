// File generated by FlutterFire CLI.
// ignore_for_file: type=l
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5QWMhmB7h6UmnSW3kdeZOAMLxTZ-r_ck',
    appId: '1:413784126343:web:1eb3dc3768c77c21935922',
    messagingSenderId: '413784126343',
    projectId: 'tomasvirtualpet',
    authDomain: 'tomasvirtualpet.firebaseapp.com',
    storageBucket: 'tomasvirtualpet.firebasestorage.app',
    measurementId: 'G-JN3GBKYP93',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpbeSlqVa-S7WElGkNY2DT8SeUOOSEjQA',
    appId: '1:413784126343:android:f2fd2739e0d0e429935922',
    messagingSenderId: '413784126343',
    projectId: 'tomasvirtualpet',
    storageBucket: 'tomasvirtualpet.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAex5SK_7g4dOAulEft6BkwJQ_xpx3ACoo',
    appId: '1:413784126343:ios:e4aff2f4d7d93e84935922',
    messagingSenderId: '413784126343',
    projectId: 'tomasvirtualpet',
    storageBucket: 'tomasvirtualpet.firebasestorage.app',
    iosBundleId: 'com.example.tomasTigerpet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAex5SK_7g4dOAulEft6BkwJQ_xpx3ACoo',
    appId: '1:413784126343:ios:e4aff2f4d7d93e84935922',
    messagingSenderId: '413784126343',
    projectId: 'tomasvirtualpet',
    storageBucket: 'tomasvirtualpet.firebasestorage.app',
    iosBundleId: 'com.example.tomasTigerpet',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB5QWMhmB7h6UmnSW3kdeZOAMLxTZ-r_ck',
    appId: '1:413784126343:web:fbbcda9caa36abda935922',
    messagingSenderId: '413784126343',
    projectId: 'tomasvirtualpet',
    authDomain: 'tomasvirtualpet.firebaseapp.com',
    storageBucket: 'tomasvirtualpet.firebasestorage.app',
    measurementId: 'G-PX551CXNVL',
  );

}