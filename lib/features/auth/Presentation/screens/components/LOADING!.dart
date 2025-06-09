import 'package:flutter/material.dart';

class ProfessionalCircularProgress extends StatelessWidget {
  const ProfessionalCircularProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? Colors.white : Colors.black;
    final Color backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color innerCircleColor = isDarkMode ? Colors.grey[900]! : Colors.black;
    
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            backgroundColor: backgroundColor,
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: innerCircleColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
