import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCZUG5NtGOH42p2Rzp5rjjyEGuBf9eFfPk',
    appId: '1:241009867413:web:6e9c6e1936a3359234399c',
    messagingSenderId: '241009867413',
    projectId: 'family-shield-app',
    authDomain: 'family-shield-app.firebaseapp.com',
    storageBucket: 'family-shield-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5fIZg94evN3HG5YHhKYytUgW-0L2-k54',
    appId: '1:241009867413:android:da637fdcb085f08f34399c',
    messagingSenderId: '241009867413',
    projectId: 'family-shield-app',
    storageBucket: 'family-shield-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlcCErDkivmpEdcvQMIjoZK3uPTUdaWEQ',
    appId: '1:241009867413:ios:743864f0649d195b34399c',
    messagingSenderId: '241009867413',
    projectId: 'family-shield-app',
    storageBucket: 'family-shield-app.firebasestorage.app',
    iosBundleId: 'com.familyshield.familyShield',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAlcCErDkivmpEdcvQMIjoZK3uPTUdaWEQ',
    appId: '1:241009867413:ios:743864f0649d195b34399c',
    messagingSenderId: '241009867413',
    projectId: 'family-shield-app',
    storageBucket: 'family-shield-app.firebasestorage.app',
    iosBundleId: 'com.familyshield.familyShield',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCZUG5NtGOH42p2Rzp5rjjyEGuBf9eFfPk',
    appId: '1:241009867413:web:2843b11a1cd05e5a34399c',
    messagingSenderId: '241009867413',
    projectId: 'family-shield-app',
    authDomain: 'family-shield-app.firebaseapp.com',
    storageBucket: 'family-shield-app.firebasestorage.app',
  );
}
