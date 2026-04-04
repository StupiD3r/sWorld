import 'package:flutter/material.dart';

class AnimatedOakTree extends StatefulWidget {
  final double scale;
  final Duration duration;

  const AnimatedOakTree({
    super.key,
    this.scale = 1.0,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedOakTree> createState() => _AnimatedOakTreeState();
}

// FIX 1: Changed to TickerProviderStateMixin to support multiple animation controllers
class _AnimatedOakTreeState extends State<AnimatedOakTree>
    with TickerProviderStateMixin {
  late AnimationController _swayController;
  late AnimationController _leafController;
  late Animation<double> _swayAnimation;
  late Animation<double> _leafAnimation;

  @override
  void initState() {
    super.initState();

    _swayController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _leafController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _swayAnimation = Tween<double>(
      begin: -0.03,
      end: 0.03,
    ).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));

    _leafAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _leafController,
      curve: Curves.easeInOut,
    ));

    _swayController.repeat(reverse: true);
    _leafController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _swayController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_swayAnimation, _leafAnimation]),
      builder: (context, child) {
        final combinedSway = _swayAnimation.value;
        final leafScale = _leafAnimation.value;

        return Transform.rotate(
          angle: combinedSway,
          child: Transform.scale(
            scale: widget.scale * leafScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tree crown (oak style)
                Container(
                  width: 45,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment(0.3, -0.2),
                      radius: 0.8,
                      colors: [
                        Color(0xFF228B22), // Dark green
                        Color(0xFF32CD32), // Light green
                        Color(0xFF90EE90), // Light green
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                      // Added slight bottom rounding so it sits nicely on the trunk
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ), // FIX 3: Added missing closing bracket for the crown container

                // FIX 2: Moved the trunk out to be a sibling in the Column
                // Tree trunk (oak style - thicker)
                Container(
                  width: 16,
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF8B4513), // Saddle brown
                        Color(0xFF654321), // Darker brown
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}