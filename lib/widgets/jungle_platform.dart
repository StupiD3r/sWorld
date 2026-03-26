import 'dart:math' as math;
import 'package:flutter/material.dart';

class JunglePlatform extends StatefulWidget {
  final double width;
  final double height;
  final double depth;
  final Function(Offset)? onTopSurfaceTap;
  final VoidCallback? onLongPress;

  const JunglePlatform({
    super.key,
    this.width = 320,
    this.height = 180,
    this.depth = 55,
    this.onTopSurfaceTap,
    this.onLongPress,
  });

  @override
  State<JunglePlatform> createState() => _JunglePlatformState();
}

class _JunglePlatformState extends State<JunglePlatform>
    with SingleTickerProviderStateMixin {
  double _rotationY = 0.0;
  double _scale = 1.0;

  double _baseRotationY = 0.0;
  double _baseScale = 1.0;

  late AnimationController _floatController;

  // Fixed isometric tilt
  final double _tiltX = -0.55;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseRotationY = _rotationY;
    _baseScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Pinch zoom
      _scale = (_baseScale * details.scale).clamp(0.7, 2.0);

      // Horizontal swipe = rotate around Y axis
      _rotationY = _baseRotationY + details.focalPointDelta.dx * 0.02;
    });
  }

  void _handleTap(TapUpDetails details) {
    widget.onTopSurfaceTap?.call(details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onTapUp: _handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final floatOffset =
                math.sin(_floatController.value * 2 * math.pi) * 4;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..translate(0.0, floatOffset, 0.0)
                ..rotateX(_tiltX)
                ..rotateY(_rotationY)
                ..scale(_scale),
              child: child,
            );
          },
          child: CustomPaint(
            size: Size(widget.width, widget.height + widget.depth + 120),
            painter: JunglePlatformPainter(
              width: widget.width,
              height: widget.height,
              depth: widget.depth,
            ),
          ),
        ),
      ),
    );
  }
}

class JunglePlatformPainter extends CustomPainter {
  final double width;
  final double height;
  final double depth;

  JunglePlatformPainter({
    required this.width,
    required this.height,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the 8 vertices of the rectangular cube
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Front face vertices
    final frontTopLeft = Offset(centerX - width/2, centerY - height/2);
    final frontTopRight = Offset(centerX + width/2, centerY - height/2);
    final frontBottomRight = Offset(centerX + width/2, centerY + height/2);
    final frontBottomLeft = Offset(centerX - width/2, centerY + height/2);
    
    // Back face vertices (offset by depth - more subtle for flat look)
    final backTopLeft = frontTopLeft - Offset(depth * 0.3, depth * 0.3);
    final backTopRight = frontTopRight - Offset(depth * 0.3, depth * 0.3);
    final backBottomRight = frontBottomRight - Offset(depth * 0.3, depth * 0.3);
    final backBottomLeft = frontBottomLeft - Offset(depth * 0.3, depth * 0.3);
    
    // Draw shadow (floating effect)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final shadowPath = Path()
      ..addPolygon([
        frontBottomLeft + Offset(3, 3),
        frontBottomRight + Offset(3, 3),
        backBottomRight + Offset(3, 6),
        backBottomLeft + Offset(3, 6),
      ], true);
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw the 6 faces of the cube (back to front for proper depth)
    
    // 1. Back face (dirt)
    final backFacePath = Path()
      ..addPolygon([
        backTopLeft,
        backTopRight,
        backBottomRight,
        backBottomLeft,
      ], true);
    
    final backFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8B4513), // Saddle brown
          const Color(0xFF654321), // Darker brown
        ],
      ).createShader(Rect.fromPoints(backTopLeft, backBottomRight));
    
    canvas.drawPath(backFacePath, backFacePaint);
    
    // 2. Bottom face (dirt)
    final bottomFacePath = Path()
      ..addPolygon([
        frontBottomLeft,
        backBottomLeft,
        backBottomRight,
        frontBottomRight,
      ], true);
    
    final bottomFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8B4513), // Saddle brown
          const Color(0xFF654321), // Darker brown
        ],
      ).createShader(Rect.fromPoints(frontBottomLeft, backBottomRight));
    
    canvas.drawPath(bottomFacePath, bottomFacePaint);
    
    // 3. Left side face (dirt)
    final leftFacePath = Path()
      ..addPolygon([
        frontTopLeft,
        backTopLeft,
        backBottomLeft,
        frontBottomLeft,
      ], true);
    
    final leftFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B4513), // Saddle brown
          const Color(0xFF654321), // Darker brown
        ],
      ).createShader(Rect.fromPoints(frontTopLeft, frontBottomLeft));
    
    canvas.drawPath(leftFacePath, leftFacePaint);
    
    // 4. Right side face (dirt)
    final rightFacePath = Path()
      ..addPolygon([
        frontTopRight,
        backTopRight,
        backBottomRight,
        frontBottomRight,
      ], true);
    
    final rightFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B4513), // Saddle brown
          const Color(0xFF654321), // Darker brown
        ],
      ).createShader(Rect.fromPoints(frontTopRight, frontBottomRight));
    
    canvas.drawPath(rightFacePath, rightFacePaint);
    
    // 5. Front face (dirt)
    final frontFacePath = Path()
      ..addPolygon([
        frontTopLeft,
        frontTopRight,
        frontBottomRight,
        frontBottomLeft,
      ], true);
    
    final frontFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B4513), // Saddle brown
          const Color(0xFF654321), // Darker brown
        ],
      ).createShader(Rect.fromPoints(frontTopLeft, frontBottomLeft));
    
    canvas.drawPath(frontFacePath, frontFacePaint);
    
    // 6. Top face (grass) - main visible surface
    final topFacePath = Path()
      ..addPolygon([
        backTopLeft,
        backTopRight,
        frontTopRight,
        frontTopLeft,
      ], true);
    
    final topFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF90EE90), // Light green grass
          const Color(0xFF228B22), // Forest green grass
          const Color(0xFF32CD32), // Lime green grass
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromPoints(backTopLeft, frontTopRight));
    
    canvas.drawPath(topFacePath, topFacePaint);
    
    // Add grass texture on top face
    if (width > 50) {
      final grassTexturePaint = Paint()
        ..color = const Color(0xFF228B22).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      // Create grass texture pattern
      final grassSpacing = width / 8;
      for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 3; j++) {
          final startX = backTopLeft.dx + (frontTopRight.dx - backTopLeft.dx) * i / 7;
          final startY = backTopLeft.dy + (frontTopRight.dy - backTopLeft.dy) * i / 7;
          final endX = startX + grassSpacing * 0.3;
          final endY = startY - 5 - j * 2;
          
          canvas.drawLine(Offset(startX, startY), Offset(endX, endY), grassTexturePaint);
        }
      }
    }
    
    // Draw subtle edges for definition
    final edgePaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Only draw top face edges to maintain clean look
    canvas.drawLine(backTopLeft, backTopRight, edgePaint);
    canvas.drawLine(backTopRight, frontTopRight, edgePaint);
    canvas.drawLine(frontTopRight, frontTopLeft, edgePaint);
    canvas.drawLine(frontTopLeft, backTopLeft, edgePaint);
  }

  @override
  bool shouldRepaint(covariant JunglePlatformPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.depth != depth;
  }
}