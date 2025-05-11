import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/ForgotPasswordPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';
// step 5 : create the login page
// the login page will be the page that the user will use to login to the app
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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100,),
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Image.asset(
                      'lib/assets/Logo1.png',
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
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
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordPage()));
                      },
                      child: Text(
                        'Forgot Password ?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
      ),
    );
  }
}
