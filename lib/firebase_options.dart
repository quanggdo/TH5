import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// NOTE: This is a placeholder file. For a real application, you should generate
/// this file automatically using the FlutterFire CLI:
/// `flutterfire configure`
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
    apiKey : "AIzaSyD5qzGIJX5X-gJPV7IJ8cu_xvZJBeszueY" , 
  authDomain : "th5project.firebaseapp.com" , 
  projectId : "th5project" , 
  storageBucket : "th5project.firebasestorage.app" , 
  messagingSenderId : "168549572764" , 
  appId : "1:168549572764:web:300fb6977627f6fed54d59" , 
  measurementId : "G-QJHRPTRCGC" 
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDa2_QoP4z2cSNBzR_UbsXBMM4-pUpqsbo',
    appId: '1:168549572764:android:ff48e21b5990a956d54d59',
    messagingSenderId: '168549572764',
    projectId: 'th5project',
    storageBucket: 'th5project.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
    iosBundleId: 'REPLACE_WITH_YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_MACOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_MACOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
    iosBundleId: 'REPLACE_WITH_YOUR_MACOS_BUNDLE_ID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_WINDOWS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    authDomain: 'REPLACE_WITH_YOUR_AUTH_DOMAIN',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
  );
}
