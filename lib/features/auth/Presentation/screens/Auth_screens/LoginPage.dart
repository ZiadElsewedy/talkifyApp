import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/ForgotPasswordPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/MyTextField.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mybutton.dart';
import 'package:lottie/lottie.dart';

// step 5 : create the login page
// the login page will be the page that the user will use to login to the app
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // Text Controller
  // to manage the text input for email and password fields
  // these controllers will be used to get the text input from the user
  final EmailController = TextEditingController();
  final PwController = TextEditingController();
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

  @override
  void dispose() {
    _animationController?.dispose();
    EmailController.dispose();
    PwController.dispose();
    super.dispose();
  }

  // login button pressed
  void login() {
    final String Email = EmailController.text;
    final String Pw = PwController.text;
    
    if (Email.isEmpty || Pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthCubit>().login(
      EMAIL: Email,
      PASSWORD: Pw,
    );
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
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is UnverifiedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;
          
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Container(
                        height: 170,
                        child: _animationController != null
                            ? Lottie.asset(
                                'lib/assets/logo_animation.json',
                                controller: _animationController,
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                                onLoaded: (composition) {
                                  _animationController?.duration = composition.duration;
                                },
                              )
                            : const SizedBox(), // Show empty container while animation is loading
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome back ! to our community :)',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: EmailController,
                      hintText: "Email",
                      obsecureText: false,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: PwController,
                      hintText: "Password",
                      obsecureText: true,
                      enabled: !isLoading,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                            );
                          },
                          child: Text(
                            'Forgot Password ?',
                            style: TextStyle(
                              color: isLoading ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MyButton(
                      onTap: isLoading ? null : login,
                      text: isLoading ? "Logging in..." : "Login",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Not a member ? ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : widget.togglePages,
                          child: Text(
                            'Register now',
                            style: TextStyle(
                              fontSize: 18,
                              color: isLoading ? Colors.grey : Color.fromARGB(255, 0, 0, 0),
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
