import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
   MyTextField({super.key, required this.controller, required this.hintText, required this.obsecureText});
  final TextEditingController controller;
  final String hintText;
  bool obsecureText;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obsecureText,
      decoration: InputDecoration(
        // border when unselected
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
          borderRadius: BorderRadius.circular(12)
        ),

        // border when selected 
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
      ),
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      fillColor: Theme.of(context).colorScheme.secondary,
      filled: true,
      ),
    );
  }
}