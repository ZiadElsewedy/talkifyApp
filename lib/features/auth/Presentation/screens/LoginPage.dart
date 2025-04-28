import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';
//import 'package:talkifyapp/theme/LightMode.dart';

class LoginPage extends StatefulWidget {
   const LoginPage({super.key, required this.togglePages});
   final void Function()? togglePages;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
// Text Controller
  final emailController = TextEditingController();
  final pwController = TextEditingController();

 // login button pressed
 void login(){
  // prepare amail & pw
  final String Email = emailController.text;
  final String Pw = pwController.text;

  // Auth cubit 
  //final authCubit = context.read<AuthCubit>();
 }

  // ensure that email & pw are not empty
 
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
            SizedBox(height: 20),
            // email textfield
            MyTextField(
                controller: emailController,
                hintText: "Email",
                obsecureText: false
                ),

            SizedBox(height: 20),

            // email textfield
            MyTextField(
                controller: pwController,
                hintText: "Password",
                obsecureText: true,
                ),

            SizedBox(height: 20),

            //login button 
            MyButton(onTap: login,
             text: "Login" ,),

          // not a member register now 
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Not a member? ', 
                style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),),
              GestureDetector(
                onTap: widget.togglePages,
                child: Text('register now ',
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