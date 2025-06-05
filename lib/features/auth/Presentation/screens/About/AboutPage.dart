import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Animation<double>> _fadeAnimations = [];
  final int _totalAnimationItems = 10;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Create staggered animations for different sections
    for (int i = 0; i < _totalAnimationItems; i++) {
      final startInterval = i * 0.05;
      final endInterval = startInterval + 0.3;
      
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
          ),
        ),
      );
    }

    // Start animation after a short delay
    Timer(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final appBarBg = colorScheme.surface;
    final appBarText = colorScheme.inversePrimary;
    final sectionBg = isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
    final cardBg = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardBorder = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final cardText = isDarkMode ? Colors.grey[200]! : Colors.grey[800]!;
    final cardSubText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final sectionTitle = isDarkMode ? Colors.white : Colors.black;
    final sectionBar = isDarkMode ? Colors.blue[700]! : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final iconBg = isDarkMode ? Colors.blue[900]! : Colors.black.withOpacity(0.05);
    final featureTitle = isDarkMode ? Colors.white : Colors.black;
    final featureDesc = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final contactTitle = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final contactInfo = isDarkMode ? Colors.white : Colors.black;
    final socialBg = isDarkMode ? Colors.blue[900]! : Colors.black;
    final socialIcon = Colors.white;
    final copyrightBg = sectionBg;
    final copyrightText = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'About Talkify',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: appBarBg,
        foregroundColor: appBarText,
        iconTheme: IconThemeData(color: appBarText),
        titleTextStyle: TextStyle(color: appBarText, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // App Branding Section
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeAnimations[0]),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: sectionBg,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 70,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // App Name
                            Text(
                              'TALKIFY',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: sectionTitle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Tagline
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.blue[900]!.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Connect • Share • Engage',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: sectionTitle,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // App Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'A modern messaging platform designed to bring people together through seamless communication.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: cardText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // What is Talkify Section
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.2, 0),
                        end: Offset.zero,
                      ).animate(_fadeAnimations[1]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('What is Talkify?', sectionBar, sectionTitle),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              child: Column(
                                children: [
                                  Text(
                                    'Talkify is a state-of-the-art messaging application that focuses on creating meaningful connections between people. Our platform provides a secure, intuitive, and feature-rich environment for personal and group conversations.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: cardText,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Built with the latest technology, Talkify offers a seamless experience across devices while prioritizing your privacy and data security.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: cardText,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Key Features Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimations[2],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(_fadeAnimations[2]),
                            child: _buildSectionTitle('Key Features', sectionBar, sectionTitle),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeAnimations[3],
                          child: _buildFeatureCard(
                            icon: Icons.message_rounded,
                            title: 'Real-time Messaging',
                            description: 'Send and receive messages instantly with typing indicators and read receipts.',
                            cardBg: cardBg,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            titleColor: featureTitle,
                            descColor: featureDesc,
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimations[4],
                          child: _buildFeatureCard(
                            icon: Icons.groups_rounded,
                            title: 'Group Conversations',
                            description: 'Create group chats with multiple participants for team collaboration or social planning.',
                            cardBg: cardBg,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            titleColor: featureTitle,
                            descColor: featureDesc,
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimations[5],
                          child: _buildFeatureCard(
                            icon: Icons.photo_library_rounded,
                            title: 'Rich Media Sharing',
                            description: 'Share photos, videos, documents, and voice messages seamlessly within your conversations.',
                            cardBg: cardBg,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            titleColor: featureTitle,
                            descColor: featureDesc,
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimations[6],
                          child: _buildFeatureCard(
                            icon: Icons.verified_user_rounded,
                            title: 'Privacy & Security',
                            description: 'Your conversations are protected with industry-standard security protocols.',
                            cardBg: cardBg,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            titleColor: featureTitle,
                            descColor: featureDesc,
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimations[7],
                          child: _buildFeatureCard(
                            icon: Icons.notifications_active_rounded,
                            title: 'Smart Notifications',
                            description: 'Stay updated with customizable notification settings for different conversations.',
                            cardBg: cardBg,
                            iconBg: iconBg,
                            iconColor: iconColor,
                            titleColor: featureTitle,
                            descColor: featureDesc,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Our Team Section
                  FadeTransition(
                    opacity: _fadeAnimations[8],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeAnimations[8]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Our Team', sectionBar, sectionTitle),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              child: Text(
                                'Talkify is developed by a passionate team of designers, developers, and communication experts committed to creating the best messaging experience possible. We believe in the power of connection and strive to make communication more accessible, enjoyable, and meaningful.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: cardText,
                                  height: 1.6,
                                ),
                              ),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Contact Section
                  FadeTransition(
                    opacity: _fadeAnimations[9],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_fadeAnimations[9]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Contact Us', sectionBar, sectionTitle),
                            const SizedBox(height: 16),
                            _buildContactInfo(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              info: 'support@talkify.com',
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              titleColor: contactTitle,
                              infoColor: contactInfo,
                              iconColor: iconColor,
                            ),
                            _buildContactInfo(
                              icon: Icons.public,
                              title: 'Website',
                              info: 'www.talkify.com',
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              titleColor: contactTitle,
                              infoColor: contactInfo,
                              iconColor: iconColor,
                            ),
                            _buildContactInfo(
                              icon: Icons.location_on_outlined,
                              title: 'Address',
                              info: '6th of October City, Egypt , 10211',
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              titleColor: contactTitle,
                              infoColor: contactInfo,
                              iconColor: iconColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Social Media Links
                  FadeTransition(
                    opacity: _fadeAnimations[9],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(Icons.facebook, socialBg, socialIcon),
                        _buildSocialIcon(Icons.discord, socialBg, socialIcon),
                        _buildSocialIcon(Icons.camera_alt, socialBg, socialIcon),
                        _buildSocialIcon(Icons.flutter_dash, socialBg, socialIcon),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Version and Copyright Info
                  FadeTransition(
                    opacity: _fadeAnimations[9],
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      color: copyrightBg,
                      child: Column(
                        children: [
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: copyrightText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2024 Talkify. All rights reserved.',
                            style: TextStyle(
                              color: copyrightText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color barColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child, Color? cardBg, Color? cardBorder}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorder ?? Colors.grey[200]!),
      ),
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    Color? cardBg,
    Color? iconBg,
    Color? iconColor,
    Color? titleColor,
    Color? descColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg ?? Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor ?? Colors.black),
            ),
            const SizedBox(width: 16),
            // Feature Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: descColor ?? Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String info,
    Color? cardBg,
    Color? cardBorder,
    Color? titleColor,
    Color? infoColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder ?? Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor ?? Colors.black87),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: titleColor ?? Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: infoColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color bg, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 24,
        color: iconColor,
      ),
    );
  }
} 