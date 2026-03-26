import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/activity_page.dart';
import '../pages/jungle_demo_page.dart';
import '../widgets/jungle_platform.dart';

class Particle {
  double x, y;
  double vx, vy;
  double mass;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.mass = 1.0,
    required this.color,
    this.size = 2.0,
  });

  void update(double dt, double gravity, Size bounds, double friction) {
    vy += gravity * dt;
    vx *= friction;
    vy *= friction;
    x += vx * dt;
    y += vy * dt;

    if (x < 0) { x = 0; vx = -vx * 0.5; }
    else if (x > bounds.width) { x = bounds.width; vx = -vx * 0.5; }

    if (y < 0) { y = 0; vy = -vy * 0.5; }
    else if (y > bounds.height) { y = bounds.height; vy = -vy * 0.6; }
  }

  void applyWind(double windX, double windY) {
    vx += windX / mass;
    vy += windY / mass;
  }
}

class SandboxPainter extends CustomPainter {
  final List<Particle> particles;
  final double radius;
  final double wavePhase;

  SandboxPainter({
    required this.particles,
    required this.radius,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bgGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [
        const Color(0xFF1A3A5C),
        const Color(0xFF0D5C36),
        const Color(0xFF8B4513),
        const Color(0xFF1A1A2E),
      ],
      stops: const [0.2, 0.5, 0.8, 1.0],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, bgPaint);

    _drawWaves(canvas, center, radius, wavePhase);

    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 2));
    canvas.clipPath(clipPath);

    for (final particle in particles) {
      final particlePaint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        particlePaint,
      );
    }

    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFF5CE1E6).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);

    final glowPaint = Paint()
      ..color = const Color(0xFF5CE1E6).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 15);

    canvas.drawCircle(center, radius, glowPaint);
  }

  void _drawWaves(Canvas canvas, Offset center, double radius, double phase) {
    final wavePaint = Paint()
      ..color = const Color(0xFF5CE1E6).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final waveRadius = radius * (0.3 + i * 0.25) + math.sin(phase + i) * 5;
      if (waveRadius < radius - 5) {
        final path = Path();
        for (double angle = 0; angle <= 2 * math.pi; angle += 0.1) {
          final r = waveRadius + math.sin(angle * 8 + phase * 2) * 3;
          final x = center.dx + math.cos(angle) * r;
          final y = center.dy + math.sin(angle) * r;
          if (angle == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SandboxPainter oldDelegate) => true;
}

class DashboardPage extends StatefulWidget {
  final String username;
  final String email;
  final String? photoUrl;

  const DashboardPage({
    super.key,
    required this.username,
    required this.email,
    this.photoUrl,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _physicsController;
  late AnimationController _waveController;
  List<Particle> particles = [];
  final double sandboxRadius = 140.0;
  
  // Jungle platform state
  String _lastPlatformAction = 'No interaction yet';
  int _platformTapCount = 0;

  @override
  void initState() {
    super.initState();
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _physicsController.addListener(_updatePhysics);
    _spawnParticles(50);
  }

  @override
  void dispose() {
    _physicsController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _spawnParticles(int count) {
    final centerX = sandboxRadius;
    final centerY = sandboxRadius;
    for (int i = 0; i < count; i++) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      final r = math.Random().nextDouble() * sandboxRadius * 0.8;
      final colors = [
        const Color(0xFFE6D7B9),
        const Color(0xFFC2B280),
        const Color(0xFF5CE1E6).withOpacity(0.5),
        const Color(0xFFFFFFFF).withOpacity(0.3),
      ];
      particles.add(Particle(
        x: centerX + math.cos(angle) * r,
        y: centerY + math.sin(angle) * r,
        vx: (math.Random().nextDouble() - 0.5) * 50,
        vy: (math.Random().nextDouble() - 0.5) * 50,
        mass: 0.5 + math.Random().nextDouble(),
        color: colors[math.Random().nextInt(colors.length)],
        size: 1.5 + math.Random().nextDouble() * 2,
      ));
    }
    if (particles.length > 300) {
      particles.removeRange(0, particles.length - 300);
    }
  }

  void _updatePhysics() {
    // Physics update removed for jungle platform
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Pan gesture removed - handled by platform's scale gesture
  }

  void _onTap(TapDownDetails details) {
    // Tap gesture removed - handled by platform's tap gesture
  }

  void _onPlatformTap(Offset position) {
    setState(() {
      _platformTapCount++;
      _lastPlatformAction = 'Tap #$_platformTapCount at (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})';
    });
  }

  void _onPlatformLongPress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Platform long pressed! Ready for object placement.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetPlatform() {
    setState(() {
      _platformTapCount = 0;
      _lastPlatformAction = 'Platform reset - Ready for new interactions';
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/images/sWorld_Logo.png',
          height: 40,
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF5CE1E6)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF0A1628),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A2B4A), Color(0xFF0A1628)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF5CE1E6), width: 1),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF5CE1E6),
                    backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
                    child: widget.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF0A1628),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    isActive: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            username: widget.username,
                            email: widget.email,
                            photoUrl: widget.photoUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_activity,
                    title: 'Activity',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Jungle Demo',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JungleDemoPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF5CE1E6), height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Jungle Platform
            Expanded(
              flex: 3,
              child: Center(
                child: JunglePlatform(
                  width: 320,
                  height: 70,
                  depth: 40,
                  onTopSurfaceTap: _onPlatformTap,
                  onLongPress: _onPlatformLongPress,
                ),
              ),
            ),
            // Platform Interaction Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B4A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF5CE1E6).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Platform Activity',
                    style: TextStyle(
                      color: Color(0xFF5CE1E6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastPlatformAction,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Reset Platform',
                    onPressed: _resetPlatform,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Swipe to rotate • Pinch to zoom • Tap to place objects',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: isActive ? const Color(0xFF0A1628) : const Color(0xFF5CE1E6),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isActive ? const Color(0xFF0A1628) : const Color(0xFF5CE1E6),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF5CE1E6) : Colors.transparent,
        foregroundColor: const Color(0xFF5CE1E6),
        side: const BorderSide(color: Color(0xFF5CE1E6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.2),
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF5CE1E6) : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFF5CE1E6) : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? const Color(0xFF1A2B4A) : null,
      onTap: onTap,
    );
  }
}
