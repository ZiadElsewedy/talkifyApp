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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.togglePages});
  final void Function()? togglePages;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _loginFormKey = GlobalKey<FormState>();
  
  // Animation controllers
  late AnimationController _primaryAnimationController;
  late AnimationController _secondaryAnimationController;
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoRotation;
  
  // Focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  // State variables
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFocusListeners();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Primary animation for main content
    _primaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Secondary animation for staggered effects
    _secondaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Define animations with professional curves
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _primaryAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutExpo),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _secondaryAnimationController,
      curve: Curves.elasticOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundController);

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _primaryAnimationController.forward();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _secondaryAnimationController.forward();
        _logoController.forward();
      }
    });
  }

  void _setupFocusListeners() {
    _emailFocus.addListener(_handleFocusChange);
    _passwordFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
      _scrollToFocusedField();
    }
  }

  void _scrollToFocusedField() {
    if (_emailFocus.hasFocus || _passwordFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.7,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers in reverse order
    _primaryAnimationController.dispose();
    _secondaryAnimationController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    _scrollController.dispose();
    
    _emailController.dispose();
    _passwordController.dispose();
    
    _emailFocus.dispose();
    _passwordFocus.dispose();
    
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      _showValidationError();
      return;
    }
    
    // Hide keyboard before login
    FocusScope.of(context).unfocus();
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    try {
      context.read<AuthCubit>().login(
        EMAIL: email,
        PASSWORD: password,
      );
    } catch (e) {
      _showErrorSnackBar('Login failed. Please try again.');
    }
  }

  void _showValidationError() {
    _showErrorSnackBar('Please check your input and try again.');
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: BlocConsumer<AuthCubit, AuthStates>(
        listener: _handleAuthStateChanges,
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;
          
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                _buildMainContent(isLoading, isSmallScreen),
                if (isLoading) _buildLoadingOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthStates state) {
    if (state is AuthErrorState) {
      _showErrorSnackBar(state.error);
    } else if (state is UnverifiedState) {
      _showErrorSnackBar(state.message);
    } else if (state is Authanticated) {
      _showSuccessSnackBar('Welcome back!');
    }
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
        ),
        
        // Animated background effects
        AnimatedBackgroundGradient(animation: _backgroundAnimation),
        FloatingParticles(animation: _backgroundAnimation),
        FloatingOrbs(animation: _backgroundAnimation),
        
        // Subtle overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isLoading, bool isSmallScreen) {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 24,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLoginCard(isLoading, isSmallScreen),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isSmallScreen),
          SizedBox(height: isSmallScreen ? 24 : 32),
          _buildLoginForm(isLoading, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          _buildFooter(isLoading),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        // Animated logo
        AnimatedBuilder(
          animation: _logoRotation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_logoRotation.value * 0.2),
              child: Transform.rotate(
                angle: _logoRotation.value * 0.1,
                child: Container(
                  width: isSmallScreen ? 120 : 170,
                  height: isSmallScreen ? 120 : 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                  ),
                  child: Lottie.asset(
                      
                    'lib/assets/Logo5.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Welcome text
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Please sign in to your account',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading, bool isSmallScreen) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          _buildEmailField(isLoading),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Password field
          _buildPasswordField(isLoading),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Remember me and forgot password row
          _buildOptionsRow(isLoading),
          
          SizedBox(height: isSmallScreen ? 24 : 32),
          
          // Login button
          _buildLoginButton(isLoading),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isLoading) {
    return AnimatedTextField(
      controller: _emailController,
      focusNode: _emailFocus,
      hint: 'Email Address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      enabled: !isLoading,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return AnimatedTextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      hint: 'Password',
      icon: Icons.lock_outline,
      isPassword: true,
      obscureText: _obscurePassword,
      enabled: !isLoading,
      textInputAction: TextInputAction.done,
      onToggleVisibility: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      onFieldSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildOptionsRow(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _rememberMe,
                onChanged: isLoading ? null : (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: Colors.white,
                checkColor: Colors.black,
                side: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Remember me',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Forgot password button
        TextButton(
          onPressed: isLoading ? null : () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ForgotPasswordPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: isLoading ? Colors.grey[600] : Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return ActionButton(
      text: 'Sign In',
      isLoading: isLoading,
      onPressed: isLoading ? null : _handleLogin,
    );
  }

  Widget _buildFooter(bool isLoading) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey[600],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Sign up link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: isLoading ? null : widget.togglePages,
              child: Text(
                'Create Account',
                style: TextStyle(
                  color: isLoading ? Colors.grey[600] : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}