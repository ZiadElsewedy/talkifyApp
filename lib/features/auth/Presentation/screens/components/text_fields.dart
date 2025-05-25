import 'package:flutter/material.dart';

class AnimatedTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final bool enabled;

  const AnimatedTextField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isFocused = focusNode.hasFocus;
    bool hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isFocused 
            ? Colors.white.withOpacity(0.1) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused 
              ? Colors.white.withOpacity(0.3) 
              : Colors.white.withOpacity(0.1),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ] : [],
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isFocused ? 1.02 : 1.0),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            prefixIcon: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: Icon(
                icon, 
                color: isFocused ? Colors.white : Colors.grey[400],
                size: isFocused ? 24 : 22,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: enabled ? onToggleVisibility : null,
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        key: ValueKey(obscureText),
                        color: isFocused ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ),
    );
  }
} 