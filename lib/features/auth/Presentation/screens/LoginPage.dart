import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
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
  // to manage the text input for email and password fields
  // these controllers will be used to get the text input from the user
  final EmailController = TextEditingController();
  final PwController = TextEditingController();

  // login button pressed
  void login() {
    final String Email = EmailController.text;
    final String Pw = PwController.text;
    // auth cubit 
    // get
    final authcubit = context.read<AuthCubit>(); 
    // ensure that the email and password are not empty 
    if (Email.isNotEmpty && Pw.isNotEmpty) {
      // call the login function from the auth cubit
      // this function will handle the login process
      authcubit.login(
        EMAIL: Email , 
        PASSWORD: Pw,
       
      );
        
      return;
    } else {
      // show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
    
  }

  void dispose() {
    super.dispose();
    EmailController.dispose();
    PwController.dispose();
  }}
  

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
                child: Image.asset(
                  'lib/assets/Logo3.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Talkify!',
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
              Text(
                'Welcome back ! to our community :)',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey, // light grey text
                ),
              ),const SizedBox(height: 20),
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
                  login();
                },
                text: "Login",
                // deep black text
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member ? ',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold // dark blue
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.togglePages,
                    child: Text(
                      'Register now',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0), // dark blue
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
