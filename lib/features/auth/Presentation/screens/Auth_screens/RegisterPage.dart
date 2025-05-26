import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/AuthStates.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/text_fields.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/buttons.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/background_effects.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/PassReq.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/RegisterLogic.dart';
import 'package:lottie/lottie.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> with TickerProviderStateMixin {
  // Text controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPwController = TextEditingController();
  final phoneNumberController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  
  // Focus nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _phoneNumberFocus = FocusNode();
  
  // Form key
  final _registerFormKey = GlobalKey<FormState>();
  
  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _nameFocus.addListener(() {
      setState(() {});
      // Scroll to the focused field if needed
      _scrollToFocusedField(_nameFocus);
    });
    _emailFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_emailFocus);
    });
    _passwordFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_passwordFocus);
    });
    _confirmPasswordFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_confirmPasswordFocus);
    });
    _phoneNumberFocus.addListener(() {
      setState(() {});
      _scrollToFocusedField(_phoneNumberFocus);
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
    
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPwController.dispose();
    phoneNumberController.dispose();
    
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _phoneNumberFocus.dispose();
    
    super.dispose();
  }

  void register() {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }
    
    RegisterLogic.register(
      context: context,
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      confirmPassword: confirmPwController.text,
      phoneNumber: phoneNumberController.text,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
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
                                  // Header
                                  _buildHeader(),
                                  
                                  // Form
                                  _buildRegisterForm(isLoading),
                                  
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _backgroundAnimation.value * 0.1,
                child: Container(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'lib/assets/Logo5.json',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join our community',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedTextField(
            controller: nameController,
            focusNode: _nameFocus,
            hint: 'Full Name',
            icon: Icons.person_outline,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          AnimatedTextField(
            controller: emailController,
            focusNode: _emailFocus,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          AnimatedTextField(
            controller: phoneNumberController,
            focusNode: _phoneNumberFocus,
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isLoading ? null : () => PasswordRequirementsDialog.show(context),
              child: Text(
                'Password Requirements',
                style: TextStyle(
                  color: isLoading ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          AnimatedTextField(
            controller: confirmPwController,
            focusNode: _confirmPasswordFocus,
            hint: 'Confirm Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 16),
          ActionButton(
            text: 'Create Account',
            isLoading: isLoading,
            onPressed: isLoading ? null : register,
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
          "Already have an account? ",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        GestureDetector(
          onTap: isLoading ? null : widget.togglePages,
          child: Text(
            'Sign In',
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
