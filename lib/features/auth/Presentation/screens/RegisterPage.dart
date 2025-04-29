import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<Registerpage> createState() => _RegisterpageState();
 
}

class _RegisterpageState extends State<Registerpage> {
  // Text Controllers
  
  final NameController = TextEditingController();
  final EmailController = TextEditingController();
  final PwController = TextEditingController();
  final ConfirmPwController = TextEditingController();


void register(){
    final String Name = NameController.text;
    final String Email = EmailController.text;
    final String Pw = PwController.text;
    final String ConfirmPw = ConfirmPwController.text;

    // auth cubit 
    // get
    final authcubit = context.read<AuthCubit>(); 
    
    // ensure that the email and password are not empty
    // and the password and confirm password are the same
    if (Pw != ConfirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password and Confirm Password do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (Name.isNotEmpty && Email.isNotEmpty && Pw.isNotEmpty && ConfirmPw.isNotEmpty) {
      // call the login function from the auth cubit
      // this function will handle the login process
      authcubit.register(
        NAME: Name,
        EMAIL: Email , 
        PASSWORD: Pw,
        CONFIRMPASSWORD: ConfirmPw,
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
 }
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
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 70,
                    color: Colors.grey, // dark blue
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create an account :)',
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
                  controller: NameController,
                  hintText: "Name",
                  obsecureText: false,
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
                MyTextField(
                  controller: ConfirmPwController,
                  hintText: "Confirm Password",
                  obsecureText: true,
                ),
                const SizedBox(height: 20),
                MyButton(
                  onTap: () {
                    // Register logic here
                     register();
                     
                  },
                  text: "Register",
         // deep black text
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account ! ',
                      style: TextStyle(
                        color: Colors.grey, // dark blue
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.togglePages,
                      child: Text(
                        'Login now',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 0, 0, 0), // dark blue
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
