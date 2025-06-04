import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final FontWeight? fontWeight;

  const MyDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use provided colors or default to theme-appropriate colors
    final Color actualIconColor = iconColor ?? 
        (isDarkMode ? Colors.grey[400]! : const Color.fromARGB(221, 88, 88, 88));
    
    final Color actualTextColor = textColor ?? 
        (isDarkMode ? Colors.grey[300]! : Colors.black87);

    return ListTile(
      leading: Icon(
        icon,
        color: actualIconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: actualTextColor,
          fontWeight: fontWeight,
        ),
      ),
      onTap: onTap,
    );
  }
}
