import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obsecureText;
  final bool enabled;
  final String? helperText;
  final Widget? suffixIcon;
  

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obsecureText,
    this.enabled = true,
    this.helperText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color fillColor = isDarkMode ? Colors.grey[900]! : const Color(0xFFF7F7F7);
    final Color hintColor = isDarkMode ? Colors.grey[500]! : Colors.grey.shade500;
    final Color helperColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade600;
    final Color borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final Color focusedBorderColor = isDarkMode ? Colors.grey[400]! : Colors.grey.shade600;

    return TextField(
      enabled: enabled,
      controller: controller,
      obscureText: obsecureText,
      style: TextStyle(
        color: textColor, // Text inside field
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor, // background
        hintText: hintText,
        helperText: helperText,
        helperStyle: TextStyle(
          color: helperColor,
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: hintColor, // hint
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 16.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: borderColor, // border when not selected
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: focusedBorderColor, // border when selected
            width: 1.8,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
