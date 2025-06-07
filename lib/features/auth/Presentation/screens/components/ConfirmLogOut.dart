import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class ConfirmLogout extends StatelessWidget {
  const ConfirmLogout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return IconButton(
      icon: Icon(
        Icons.logout,
        color: isDarkMode ? Colors.redAccent[100] : Colors.red[700],
      ),
      onPressed: () async {
        final shouldLogout = await showConfirmLogoutDialog(context);
    
        if (shouldLogout == true) {
          // Call the actual logout method
          await context.read<AuthCubit>().logout();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}

Future<bool?> showConfirmLogoutDialog(BuildContext context) {
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final Color iconColor = isDarkMode ? Colors.redAccent[100]! : Colors.red[700]!;
  final Color cancelTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
  final Color buttonColor = isDarkMode ? Colors.red[700]! : Colors.black;
  
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Text(
            'Confirm Logout',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.grey[300] : Colors.black87,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: cancelTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}