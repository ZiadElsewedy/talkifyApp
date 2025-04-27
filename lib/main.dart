import 'package:flutter/material.dart';
import 'package:talkifyapp/screens/HomePage.dart';

void main() {
  runApp(const TalkifyApp());
}

class TalkifyApp extends StatelessWidget {
  const TalkifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: true,
      home: Homepage()
      
    );
  }
}
