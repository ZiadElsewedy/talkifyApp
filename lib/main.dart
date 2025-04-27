import 'package:flutter/material.dart';
import 'package:talkifyapp/screens/HomePage.dart';

void main() {
  runApp(const TalkifyAp());
}

class TalkifyAp extends StatelessWidget {
  const TalkifyAp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: true,
      home: Homepage()
      
    );
  }
}
