import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/AuthPage.dart';
import 'package:talkifyapp/firebase_options.dart';
import 'package:talkifyapp/theme/LightMode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // fire base setup 
  // Initialize any necessary services or plugins here
  // For example, if you're using Firebase, you might want to initialize it:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    // This is where you can set up Firebase options for different platforms
  );
  runApp(const TalkifyApp());
}

class TalkifyApp extends StatelessWidget {
  const TalkifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightmode ,
      home: const AuthPage()
      
    );
  }
}
