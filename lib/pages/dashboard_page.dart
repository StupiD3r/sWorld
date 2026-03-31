import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'jungle_demo_page.dart';

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
  int _totalCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalCoins();
  }

  Future<void> _loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCoins = prefs.getInt('totalCoins') ?? 0;
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
                    backgroundImage: widget.photoUrl != null
                        ? NetworkImage(widget.photoUrl!)
                        : null,
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: Color(0xFF5CE1E6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5CE1E6).withOpacity(0.2),
                          const Color(0xFF5CE1E6).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5CE1E6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFF5CE1E6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalCoins',
                          style: const TextStyle(
                            color: Color(0xFF5CE1E6),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'coins',
                          style: TextStyle(
                            color: Color(0xFF5CE1E6),
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                    onTap: () => Navigator.pop(context),
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
            // Static Isometric Jungle Platform
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: CustomPaint(
                      painter: _IsometricPlatformPainter(),
                    ),
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Your jungle world awaits!',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
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

/// Draws a static isometric platform block.
///
/// Visible faces (matching the sketch):
///   - Top face    → grass green
///   - Front-left  → dirt brown (lighter)
///   - Right face  → dirt brown (darker, shadow)
class _IsometricPlatformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Key vertices (normalised to canvas size) ──────────────────────────
    //
    //        p2 ────────── p3
    //       /  (TOP FACE)  /
    //      /              /
    //    p1 ────────── p4
    //    |  (FRONT-L) /|  (RIGHT)
    //    |           / |
    //   p1b ──── p4b   p3b
    //
    final p1  = Offset(w * 0.08, h * 0.46); // left vertex
    final p2  = Offset(w * 0.37, h * 0.13); // back-left vertex (top)
    final p3  = Offset(w * 0.92, h * 0.30); // back-right vertex (top)
    final p4  = Offset(w * 0.63, h * 0.62); // front-right / centre junction

    final p1b = Offset(w * 0.08, h * 0.76); // p1 dropped by block height
    final p4b = Offset(w * 0.63, h * 0.92); // p4 dropped by block height
    final p3b = Offset(w * 0.92, h * 0.60); // p3 dropped by block height

    // ── Paths ─────────────────────────────────────────────────────────────
    final topPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final frontPath = Path()
      ..moveTo(p1.dx,  p1.dy)
      ..lineTo(p4.dx,  p4.dy)
      ..lineTo(p4b.dx, p4b.dy)
      ..lineTo(p1b.dx, p1b.dy)
      ..close();

    final rightPath = Path()
      ..moveTo(p4.dx,  p4.dy)
      ..lineTo(p3.dx,  p3.dy)
      ..lineTo(p3b.dx, p3b.dy)
      ..lineTo(p4b.dx, p4b.dy)
      ..close();

    // ── Paints ────────────────────────────────────────────────────────────

    // Top face – grass gradient
    final topRect = Rect.fromPoints(p2, p4);
    final topPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(topRect);

    // Front-left face – mid-tone dirt
    final frontPaint = Paint()..color = const Color(0xFF8D6E63);

    // Right face – darker dirt (shadow)
    final rightPaint = Paint()..color = const Color(0xFF5D4037);

    // Stroke paints
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;

    // ── Draw faces ────────────────────────────────────────────────────────
    canvas.drawPath(frontPath, frontPaint);
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(topPath,   topPaint);

    // ── Grass detail strokes on top face ──────────────────────────────────
    _drawGrassStrokes(canvas, p1, p2, p3, p4, w, h);

    // ── Dirt detail strokes on front face ─────────────────────────────────
    _drawDirtStrokes(canvas, p1, p4, p4b, p1b, isRight: false);

    // ── Dirt detail strokes on right face ─────────────────────────────────
    _drawDirtStrokes(canvas, p4, p3, p3b, p4b, isRight: true);

    // ── Outline edges ─────────────────────────────────────────────────────
    edgePaint.color = const Color(0xFF1B5E20);
    canvas.drawPath(topPath, edgePaint);

    edgePaint.color = const Color(0xFF3E2723);
    canvas.drawPath(frontPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    // Shared vertical edge (p4 → p4b)
    edgePaint.color = const Color(0xFF3E2723);
    canvas.drawLine(p4, p4b, edgePaint);
  }

  /// Draws zigzag grass strokes across the top face.
  void _drawGrassStrokes(
      Canvas canvas,
      Offset p1, Offset p2, Offset p3, Offset p4,
      double w, double h,
      ) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const int rows = 5;
    const int cols = 8;

    for (int row = 1; row < rows; row++) {
      final t = row / rows;
      // Interpolate left edge (p1→p2) and right edge (p4→p3)
      final leftEdge  = Offset.lerp(p1, p2, t)!;
      final rightEdge = Offset.lerp(p4, p3, t)!;

      final path = Path();
      bool first = true;

      for (int col = 0; col <= cols; col++) {
        final s = col / cols;
        final base = Offset.lerp(leftEdge, rightEdge, s)!;

        // Perpendicular direction (roughly "up" on the face)
        final up = Offset(
          (p2 - p1).dx / (p2 - p1).distance,
          (p2 - p1).dy / (p2 - p1).distance,
        ) * (h * 0.045);

        final tip = base - up * (col.isEven ? 1.0 : 0.4);

        if (first) {
          path.moveTo(base.dx, base.dy);
          first = false;
        }
        path.lineTo(tip.dx, tip.dy);
        path.lineTo(base.dx, base.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Draws horizontal dirt/root strokes across a quad face.
  void _drawDirtStrokes(
      Canvas canvas,
      Offset tl, Offset tr, Offset br, Offset bl, {
        required bool isRight,
      }) {
    final paint = Paint()
      ..color = (isRight
          ? const Color(0xFF4E342E)
          : const Color(0xFF6D4C41))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const int lines = 5;

    for (int i = 1; i < lines; i++) {
      final t = i / lines;
      final left  = Offset.lerp(tl, bl, t)!;
      final right = Offset.lerp(tr, br, t)!;

      // Wavy stroke
      final path = Path();
      const int segments = 10;
      path.moveTo(left.dx, left.dy);

      for (int s = 1; s <= segments; s++) {
        final u     = s / segments;
        final mid   = Offset.lerp(left, right, u)!;
        final wave  = math.sin(u * math.pi * 4) * 2.5;
        path.lineTo(mid.dx, mid.dy + wave);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}