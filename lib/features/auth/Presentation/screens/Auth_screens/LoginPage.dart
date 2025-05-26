import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Auth_screens/ForgotPasswordPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/text_fields.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/buttons.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/background_effects.dart';
import 'package:lottie/lottie.dart';

// step 5 : create the login page
// the login page will be the page that the user will use to login to the app
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Text Controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  
  // Focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  // Form key
  final _loginFormKey = GlobalKey<FormState>();
  
  // Password visibility
  bool _obscurePassword = true;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFocusListeners();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);

    _animationController.forward();
    _slideController.forward();
  }

  void _setupFocusListeners() {
    _emailFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_emailFocus);
    });
    _passwordFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_passwordFocus);
    });
  }

  void _scrollToFocusedField(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _scrollController.dispose();
    
    emailController.dispose();
    passwordController.dispose();
    
    _emailFocus.dispose();
    _passwordFocus.dispose();
    
    super.dispose();
  }

  // login button pressed
  void login() {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }
    
    final String email = emailController.text;
    final String password = passwordController.text;
    
    context.read<AuthCubit>().login(
      EMAIL: email,
      PASSWORD: password,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
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
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo/Title
                                _buildHeader(),
                                
                                // Form
                                _buildLoginForm(isLoading),

                                const SizedBox(height: 16),

                                // Toggle button
                                _buildToggleButton(isLoading),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _backgroundAnimation.value * 0.1,
                child: Container(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'lib/assets/Logo5.json',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome Back',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to continue',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        children: [
          AnimatedTextField(
            controller: emailController,
            focusNode: _emailFocus,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          AnimatedTextField(
            controller: passwordController,
            focusNode: _passwordFocus,
            hint: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: isLoading ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ActionButton(
            text: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : login,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        GestureDetector(
          onTap: isLoading ? null : widget.togglePages,
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: isLoading ? Colors.grey[600] : Colors.white,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
