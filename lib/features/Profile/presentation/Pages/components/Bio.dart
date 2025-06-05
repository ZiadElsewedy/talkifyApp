import 'package:flutter/material.dart';

class Mybio extends StatefulWidget {
  final String bioText;

  const Mybio({Key? key, required this.bioText}) : super(key: key);

  @override
  State<Mybio> createState() => _MybioState();
}

class _MybioState extends State<Mybio> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1);
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.08);
    final barColor = isDarkMode ? Colors.blue[700]! : Colors.black;
    final aboutText = isDarkMode ? Colors.grey[200]! : Colors.black54;
    final bioText = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final emptyBioText = isDarkMode ? Colors.grey[500]! : Colors.black38;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 18,
                        width: 3,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "About",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: aboutText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.bioText.isEmpty ? "No bio added yet..." : widget.bioText,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: 0.2,
                      color: widget.bioText.isEmpty 
                          ? emptyBioText 
                          : bioText,
                      fontWeight: widget.bioText.isEmpty 
                          ? FontWeight.normal 
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
