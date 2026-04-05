import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBird extends StatefulWidget {
  final double platformWidth;
  final double platformHeight;
  
  const AnimatedBird({
    super.key,
    required this.platformWidth,
    required this.platformHeight,
  });

  @override
  State<AnimatedBird> createState() => _AnimatedBirdState();
}

class _AnimatedBirdState extends State<AnimatedBird> 
    with TickerProviderStateMixin {
  late AnimationController _flightController;
  late AnimationController _wingController;
  late Animation<Offset> _flightAnimation;
  late Animation<double> _wingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Flight path animation (10-second loop)
    _flightController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Wing flapping animation (0.3-second loop)
    _wingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    
    // Create circular flight path
    _flightAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.1, 0.2),
          end: const Offset(0.9, 0.3),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.9, 0.3),
          end: const Offset(0.8, 0.8),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.8, 0.8),
          end: const Offset(0.2, 0.7),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.2, 0.7),
          end: const Offset(0.1, 0.2),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_flightController);
    
    // Wing flapping
    _wingAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _wingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flightController.dispose();
    _wingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flightAnimation, _wingAnimation]),
      builder: (context, child) {
        final position = _flightAnimation.value;
        final wingAngle = _wingAnimation.value;
        
        return Positioned(
          left: position.dx * widget.platformWidth,
          top: position.dy * widget.platformHeight,
          child: Transform.rotate(
            angle: wingAngle,
            child: Icon(
              Icons.flight,
              color: const Color(0xFF5CE1E6),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
