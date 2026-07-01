import 'package:beltei_app/app.dart';
import 'package:beltei_app/db/app_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    await AppDatabase.instance.database;
  }
  await bootstrapApp();
  runApp(const LoseFoundApp());
}
