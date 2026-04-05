import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedPig extends StatefulWidget {
  final double platformWidth;
  final double platformHeight;
  
  const AnimatedPig({
    super.key,
    required this.platformWidth,
    required this.platformHeight,
  });

  @override
  State<AnimatedPig> createState() => _AnimatedPigState();
}

class _AnimatedPigState extends State<AnimatedPig> 
    with TickerProviderStateMixin {
  late AnimationController _wanderController;
  late AnimationController _bounceController;
  late Animation<Offset> _wanderAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wandering animation (12-second loop)
    _wanderController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    
    // Bouncing animation (0.8-second loop)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    // Create wandering path
    _wanderAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.3, 0.6),
          end: const Offset(0.7, 0.6),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.7, 0.6),
          end: const Offset(0.7, 0.4),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.7, 0.4),
          end: const Offset(0.3, 0.4),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.3, 0.4),
          end: const Offset(0.3, 0.6),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.3, 0.6),
          end: const Offset(0.5, 0.5),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_wanderController);
    
    // Gentle bouncing
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _wanderController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_wanderAnimation, _bounceAnimation]),
      builder: (context, child) {
        final position = _wanderAnimation.value;
        final bounce = _bounceAnimation.value;
        
        return Positioned(
          left: position.dx * widget.platformWidth,
          top: position.dy * widget.platformHeight - bounce * widget.platformHeight,
          child: Transform.scale(
            scale: 1.0 + bounce,
            child: Icon(
              Icons.pets,
              color: const Color(0xFFFF6B6B),
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
