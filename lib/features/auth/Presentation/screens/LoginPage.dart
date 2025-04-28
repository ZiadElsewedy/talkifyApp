import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text Controller
  final EmailController = TextEditingController();
  final PwController = TextEditingController();

  // login button pressed
  void login() {
    final String Email = EmailController.text;
    final String Pw = PwController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1EFEC), // light background
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
                  color: Color(0xFF123458), // dark blue
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to Talkify!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF030303), // deep black text
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
              const SizedBox(height: 20),
              MyTextField(
                controller: EmailController,
                hintText: "Email",
                obsecureText: false,
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: PwController,
                hintText: "Password",
                obsecureText: true,
              ),
              const SizedBox(height: 20),
              MyButton(
                onTap: (){
                    
                },
                text: "Login",
                // deep black text
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member? ',
                    style: TextStyle(
                      color: Color(0xFF123458), // dark blue
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.togglePages,
                    child: Text(
                      'Register now',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF123458), // dark blue
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
