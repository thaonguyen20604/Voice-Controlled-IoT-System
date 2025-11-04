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
    apiKey: 'AIzaSyCyf-k7lhhHmGbZ5nRytDONaWHtOT8RGgI',
    appId: '1:609062162885:web:ac704f082d7d6efdbdbbac',
    messagingSenderId: '609062162885',
    projectId: 'iotdemo-81143',
    authDomain: 'iotdemo-81143.firebaseapp.com',
    storageBucket: 'iotdemo-81143.appspot.com',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAN28ojIUYHoXyDJ9_PAmuKHba8fp82fuk',
    appId: '1:609062162885:android:b5d436d453447048bdbbac',
    messagingSenderId: '609062162885',
    projectId: 'iotdemo-81143',
    storageBucket: 'iotdemo-81143.appspot.com',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD7yZsL4Q65S_6w0faaWZee-PfSxXDC9CM',
    appId: '1:609062162885:ios:d175bdcb24e91275bdbbac',
    messagingSenderId: '609062162885',
    projectId: 'iotdemo-81143',
    storageBucket: 'iotdemo-81143.appspot.com',
    iosBundleId: 'com.example.homeAutomationApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD7yZsL4Q65S_6w0faaWZee-PfSxXDC9CM',
    appId: '1:609062162885:ios:d175bdcb24e91275bdbbac',
    messagingSenderId: '609062162885',
    projectId: 'iotdemo-81143',
    storageBucket: 'iotdemo-81143.appspot.com',
    iosBundleId: 'com.example.homeAutomationApp',
  );
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCyf-k7lhhHmGbZ5nRytDONaWHtOT8RGgI',
    appId: '1:609062162885:web:b48a712cfaa50101bdbbac',
    messagingSenderId: '609062162885',
    projectId: 'iotdemo-81143',
    authDomain: 'iotdemo-81143.firebaseapp.com',
    storageBucket: 'iotdemo-81143.appspot.com',
  );
}
