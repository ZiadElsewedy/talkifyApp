import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final NameController = TextEditingController();
  final EmailController = TextEditingController();
  final PwController = TextEditingController();
  final ConfirmPwController = TextEditingController();
  final PHONENUMBERController = TextEditingController();

  void register() {
    final String Name = NameController.text;
    final String Email = EmailController.text;
    final String Pw = PwController.text;
    final String ConfirmPw = ConfirmPwController.text;
    final String PHONENUMBER = PHONENUMBERController.text;

    // Validate all fields
    if (Name.isEmpty || Email.isEmpty || Pw.isEmpty || ConfirmPw.isEmpty || PHONENUMBER.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password match
    if (Pw != ConfirmPw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password and Confirm Password do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    if (!Email.contains('@') || !Email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (Pw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for uppercase letter
    if (!Pw.contains(RegExp(r'[A-Z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain at least one uppercase letter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for lowercase letter
    if (!Pw.contains(RegExp(r'[a-z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain at least one lowercase letter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for number
    if (!Pw.contains(RegExp(r'[0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain at least one number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for special character
    if (!Pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthCubit>().register(
      PHONENUMBER: PHONENUMBER,
      NAME: Name,
      EMAIL: Email,
      PASSWORD: Pw,
      CONFIRMPASSWORD: ConfirmPw,
    );
  }

  @override
  void dispose() {
    NameController.dispose();
    EmailController.dispose();
    PwController.dispose();
    ConfirmPwController.dispose();
    PHONENUMBERController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1EFEC),
      body: BlocConsumer<AuthCubit, AuthStates>(
        listener: (context, state) {
          if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Image.asset(
                        'lib/assets/Logo1.png',
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create an account :)',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF030303),
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
                      controller: PHONENUMBERController,
                      hintText: "Phone Number",
                      obsecureText: false,
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: PwController,
                      hintText: "Password",
                      obsecureText: true,
                      helperText: "Must be at least 8 characters with uppercase, lowercase, number & special character",
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: ConfirmPwController,
                      hintText: "Confirm Password",
                      obsecureText: true,
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: state is AuthLoadingState ? null : register,
                      text: state is AuthLoadingState ? "Registering..." : "Register",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account ! ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.togglePages,
                          child: Text(
                            'Login now',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 0, 0, 0),
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
        },
      ),
    );
  }
}
