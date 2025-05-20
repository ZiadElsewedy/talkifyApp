import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/PassReq.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/RegisterLogic.dart';
import 'package:lottie/lottie.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> with SingleTickerProviderStateMixin {
  final NameController = TextEditingController();
  final EmailController = TextEditingController();
  final PwController = TextEditingController();
  final ConfirmPwController = TextEditingController();
  final PHONENUMBERController = TextEditingController();
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController?.repeat();
  }

  void register() {
    RegisterLogic.register(
      context: context,
      name: NameController.text,
      email: EmailController.text,
      password: PwController.text,
      confirmPassword: ConfirmPwController.text,
      phoneNumber: PHONENUMBERController.text,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
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
                      child: Container(
                        height: 170,
                        child: _animationController != null
                            ? Lottie.asset(
                                'lib/assets/Register.json',
                                controller: _animationController,
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                                onLoaded: (composition) {
                                  _animationController?.duration = composition.duration;
                                },
                              )
                            : const SizedBox(),
                      ),
                    ),
                    
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
                      helperText: "Tap the info icon to see password requirements",
                      suffixIcon: GestureDetector(
                        onTap: () => PasswordRequirementsDialog.show(context),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
