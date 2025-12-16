import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCiuHu1FsEeFUOsX3ygkN2rdjrS7maVTFQ',
    appId: '1:728552713392:web:1b02282ec4da62ed6edf75',
    messagingSenderId: '728552713392',
    projectId: 'torkh-app',
    authDomain: 'torkh-app.firebaseapp.com',
    databaseURL: 'https://torkh-app-default-rtdb.firebaseio.com',
    storageBucket: 'torkh-app.firebasestorage.app',
    measurementId: 'G-JG49RF03WP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALacUYRMsvfELIcy7iHFMOt3hiXA_dTSQ',
    appId: '1:728552713392:android:06047b5c5c71c09c6edf75',
    messagingSenderId: '728552713392',
    projectId: 'torkh-app',
    databaseURL: 'https://torkh-app-default-rtdb.firebaseio.com',
    storageBucket: 'torkh-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCT-poOBy_bIKeGGNf9StMTfQsFlA4XsB8',
    appId: '1:728552713392:ios:612017aabb32e1af6edf75',
    messagingSenderId: '728552713392',
    projectId: 'torkh-app',
    databaseURL: 'https://torkh-app-default-rtdb.firebaseio.com',
    storageBucket: 'torkh-app.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCT-poOBy_bIKeGGNf9StMTfQsFlA4XsB8',
    appId: '1:728552713392:ios:612017aabb32e1af6edf75',
    messagingSenderId: '728552713392',
    projectId: 'torkh-app',
    databaseURL: 'https://torkh-app-default-rtdb.firebaseio.com',
    storageBucket: 'torkh-app.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCiuHu1FsEeFUOsX3ygkN2rdjrS7maVTFQ',
    appId: '1:728552713392:web:524b8c5bee0aabde6edf75',
    messagingSenderId: '728552713392',
    projectId: 'torkh-app',
    authDomain: 'torkh-app.firebaseapp.com',
    databaseURL: 'https://torkh-app-default-rtdb.firebaseio.com',
    storageBucket: 'torkh-app.firebasestorage.app',
    measurementId: 'G-081CRDYWCH',
  );

}