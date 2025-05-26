import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:talkifyapp/App.dart';
import 'package:talkifyapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // fire base setup 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

