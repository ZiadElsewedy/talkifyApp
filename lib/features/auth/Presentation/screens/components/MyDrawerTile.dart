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
    this.iconColor = const Color.fromARGB(221, 88, 88, 88),
    this.textColor = Colors.black87,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
      onTap: onTap,
    );
  }
}
