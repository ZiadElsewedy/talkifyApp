import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
   MyButton({super.key, this.onTap, required this.text});
  final void Function()? onTap;
  final String text; 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // button color
          color: Theme.of(context).colorScheme.tertiary,

          // curved corners
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(text,
          style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          ),),
        ),
      ),
    );
  }
}