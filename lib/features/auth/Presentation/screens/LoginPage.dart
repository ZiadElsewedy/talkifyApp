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

      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Icon(
                Icons.lock_open_rounded,
                 size : 70 ,
                  color: Theme.of(context).colorScheme.primary,
                  ),
            
            ),
             SizedBox(height: 20),
            Text(
              'Welcome to Talkify !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      )


      
    );
  }
}