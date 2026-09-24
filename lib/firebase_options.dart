// File generated for Firebase project assessment-system-c20d7
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
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAssessmentSystemAppKeyConfigured',
    appId: '1:103587829121593092193:web:assessmentSystem',
    messagingSenderId: '103587829121593092193',
    projectId: 'assessment-system-c20d7',
    authDomain: 'assessment-system-c20d7.firebaseapp.com',
    storageBucket: 'assessment-system-c20d7.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAssessmentSystemAppKeyConfigured',
    appId: '1:103587829121593092193:android:assessmentSystem',
    messagingSenderId: '103587829121593092193',
    projectId: 'assessment-system-c20d7',
    storageBucket: 'assessment-system-c20d7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAssessmentSystemAppKeyConfigured',
    appId: '1:103587829121593092193:ios:assessmentSystem',
    messagingSenderId: '103587829121593092193',
    projectId: 'assessment-system-c20d7',
    storageBucket: 'assessment-system-c20d7.appspot.com',
    iosBundleId: 'com.mca.aptitude.mcaAptitudeApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAssessmentSystemAppKeyConfigured',
    appId: '1:103587829121593092193:ios:assessmentSystem',
    messagingSenderId: '103587829121593092193',
    projectId: 'assessment-system-c20d7',
    storageBucket: 'assessment-system-c20d7.appspot.com',
    iosBundleId: 'com.mca.aptitude.mcaAptitudeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAssessmentSystemAppKeyConfigured',
    appId: '1:103587829121593092193:web:assessmentSystem',
    messagingSenderId: '103587829121593092193',
    projectId: 'assessment-system-c20d7',
    authDomain: 'assessment-system-c20d7.firebaseapp.com',
    storageBucket: 'assessment-system-c20d7.appspot.com',
  );
}
