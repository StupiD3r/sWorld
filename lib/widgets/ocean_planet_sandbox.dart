import 'dart:math' as math;
import 'package:flutter/material.dart';

class OceanPlanetSandbox extends StatefulWidget {
  final double size;
  final Function(Offset)? onWindGesture;
  final Function()? onTapGesture;

  const OceanPlanetSandbox({
    super.key,
    this.size = 200,
    this.onWindGesture,
    this.onTapGesture,
  });

  @override
  State<OceanPlanetSandbox> createState() => _OceanPlanetSandboxState();
}

class _OceanPlanetSandboxState extends State<OceanPlanetSandbox>
    with TickerProviderStateMixin {
  late AnimationController _oceanController;
  late AnimationController _cloudController;
  late AnimationController _rotationController;
  late AnimationController _atmosphereController;
  
  Offset windForce = Offset.zero;
  final double maxWindForce = 50.0;

  @override
  void initState() {
    super.initState();
    
    _oceanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    
    _atmosphereController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oceanController.dispose();
    _cloudController.dispose();
    _rotationController.dispose();
    _atmosphereController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      windForce = Offset(
        windForce.dx + details.delta.dx * 0.5,
        windForce.dy + details.delta.dy * 0.5,
      );
      
      windForce = Offset(
        windForce.dx.clamp(-maxWindForce, maxWindForce),
        windForce.dy.clamp(-maxWindForce, maxWindForce),
      );
    });
    
    widget.onWindGesture?.call(details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      windForce = windForce * 0.8;
    });
  }

  @override
  Widget build(BuildContext context) {
    final planetSize = widget.size;
    
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTapGesture,
      child: RepaintBoundary(
        child: Container(
          width: planetSize,
          height: planetSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer atmospheric glow
              AnimatedBuilder(
                animation: _atmosphereController,
                builder: (context, child) {
                  return Container(
                    width: planetSize * 1.3,
                    height: planetSize * 1.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF5CE1E6).withOpacity(0.15 + _atmosphereController.value * 0.05),
                          const Color(0xFF4A90E2).withOpacity(0.08 + _atmosphereController.value * 0.03),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  );
                },
              ),
              
              // Main planet shadow/glow
              Container(
                width: planetSize * 1.15,
                height: planetSize * 1.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF5CE1E6).withOpacity(0.2),
                      const Color(0xFF0b3d91).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Base ocean planet with enhanced lighting
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi * 0.08,
                    child: child,
                  );
                },
                child: Container(
                  width: planetSize,
                  height: planetSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      radius: 1.0,
                      colors: [
                        const Color(0xFF87CEEB), // Sky blue (bright highlight)
                        const Color(0xFF4A90E2), // Medium blue
                        const Color(0xFF0b3d91), // Deep blue
                        const Color(0xFF052060), // Very dark blue (shadow)
                        const Color(0xFF020F30), // Darkest edge
                      ],
                      stops: const [0.0, 0.25, 0.6, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Noise-based animated wave layer
              AnimatedBuilder(
                animation: _oceanController,
                builder: (context, child) {
                  final wavePhase = _oceanController.value * 2 * math.pi;
                  final windOffsetX = windForce.dx * 0.15;
                  final windOffsetY = windForce.dy * 0.15;
                  
                  return ClipOval(
                    child: CustomPaint(
                      size: Size(planetSize, planetSize),
                      painter: NoiseWavePainter(
                        wavePhase: wavePhase,
                        windOffset: Offset(windOffsetX, windOffsetY),
                        time: _oceanController.value,
                      ),
                    ),
                  );
                },
              ),
              
              // Enhanced soft cloud layer
              AnimatedBuilder(
                animation: _cloudController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _cloudController.value * 2 * math.pi * 0.12,
                    child: ClipOval(
                      child: CustomPaint(
                        size: Size(planetSize, planetSize),
                        painter: SoftCloudPainter(
                          cloudPhase: _cloudController.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Enhanced 3D highlight with soft edges
              Positioned(
                top: planetSize * 0.12,
                left: planetSize * 0.18,
                child: Container(
                  width: planetSize * 0.35,
                  height: planetSize * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Secondary highlight for depth
              Positioned(
                top: planetSize * 0.25,
                left: planetSize * 0.35,
                child: Container(
                  width: planetSize * 0.15,
                  height: planetSize * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF87CEEB).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoiseWavePainter extends CustomPainter {
  final double wavePhase;
  final Offset windOffset;
  final double time;

  NoiseWavePainter({
    required this.wavePhase,
    required this.windOffset,
    required this.time,
  });

  // Simple noise function using multiple sine waves
  double noise(double x, double y, double t) {
    final n1 = math.sin(x * 0.02 + t * 2) * math.cos(y * 0.03 + t * 1.5);
    final n2 = math.sin(x * 0.05 - t * 1.8) * math.cos(y * 0.02 + t * 2.2);
    final n3 = math.sin(x * 0.01 + y * 0.01 + t * 0.8);
    return (n1 + n2 * 0.5 + n3 * 0.3) / 1.8;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple noise-based wave layers
    for (int layer = 0; layer < 4; layer++) {
      final layerAlpha = 0.15 - layer * 0.03;
      final layerScale = 1.0 + layer * 0.2;
      
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF6BB6FF),
          const Color(0xFF4A90E2),
          layer / 3.0,
        )!.withOpacity(layerAlpha)
        ..style = PaintingStyle.fill;

      final path = Path();
      bool firstPoint = true;
      
      // Create wave path using noise
      for (double angle = 0; angle <= 2 * math.pi; angle += 0.05) {
        final baseRadius = radius * (0.4 + layer * 0.15);
        
        // Apply noise-based distortion
        final noiseX = math.cos(angle) * radius * 0.8;
        final noiseY = math.sin(angle) * radius * 0.8;
        final noiseValue = noise(noiseX, noiseY, time + layer * 0.5);
        
        final waveHeight = (12.0 + layer * 3.0) * noiseValue;
        final r = baseRadius + waveHeight;
        
        // Add wind influence
        final windInfluence = math.sin(angle * 2 + wavePhase) * windOffset.distance * 0.1;
        
        final x = center.dx + math.cos(angle) * (r + windInfluence) + windOffset.dx;
        final y = center.dy + math.sin(angle) * (r + windInfluence) + windOffset.dy;
        
        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      canvas.drawPath(path, paint);
    }

    // Add subtle surface detail
    final detailPaint = Paint()
      ..color = const Color(0xFF87CEEB).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + time * 0.5;
      final detailRadius = radius * (0.6 + math.sin(time * 2 + i) * 0.1);
      final detailX = center.dx + math.cos(angle) * detailRadius;
      final detailY = center.dy + math.sin(angle) * detailRadius;
      
      canvas.drawCircle(
        Offset(detailX, detailY),
        8.0 + math.sin(time * 3 + i) * 3.0,
        detailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NoiseWavePainter oldDelegate) => 
      oldDelegate.wavePhase != wavePhase || 
      oldDelegate.windOffset != windOffset ||
      oldDelegate.time != time;
}

class SoftCloudPainter extends CustomPainter {
  final double cloudPhase;

  SoftCloudPainter({required this.cloudPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple soft cloud formations
    final cloudPositions = [
      // Main cloud formation
      {
        'center': center + Offset(-radius * 0.3, -radius * 0.25),
        'size': radius * 0.4,
        'density': 0.12,
        'drift': Offset(math.sin(cloudPhase * 2) * 5, math.cos(cloudPhase * 1.5) * 3),
      },
      // Secondary cloud
      {
        'center': center + Offset(radius * 0.2, -radius * 0.4),
        'size': radius * 0.3,
        'density': 0.10,
        'drift': Offset(math.sin(cloudPhase * 2.5) * 4, math.cos(cloudPhase * 2) * 2),
      },
      // Tertiary cloud
      {
        'center': center + Offset(radius * 0.35, radius * 0.15),
        'size': radius * 0.35,
        'density': 0.08,
        'drift': Offset(math.sin(cloudPhase * 1.8) * 6, math.cos(cloudPhase * 2.3) * 4),
      },
      // Small cloud
      {
        'center': center + Offset(-radius * 0.1, radius * 0.35),
        'size': radius * 0.25,
        'density': 0.09,
        'drift': Offset(math.sin(cloudPhase * 3) * 3, math.cos(cloudPhase * 2.8) * 2),
      },
    ];

    for (final cloudData in cloudPositions) {
      final cloudCenter = (cloudData['center'] as Offset) + (cloudData['drift'] as Offset);
      final cloudSize = cloudData['size'] as double;
      final density = cloudData['density'] as double;

      _drawSoftCloudFormation(canvas, cloudCenter, cloudSize, density);
    }
  }

  void _drawSoftCloudFormation(Canvas canvas, Offset center, double size, double density) {
    // Create soft, natural-looking cloud using multiple overlapping circles
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(density)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Main cloud body with irregular shape
    final mainCircles = [
      Offset(0, 0),
      Offset(size * 0.25, -size * 0.15),
      Offset(-size * 0.2, -size * 0.1),
      Offset(size * 0.15, size * 0.1),
      Offset(-size * 0.1, size * 0.15),
      Offset(size * 0.35, 0),
      Offset(-size * 0.25, 0.05),
    ];

    for (final offset in mainCircles) {
      final circleSize = size * (0.4 + math.Random().nextDouble() * 0.2);
      canvas.drawCircle(center + offset, circleSize, cloudPaint);
    }

    // Add wispy edges
    final wispPaint = Paint()
      ..color = Colors.white.withOpacity(density * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final wisps = [
      Offset(size * 0.5, -size * 0.2),
      Offset(-size * 0.4, size * 0.2),
      Offset(size * 0.3, size * 0.3),
      Offset(-size * 0.35, -size * 0.25),
    ];

    for (final offset in wisps) {
      canvas.drawCircle(
        center + offset,
        size * 0.15 + math.Random().nextDouble() * size * 0.1,
        wispPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoftCloudPainter oldDelegate) => 
      oldDelegate.cloudPhase != cloudPhase;
}
