import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/Posts/presentation/HomePage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/background_effects.dart';
import 'package:lottie/lottie.dart';

class VerificationEmail extends StatefulWidget {
  const VerificationEmail({super.key});

  @override
  State<VerificationEmail> createState() => _VerificationEmailState();
}

class _VerificationEmailState extends State<VerificationEmail> with TickerProviderStateMixin {
  StreamSubscription? _authSubscription;
  AnimationController? _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeBackgroundAnimation();
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

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animationController?.repeat();
  }

  void _initializeBackgroundAnimation() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animationController?.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Email Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthStates>(
        builder: (context, state) {
          return Stack(
            children: [
              // Animated background
              AnimatedBackgroundGradient(animation: _backgroundAnimation),
              
              // Animated floating particles
              FloatingParticles(animation: _backgroundAnimation),
              
              // Large floating orbs with complex animation
              FloatingOrbs(animation: _backgroundAnimation),
              
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Email Animation with Container
                        Container(
                          padding: EdgeInsets.all(15),
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _animationController != null
                              ? Lottie.asset(
                                  'lib/assets/Verfiy.json',
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
                        const SizedBox(height: 40),
                        
                        // Title
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Description
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (state is EmailVerificationState)
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[300],
                                    height: 1.5,
                                  ),
                                )
                              else if (state is UnverifiedState)
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[300],
                                    height: 1.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Check Verification Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state is AuthLoadingState 
                              ? null 
                              : () {
                                  if (!mounted) return;
                                  context.read<AuthCubit>().checkEmailVerification();
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Check Verification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
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
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[300],
                          ),
                          child: Text(
                            'Resend Verification Email',
                            style: TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Loading Indicator
                        if (state is AuthLoadingState)
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 