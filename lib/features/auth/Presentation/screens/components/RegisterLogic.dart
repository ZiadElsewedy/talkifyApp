import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class RegisterLogic {
  static void register({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
  }) {
    // Validate all fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phoneNumber.isEmpty) {
      _showError(context, 'Please fill in all fields');
      return;
    }

    // Validate password match
    if (password != confirmPassword) {
      _showError(context, 'Password and Confirm Password do not match');
      return;
    }

    // Validate email format
    if (!email.contains('@') || !email.contains('.')) {
      _showError(context, 'Please enter a valid email address');
      return;
    }

    // Validate password length
    if (password.length < 8) {
      _showError(context, 'Password must be at least 8 characters long');
      return;
    }

    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError(context, 'Password must contain at least one uppercase letter');
      return;
    }

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError(context, 'Password must contain at least one lowercase letter');
      return;
    }

    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError(context, 'Password must contain at least one number');
      return;
    }

    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showError(context, 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)');
      return;
    }

    // If all validations pass, proceed with registration
    context.read<AuthCubit>().register(
      PHONENUMBER: phoneNumber,
      NAME: name,
      EMAIL: email,
      PASSWORD: password,
      CONFIRMPASSWORD: confirmPassword,
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} 