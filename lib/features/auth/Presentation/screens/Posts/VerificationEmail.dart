import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/HomePage.dart';

class VerificationEmail extends StatefulWidget {
  const VerificationEmail({super.key});

  @override
  State<VerificationEmail> createState() => _VerificationEmailState();
}

class _VerificationEmailState extends State<VerificationEmail> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = context.read<AuthCubit>().stream.listen((state) {
      if (!mounted) return;
      
      if (state is Authanticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (state is AuthErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1EFEC),
      body: BlocBuilder<AuthCubit, AuthStates>(
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email Icon
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (state is EmailVerificationState)
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    )
                  else if (state is UnverifiedState)
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 32),
                  
                  // Check Verification Button
                  ElevatedButton(
                    onPressed: state is AuthLoadingState 
                      ? null 
                      : () {
                          if (!mounted) return;
                          context.read<AuthCubit>().checkEmailVerification();
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Check Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Resend Email Button
                  TextButton(
                    onPressed: state is AuthLoadingState 
                      ? null 
                      : () {
                          if (!mounted) return;
                          context.read<AuthCubit>().sendVerificationEmail();
                        },
                    child: Text(
                      'Resend Verification Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Loading Indicator
                  if (state is AuthLoadingState)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 