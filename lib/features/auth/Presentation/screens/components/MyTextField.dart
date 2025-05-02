import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obsecureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obsecureText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obsecureText,
      style: const TextStyle(
        color: Colors.black87, // Text inside field
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF7F7F7), // very light grey background
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500, // light grey hint
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 16.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade300, // light grey border when not selected
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade600, // darker grey when selected
            width: 1.8,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
