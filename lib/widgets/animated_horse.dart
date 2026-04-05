import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedHorse extends StatefulWidget {
  final double platformWidth;
  final double platformHeight;
  
  const AnimatedHorse({
    super.key,
    required this.platformWidth,
    required this.platformHeight,
  });

  @override
  State<AnimatedHorse> createState() => _AnimatedHorseState();
}

class _AnimatedHorseState extends State<AnimatedHorse> 
    with TickerProviderStateMixin {
  late AnimationController _gallopController;
  late AnimationController _pathController;
  late Animation<double> _gallopAnimation;
  late Animation<Offset> _pathAnimation;

  @override
  void initState() {
    super.initState();
    
    // Galloping animation (0.6-second loop)
    _gallopController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    
    // Path animation (15-second loop)
    _pathController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Create galloping path around platform
    _pathAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.2, 0.7),
          end: const Offset(0.8, 0.7),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.8, 0.7),
          end: const Offset(0.9, 0.3),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.9, 0.3),
          end: const Offset(0.1, 0.3),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.1, 0.3),
          end: const Offset(0.2, 0.7),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_pathController);
    
    // Galloping motion
    _gallopAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _gallopController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _gallopController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pathAnimation, _gallopAnimation]),
      builder: (context, child) {
        final position = _pathAnimation.value;
        final gallop = _gallopAnimation.value;
        
        return Positioned(
          left: position.dx * widget.platformWidth,
          top: position.dy * widget.platformHeight,
          child: Transform.rotate(
            angle: gallop,
            child: Transform.translate(
              offset: Offset(0, gallop.abs() * 10),
              child: Icon(
                Icons.directions_run,
                color: const Color(0xFF8B4513),
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}
