import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackgroundGradient extends StatelessWidget {
  final Animation<double> animation;

  const AnimatedBackgroundGradient({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.sin(animation.value) * 0.5 + 0.5,
                math.cos(animation.value) * 0.5 + 0.5,
              ),
              end: Alignment(
                math.cos(animation.value) * 0.5 + 0.5,
                math.sin(animation.value) * 0.5 + 0.5,
              ),
              colors: [
                Color(0xFF050505),
                Color(0xFF101010),
                Color(0xFF202020),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FloatingParticles extends StatelessWidget {
  final Animation<double> animation;
  final int particleCount;

  const FloatingParticles({
    Key? key,
    required this.animation,
    this.particleCount = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ParticlesPainter(
            animation: animation,
            particleCount: particleCount,
          ),
        );
      },
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final int particleCount;
  final List<Particle> particles;

  ParticlesPainter({
    required this.animation,
    required this.particleCount,
  }) : particles = List.generate(
          particleCount,
          (index) => Particle.random(),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      // Update position based on animation value
      final x = (particle.x * size.width + math.sin(animation.value + particle.offset) * 20) % size.width;
      final y = (particle.y * size.height + math.cos(animation.value + particle.offset) * 20) % size.height;
      
      // Draw the particle
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (0.8 + 0.2 * math.sin(animation.value * 2 + particle.offset)),
        paint..color = Colors.white.withOpacity(0.05 + 0.05 * math.sin(animation.value + particle.offset)),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double offset;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.offset,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1.0 + random.nextDouble() * 3.0,
      offset: random.nextDouble() * 10,
    );
  }
}

class FloatingOrbs extends StatelessWidget {
  final Animation<double> animation;
  final int orbCount;

  const FloatingOrbs({
    Key? key,
    required this.animation,
    this.orbCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random(42); // Fixed seed for consistent positions

    return Stack(
      children: List.generate(
        orbCount,
        (index) {
          final xPos = random.nextDouble() * size.width;
          final yPos = random.nextDouble() * size.height;
          final orbSize = 50.0 + random.nextDouble() * 100;
          final speed = 0.5 + random.nextDouble() * 0.5;
          final phaseOffset = random.nextDouble() * math.pi * 2;

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final xOffset = math.sin(animation.value * speed + phaseOffset) * 40;
              final yOffset = math.cos(animation.value * speed + phaseOffset + 1) * 40;
              
              return Positioned(
                left: (xPos + xOffset) % size.width,
                top: (yPos + yOffset) % size.height,
                child: Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.01 + 0.01 * math.sin(animation.value)),
                        Colors.white.withOpacity(0),
                      ],
                      stops: [0.2, 1.0],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 