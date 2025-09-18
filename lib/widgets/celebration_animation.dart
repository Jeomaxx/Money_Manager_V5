import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class CelebrationAnimation extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onComplete;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CelebrationAnimation({
    super.key,
    required this.isVisible,
    this.onComplete,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _initializeParticles();
  }

  @override
  void didUpdateWidget(CelebrationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(_particleCount, (index) {
      return Particle(
        color: index % 2 == 0 
            ? (widget.primaryColor ?? Colors.amber)
            : (widget.secondaryColor ?? Colors.orange),
        size: random.nextDouble() * 8 + 4,
        initialAngle: random.nextDouble() * 2 * math.pi,
        velocity: random.nextDouble() * 200 + 100,
        gravity: random.nextDouble() * 50 + 50,
      );
    });
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: CelebrationPainter(
                particles: _particles,
                animationValue: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class Particle {
  final Color color;
  final double size;
  final double initialAngle;
  final double velocity;
  final double gravity;

  Particle({
    required this.color,
    required this.size,
    required this.initialAngle,
    required this.velocity,
    required this.gravity,
  });
}

class CelebrationPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  CelebrationPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      final progress = animationValue;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      
      if (opacity <= 0) continue;

      // Calculate position based on physics
      final time = progress * 2; // 2 seconds
      final velocityX = math.cos(particle.initialAngle) * particle.velocity;
      final velocityY = math.sin(particle.initialAngle) * particle.velocity;
      
      final x = centerX + velocityX * time;
      final y = centerY + velocityY * time + 0.5 * particle.gravity * time * time;
      
      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // Add some rotation and scale variation
      final scale = 1.0 - (progress * 0.5);
      final finalSize = particle.size * scale;
      
      canvas.drawCircle(
        Offset(x, y),
        finalSize,
        paint,
      );
      
      // Add sparkle effect
      if (progress < 0.3) {
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(x, y),
          finalSize * 0.3,
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CelebrationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Success celebration overlay widget
class SuccessCelebration extends StatefulWidget {
  final bool show;
  final String message;
  final VoidCallback? onComplete;

  const SuccessCelebration({
    super.key,
    required this.show,
    required this.message,
    this.onComplete,
  });

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration> {
  @override
  Widget build(BuildContext context) {
    if (!widget.show) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black26,
      child: Stack(
        children: [
          // Celebration particles
          CelebrationAnimation(
            isVisible: widget.show,
            onComplete: widget.onComplete,
            primaryColor: Colors.green,
            secondaryColor: Colors.lightGreen,
          ),
          
          // Success message
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                      .animate()
                      .scaleXY(begin: 0.0, duration: 500.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 300.ms),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.message,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.3, delay: 300.ms, duration: 500.ms),
                ],
              ),
            )
                .animate()
                .scaleXY(begin: 0.8, duration: 400.ms, curve: Curves.easeOut)
                .fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}