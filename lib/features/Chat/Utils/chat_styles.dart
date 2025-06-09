import 'package:flutter/material.dart';

class ChatStyles {
  // Colors
  static const Color primaryColor = Colors.black;
  static const Color secondaryColor = Colors.white;
  static const Color accentColor = Color(0xFF333333);
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color offlineColor = Color(0xFFBDBDBD);
  static const Color subtleGreyColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  
  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: primaryColor,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF757575),
  );
  
  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16,
    color: primaryColor,
  );
  
  static const TextStyle messageSentTextStyle = TextStyle(
    fontSize: 16,
    color: secondaryColor,
  );
  
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF9E9E9E),
  );
  
  // Decoration
  static BoxDecoration messageBubbleDecoration({required bool isFromCurrentUser, BuildContext? context}) {
    final isDarkMode = context != null && Theme.of(context).brightness == Brightness.dark;
    
    return BoxDecoration(
      color: isFromCurrentUser
          ? primaryColor  // Current user - same color in both modes
          : (isDarkMode ? Colors.grey.shade800 : Colors.white),  // Other users - grey in dark, white in light
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isFromCurrentUser 
            ? const Radius.circular(16) 
            : const Radius.circular(4),
        bottomRight: isFromCurrentUser 
            ? const Radius.circular(4) 
            : const Radius.circular(16),
      ),
    );
  }
  
  static BoxDecoration statusIndicatorDecoration({required bool isOnline}) {
    return BoxDecoration(
      color: isOnline ? onlineColor : offlineColor,
      border: Border.all(color: secondaryColor, width: 2),
      borderRadius: BorderRadius.circular(6),
    );
  }
  
  // Animations
  static AnimationController getMessageAnimationController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  static Animation<double> getMessageSlideAnimation(AnimationController controller) {
    return Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );
  }
  
  static Animation<double> getMessageFadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
  
  static AnimationController getTypingIndicatorController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }
  
  static Animation<double> getTypingIndicatorAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  static Widget fadeInFromBottom({
    required Widget child, 
    required AnimationController controller,
  }) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );
    
    final Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
  
  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: secondaryColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  );
  
  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: secondaryColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  );
} 