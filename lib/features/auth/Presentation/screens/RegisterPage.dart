import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key,required this.togglePages});
  final void Function()? togglePages;

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  // Text Controller
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();

  @override
  // build UI = USER INTERFACE
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Icon(
                Icons.lock_open_rounded,
                size: 70,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Create an account :)',
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
            SizedBox(height: 20),

            MyTextField(
                controller: nameController,
                hintText: "Name",
                obsecureText: false
                ),

            SizedBox(height: 20),

            MyTextField(
                controller: emailController,
                hintText: "Email",
                obsecureText: false
                ),

            SizedBox(height: 20),

            // password textfield
            MyTextField(
                controller: pwController,
                hintText: "Password",
                obsecureText: true,
                ),

            SizedBox(height: 20),

            MyTextField(
                controller: confirmPwController,
                hintText: "Confirm Password",
                obsecureText: true,
                ),

            SizedBox(height: 20),

            //Register button 
            MyButton(onTap: () {},
             text: "Register" ,),

          // A member login now 
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account ', 
                style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),),
              GestureDetector(
                onTap: widget.togglePages,
                child: Text('Login now ',
                 style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),),
              ),
            ],
          )
          ],
        ),
      ),
    ));
  }
}