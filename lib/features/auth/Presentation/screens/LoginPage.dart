import 'package:flutter/material.dart';
import 'package:talkifyapp/theme/LightMode.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});
// login page 
// AND FOR MAKE A NEW ACCOUNT
  @override
  // build UI = USER INTERFACE
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Icon(Icons.lock_open_rounded, size : 90 )
        ],
      )


      
    );
  }
}