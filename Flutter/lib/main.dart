import 'package:beltei_app/app.dart';
import 'package:beltei_app/db/app_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    const webClientId =
        '894329943560-6vbrnakcbto43kk61bbg8709af4bvr3e.apps.googleusercontent.com';
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: webClientId,
    );
    await AppDatabase.instance.database;
  }
  await bootstrapApp();
  runApp(const LoseFoundApp());
}
