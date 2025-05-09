import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:talkifyapp/App.dart';
import 'package:talkifyapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // fire base setup 
  // Initialize any necessary services or plugins here
  // For example, if you're using Firebase, you might want to initialize it:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    // This is where you can set up Firebase options for different platforms
  );
  runApp( MyApp());
}

