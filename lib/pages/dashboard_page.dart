import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'community_page.dart';
import 'admin_overview_page.dart';

// ─── Decoration types ─────────────────────────────────────────────────────────

enum CubeDecoration { none, oakTree, palmTree, pineTree, bird, pig, horse }

enum DecorationCategory { trees, animals, terrain }

extension DecorationCategoryLabel on DecorationCategory {
  String get label {
    switch (this) {
      case DecorationCategory.trees:   return 'Trees';
      case DecorationCategory.animals: return 'Animals';
      case DecorationCategory.terrain: return 'Terrain';
    }
  }

  IconData get icon {
    switch (this) {
      case DecorationCategory.trees:   return Icons.park;
      case DecorationCategory.animals: return Icons.pets;
      case DecorationCategory.terrain: return Icons.landscape;
    }
  }

  List<CubeDecoration> get items {
    switch (this) {
      case DecorationCategory.trees:
        return [CubeDecoration.oakTree, CubeDecoration.palmTree, CubeDecoration.pineTree];
      case DecorationCategory.animals:
        return [CubeDecoration.bird, CubeDecoration.pig, CubeDecoration.horse];
      case DecorationCategory.terrain:
        return [];
    }
  }
}

extension CubeDecorationLabel on CubeDecoration {
  String get label {
    switch (this) {
      case CubeDecoration.none:     return 'Empty';
      case CubeDecoration.oakTree:  return 'Oak Tree';
      case CubeDecoration.palmTree: return 'Palm Tree';
      case CubeDecoration.pineTree: return 'Pine Tree';
      case CubeDecoration.bird:     return 'Bird';
      case CubeDecoration.pig:      return 'Pig';
      case CubeDecoration.horse:    return 'Horse';
    }
  }

  IconData get icon {
    switch (this) {
      case CubeDecoration.none:     return Icons.crop_square;
      case CubeDecoration.oakTree:  return Icons.park;
      case CubeDecoration.palmTree: return Icons.nature;
      case CubeDecoration.pineTree: return Icons.forest;
      case CubeDecoration.bird:     return Icons.flight;
      case CubeDecoration.pig:      return Icons.pets;
      case CubeDecoration.horse:    return Icons.directions_run;
    }
  }

  int get price {
    switch (this) {
      case CubeDecoration.none:     return 0;
      case CubeDecoration.oakTree:  return 199;
      case CubeDecoration.palmTree: return 299;
      case CubeDecoration.pineTree: return 449;
      case CubeDecoration.bird:     return 999;
      case CubeDecoration.pig:      return 199;
      case CubeDecoration.horse:    return 499;
    }
  }
}

// ─── Slot model ───────────────────────────────────────────────────────────────

class PlatformSlot {
  final int col;
  final int row;
  CubeDecoration decoration;

  PlatformSlot({
    required this.col,
    required this.row,
    this.decoration = CubeDecoration.none,
  });
}

// ─── Dashboard page ───────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  final String username;
  final String email;
  final String? photoUrl;
  final bool isAdmin;

  const DashboardPage({
    super.key,
    required this.username,
    required this.email,
    this.photoUrl,
    this.isAdmin = false,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _cols = 4;
  static const int _rows = 2;

  late final List<PlatformSlot> _slots = [
    for (int r = 0; r < _rows; r++)
      for (int c = 0; c < _cols; c++)
        PlatformSlot(col: c, row: r),
  ];

  // ── KEY FIX: use Map<String,Offset> — same key format as the painter ──────
  Map<String, Offset> _slotCenters = {};

  int _totalCoins = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTotalCoins();
    _loadDecorations();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadTotalCoins();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTotalCoins();
  }

  Future<void> _loadTotalCoins() async {
    if (widget.isAdmin) {
      setState(() => _totalCoins = 10000);
      await _saveTotalCoins();
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _totalCoins =
          prefs.getInt('totalCoins_${widget.username}') ?? 0);
    }
  }

  Future<void> _saveTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalCoins_${widget.username}', _totalCoins);
  }

  Future<void> _saveDecorations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _slots
        .where((s) => s.decoration != CubeDecoration.none)
        .map((s) => {'col': s.col, 'row': s.row, 'decoration': s.decoration.name})
        .toList();
    await prefs.setString('decorations_${widget.username}', jsonEncode(data));
  }

  Future<void> _loadDecorations() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('decorations_${widget.username}');
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      for (final item in list) {
        if (item is! Map) continue;
        final col  = item['col']  as int?;
        final row  = item['row']  as int?;
        final name = item['decoration'] as String?;
        if (col == null || row == null || name == null) continue;
        final slot = _slots.firstWhere(
              (s) => s.col == col && s.row == row,
          orElse: () => PlatformSlot(col: col, row: row),
        );
        slot.decoration = CubeDecoration.values.firstWhere(
              (d) => d.name == name,
          orElse: () => CubeDecoration.none,
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading decorations: $e');
    }
  }

  void _showDecorateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DecorateSheet(
        slots: _slots,
        cols: _cols,
        rows: _rows,
        userCoins: _totalCoins,
        onPlace: (col, row, dec) {
          if (dec == CubeDecoration.none || dec.price <= _totalCoins) {
            setState(() {
              _slots.firstWhere((s) => s.col == col && s.row == row)
                  .decoration = dec;
              if (dec != CubeDecoration.none) _totalCoins -= dec.price;
            });
            _saveTotalCoins();
            _saveDecorations();
          }
        },
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  bool _isLandAnimal(CubeDecoration dec) =>
      dec == CubeDecoration.pig || dec == CubeDecoration.horse;

  @override
  Widget build(BuildContext context) {
    // Sort back rows first → front rows render on top
    final sortedOccupied = _slots
        .where((s) => s.decoration != CubeDecoration.none)
        .toList()
      ..sort((a, b) => b.row.compareTo(a.row));

    final hasBird = _slots.any((s) => s.decoration == CubeDecoration.bird);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/images/sWorld_Logo.png', height: 40),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF5CE1E6)),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF1A2B4A), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Pulsing logo ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5CE1E6), Color(0xFF3FA9C4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5CE1E6).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Image.asset('assets/images/sWorld_Logo.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Platform ──────────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 2.0,
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Platform surface
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _IsometricPlatformPainter(
                                    cols: _cols,
                                    rows: _rows,
                                    onSlotCenters: (centers) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() => _slotCenters = centers);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),

                              // Trees + land animals (slot-anchored)
                              ...sortedOccupied
                                  .where((s) => s.decoration != CubeDecoration.bird)
                                  .map((slot) {
                                // ── KEY FIX: look up by "col_row" string key ──
                                final key = '${slot.col}_${slot.row}';
                                final center = _slotCenters[key];
                                if (center == null) return const SizedBox.shrink();

                                final itemH = h * 0.55;
                                final itemW = w / _cols * 0.85;

                                return Positioned(
                                  left: center.dx - itemW / 2,
                                  top:  center.dy - itemH,
                                  child: SizedBox(
                                    width: itemW,
                                    height: itemH,
                                    child: _isLandAnimal(slot.decoration)
                                        ? _AnimatedLandAnimal(
                                      type: slot.decoration,
                                      slotWidth: itemW,
                                      slotHeight: itemH,
                                    )
                                        : CustomPaint(
                                      painter: _DecorationPainter(
                                          type: slot.decoration),
                                    ),
                                  ),
                                );
                              }),

                              // Bird flock — free-flying above platform
                              if (hasBird)
                                Positioned.fill(
                                  child: _AnimatedBirdFlock(
                                    platformW: w,
                                    platformH: h,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Decorate button ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _showDecorateBottomSheet,
                    icon: const Icon(Icons.design_services, size: 20),
                    label: const Text('Decorate',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CE1E6),
                      foregroundColor: const Color(0xFF0A1628),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 24, top: 8),
                child: Text('Your jungle world awaits!',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
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
                  bottom: BorderSide(color: Color(0xFF5CE1E6), width: 1)),
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
                      ? const Icon(Icons.person,
                      size: 50, color: Color(0xFF0A1628))
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.username,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('ADMIN',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.email,
                    style: const TextStyle(
                        color: Color(0xFF5CE1E6), fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFF5CE1E6).withOpacity(0.2),
                      const Color(0xFF5CE1E6).withOpacity(0.1),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF5CE1E6), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          color: Color(0xFF5CE1E6), size: 20),
                      const SizedBox(width: 8),
                      Text('$_totalCoins',
                          style: const TextStyle(
                              color: Color(0xFF5CE1E6),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Text('coins',
                          style: TextStyle(
                              color: Color(0xFF5CE1E6), fontSize: 14)),
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
                        builder: (_) => ProfilePage(
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
                        builder: (_) =>
                            ActivityPage(username: widget.username),
                      ),
                    ).then((_) => _loadTotalCoins());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt,
                  title: 'Community',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityPage(
                          username: widget.username,
                          isAdmin: widget.isAdmin,
                          photoUrl: widget.photoUrl,
                        ),
                      ),
                    ).then((_) => _loadTotalCoins());
                  },
                ),
                if (widget.isAdmin)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Overview',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminOverviewPage()),
                      );
                    },
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF5CE1E6), height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 16),
        ],
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
      leading: Icon(icon,
          color: isActive ? const Color(0xFF5CE1E6) : Colors.white70),
      title: Text(title,
          style: TextStyle(
            color: isActive ? const Color(0xFF5CE1E6) : Colors.white,
            fontWeight:
            isActive ? FontWeight.bold : FontWeight.normal,
          )),
      tileColor: isActive ? const Color(0xFF1A2B4A) : null,
      onTap: onTap,
    );
  }
}

// ─── Animated bird flock ──────────────────────────────────────────────────────

class _AnimatedBirdFlock extends StatefulWidget {
  final double platformW;
  final double platformH;

  const _AnimatedBirdFlock(
      {required this.platformW, required this.platformH});

  @override
  State<_AnimatedBirdFlock> createState() => _AnimatedBirdFlockState();
}

class _AnimatedBirdFlockState extends State<_AnimatedBirdFlock>
    with TickerProviderStateMixin {
  late final AnimationController _pathCtrl;
  late final AnimationController _wingCtrl;

  static const _birds = [
    (phase: 0.00, scale: 1.00, yOff: 0.00),
    (phase: 0.33, scale: 0.75, yOff: -0.06),
    (phase: 0.66, scale: 0.60, yOff: 0.05),
  ];

  @override
  void initState() {
    super.initState();
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _wingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  Offset _birdPos(double t, double yOff) {
    final angle = t * 2 * math.pi;
    return Offset(
      widget.platformW * (0.5 + 0.42 * math.cos(angle)),
      widget.platformH * (0.18 + yOff + 0.12 * math.sin(angle * 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pathCtrl, _wingCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _BirdFlockPainter(
          birds: _birds,
          pathT: _pathCtrl.value,
          wingT: _wingCtrl.value,
          platformW: widget.platformW,
          platformH: widget.platformH,
          positionOf: _birdPos,
        ),
      ),
    );
  }
}

class _BirdFlockPainter extends CustomPainter {
  final List<({double phase, double scale, double yOff})> birds;
  final double pathT;
  final double wingT;
  final double platformW;
  final double platformH;
  final Offset Function(double t, double yOff) positionOf;

  const _BirdFlockPainter({
    required this.birds,
    required this.pathT,
    required this.wingT,
    required this.platformW,
    required this.platformH,
    required this.positionOf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in birds) {
      final t  = (pathT + b.phase) % 1.0;
      final t2 = (t + 0.01) % 1.0;
      final pos  = positionOf(t,  b.yOff);
      final pos2 = positionOf(t2, b.yOff);
      _drawBird(canvas, pos, b.scale * 22, wingT, pos2.dx >= pos.dx);
    }
  }

  void _drawBird(Canvas canvas, Offset c, double r, double wingT,
      bool facingRight) {
    final flip = facingRight ? 1.0 : -1.0;
    final wingAngle = wingT * 0.6 - 0.3;

    final bodyPaint = Paint()..color = const Color(0xFF29B6F6);
    final wingPaint = Paint()..color = const Color(0xFF0288D1);
    final accentPaint = Paint()..color = const Color(0xFFFFA726);

    canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 1.4, height: r * 0.7),
        bodyPaint);

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(side * wingAngle);
      final wPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
            flip * side * r * 1.2, -r * 0.5, flip * side * r * 1.8, r * 0.1)
        ..quadraticBezierTo(flip * side * r * 1.0, r * 0.3, 0, r * 0.2)
        ..close();
      canvas.drawPath(wPath, wingPaint);
      canvas.restore();
    }

    canvas.drawCircle(
        Offset(c.dx + flip * r * 0.65, c.dy - r * 0.15), r * 0.38, bodyPaint);

    final beakPath = Path()
      ..moveTo(c.dx + flip * r * 0.95, c.dy - r * 0.15)
      ..lineTo(c.dx + flip * r * 1.35, c.dy - r * 0.05)
      ..lineTo(c.dx + flip * r * 0.95, c.dy + r * 0.05)
      ..close();
    canvas.drawPath(beakPath, accentPaint);

    canvas.drawCircle(
        Offset(c.dx + flip * r * 0.70, c.dy - r * 0.22),
        r * 0.09,
        Paint()..color = Colors.black87);

    final tailPath = Path()
      ..moveTo(c.dx - flip * r * 0.65, c.dy)
      ..lineTo(c.dx - flip * r * 1.20, c.dy - r * 0.25)
      ..lineTo(c.dx - flip * r * 1.10, c.dy + r * 0.10)
      ..lineTo(c.dx - flip * r * 1.30, c.dy + r * 0.05)
      ..lineTo(c.dx - flip * r * 0.65, c.dy + r * 0.20)
      ..close();
    canvas.drawPath(tailPath, wingPaint);
  }

  @override
  bool shouldRepaint(covariant _BirdFlockPainter old) => true;
}

// ─── Animated land animal ─────────────────────────────────────────────────────

class _AnimatedLandAnimal extends StatefulWidget {
  final CubeDecoration type;
  final double slotWidth;
  final double slotHeight;

  const _AnimatedLandAnimal({
    required this.type,
    required this.slotWidth,
    required this.slotHeight,
  });

  @override
  State<_AnimatedLandAnimal> createState() => _AnimatedLandAnimalState();
}

class _AnimatedLandAnimalState extends State<_AnimatedLandAnimal>
    with TickerProviderStateMixin {
  late final AnimationController _walkCtrl;
  late final AnimationController _legCtrl;
  late final AnimationController _bobCtrl;

  @override
  void initState() {
    super.initState();
    _walkCtrl = AnimationController(
      vsync: this,
      duration: widget.type == CubeDecoration.horse
          ? const Duration(seconds: 4)
          : const Duration(seconds: 6),
    )..repeat(reverse: true);
    _legCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380))
      ..repeat(reverse: true);
    _bobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _walkCtrl.dispose();
    _legCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_walkCtrl, _legCtrl, _bobCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _LandAnimalPainter(
          type: widget.type,
          walkT: _walkCtrl.value,
          legT: _legCtrl.value,
          bobT: _bobCtrl.value,
        ),
      ),
    );
  }
}

class _LandAnimalPainter extends CustomPainter {
  final CubeDecoration type;
  final double walkT;
  final double legT;
  final double bobT;

  const _LandAnimalPainter({
    required this.type,
    required this.walkT,
    required this.legT,
    required this.bobT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case CubeDecoration.pig:   _drawPig(canvas, size);   break;
      case CubeDecoration.horse: _drawHorse(canvas, size); break;
      default: break;
    }
  }

  void _drawPig(Canvas canvas, Size size) {
    final cx   = size.width * (0.15 + walkT * 0.70);
    final flip = walkT <= 0.5 ? 1.0 : -1.0;
    final bobOff = size.height * 0.01 * math.sin(bobT * math.pi);
    final cy = size.height * 0.68 + bobOff;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.94),
          width: size.width * 0.28,
          height: size.height * 0.04),
      Paint()..color = Colors.black26,
    );

    const legOffsets = [-0.10, -0.03, 0.03, 0.10];
    for (int i = 0; i < 4; i++) {
      final swing = (i % 2 == 0 ? legT : 1 - legT) * 0.08 - 0.04;
      final lx = cx + flip * legOffsets[i] * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx - size.width * 0.025,
              cy + size.height * 0.06 + swing * size.height,
              size.width * 0.05, size.height * 0.10),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFEC407A).withOpacity(0.85),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.38,
          height: size.height * 0.18),
      Paint()..color = const Color(0xFFF48FB1),
    );

    canvas.drawCircle(
      Offset(cx + flip * size.width * 0.18, cy - size.height * 0.03),
      size.width * 0.11,
      Paint()..color = const Color(0xFFF48FB1),
    );

    for (final ey in [-0.10, -0.02]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(
                cx + flip * (size.width * 0.14 + ey.abs() * size.width * 0.5),
                cy - size.height * 0.10),
            width: size.width * 0.06,
            height: size.height * 0.06),
        Paint()..color = const Color(0xFFEC407A),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + flip * size.width * 0.26, cy - size.height * 0.01),
          width: size.width * 0.08,
          height: size.height * 0.055),
      Paint()..color = const Color(0xFFEC407A),
    );
    canvas.drawCircle(
      Offset(cx + flip * size.width * 0.255, cy - size.height * 0.008),
      size.width * 0.012,
      Paint()..color = const Color(0xFFC2185B),
    );
    canvas.drawCircle(
      Offset(cx + flip * size.width * 0.19, cy - size.height * 0.06),
      size.width * 0.016,
      Paint()..color = Colors.black87,
    );

    final tailPath = Path()
      ..moveTo(cx - flip * size.width * 0.17, cy - size.height * 0.01)
      ..quadraticBezierTo(cx - flip * size.width * 0.26,
          cy - size.height * 0.06, cx - flip * size.width * 0.22,
          cy - size.height * 0.12);
    canvas.drawPath(
        tailPath,
        Paint()
          ..color = const Color(0xFFEC407A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
  }

  void _drawHorse(Canvas canvas, Size size) {
    final cx   = size.width * (0.15 + walkT * 0.70);
    final flip = walkT <= 0.5 ? 1.0 : -1.0;
    final bobOff = size.height * 0.012 * math.sin(bobT * math.pi);
    final cy = size.height * 0.62 + bobOff;

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.95),
          width: size.width * 0.38,
          height: size.height * 0.04),
      Paint()..color = Colors.black26,
    );

    const legDxs = [-0.13, -0.04, 0.04, 0.13];
    for (int i = 0; i < 4; i++) {
      final swing = (i % 2 == 0 ? legT : 1 - legT) * 0.10 - 0.05;
      final lx = cx + flip * legDxs[i] * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx - size.width * 0.030,
              cy + size.height * 0.06 + swing * size.height,
              size.width * 0.060, size.height * 0.14),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(lx - size.width * 0.034,
              cy + size.height * 0.20 + swing * size.height,
              size.width * 0.068, size.height * 0.04),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black54,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.52,
          height: size.height * 0.18),
      Paint()..color = const Color(0xFF8D6E63),
    );

    final neck = Path()
      ..moveTo(cx + flip * size.width * 0.14, cy - size.height * 0.05)
      ..lineTo(cx + flip * size.width * 0.20, cy - size.height * 0.16)
      ..lineTo(cx + flip * size.width * 0.28, cy - size.height * 0.16)
      ..lineTo(cx + flip * size.width * 0.22, cy - size.height * 0.05)
      ..close();
    canvas.drawPath(neck, Paint()..color = const Color(0xFF8D6E63));

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + flip * size.width * 0.30, cy - size.height * 0.18),
          width: size.width * 0.16,
          height: size.height * 0.10),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + flip * size.width * 0.38, cy - size.height * 0.16),
          width: size.width * 0.08,
          height: size.height * 0.065),
      Paint()..color = const Color(0xFFA1887F),
    );
    canvas.drawCircle(
      Offset(cx + flip * size.width * 0.395, cy - size.height * 0.155),
      size.width * 0.012,
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawCircle(
      Offset(cx + flip * size.width * 0.265, cy - size.height * 0.20),
      size.width * 0.016,
      Paint()..color = Colors.black87,
    );

    final ear = Path()
      ..moveTo(cx + flip * size.width * 0.26, cy - size.height * 0.22)
      ..lineTo(cx + flip * size.width * 0.28, cy - size.height * 0.28)
      ..lineTo(cx + flip * size.width * 0.31, cy - size.height * 0.22)
      ..close();
    canvas.drawPath(ear, Paint()..color = const Color(0xFF8D6E63));

    for (int i = 0; i < 3; i++) {
      final t = i / 2.0;
      canvas.drawCircle(
        Offset(cx + flip * size.width * (0.18 + t * 0.10),
            cy - size.height * (0.12 + t * 0.04)),
        size.width * 0.04,
        Paint()..color = const Color(0xFF4E342E),
      );
    }

    final tailPath = Path()
      ..moveTo(cx - flip * size.width * 0.24, cy - size.height * 0.02)
      ..quadraticBezierTo(cx - flip * size.width * 0.34,
          cy + size.height * 0.06, cx - flip * size.width * 0.28,
          cy + size.height * 0.14);
    canvas.drawPath(
        tailPath,
        Paint()
          ..color = const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.045
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _LandAnimalPainter old) =>
      old.walkT != walkT || old.legT != legT || old.bobT != bobT;
}

// ─── Decorate bottom sheet ────────────────────────────────────────────────────

class _DecorateSheet extends StatefulWidget {
  final List<PlatformSlot> slots;
  final int cols;
  final int rows;
  final int userCoins;
  final void Function(int col, int row, CubeDecoration dec) onPlace;

  const _DecorateSheet({
    required this.slots,
    required this.cols,
    required this.rows,
    required this.userCoins,
    required this.onPlace,
  });

  @override
  State<_DecorateSheet> createState() => _DecorateSheetState();
}

class _DecorateSheetState extends State<_DecorateSheet> {
  DecorationCategory? _activeCategory;
  CubeDecoration? _selectedDec;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1628),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Color(0xFF5CE1E6), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF5CE1E6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_activeCategory != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _activeCategory = null;
                      _selectedDec = null;
                    }),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF5CE1E6), size: 18),
                    ),
                  ),
                const Icon(Icons.design_services,
                    color: Color(0xFF5CE1E6), size: 24),
                const SizedBox(width: 12),
                Text(
                  _activeCategory == null
                      ? 'Decorate Platform'
                      : _activeCategory!.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(
              color: Color(0xFF5CE1E6),
              height: 16,
              indent: 20,
              endIndent: 20),
          Expanded(
            child: _activeCategory == null
                ? _buildCategoryPicker()
                : _buildItemAndSlotPicker(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE1E6),
                  foregroundColor: const Color(0xFF0A1628),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    const categories = DecorationCategory.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a category',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            children: categories.map((cat) {
              final hasItems = cat.items.isNotEmpty;
              return Expanded(
                child: GestureDetector(
                  onTap: hasItems
                      ? () => setState(() => _activeCategory = cat)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: hasItems
                          ? const Color(0xFF1A2B4A).withOpacity(0.6)
                          : const Color(0xFF1A2B4A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasItems
                            ? const Color(0xFF5CE1E6).withOpacity(0.6)
                            : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    child: Column(children: [
                      Icon(cat.icon,
                          color: hasItems
                              ? const Color(0xFF5CE1E6)
                              : Colors.white24,
                          size: 32),
                      const SizedBox(height: 10),
                      Text(cat.label,
                          style: TextStyle(
                              color: hasItems
                                  ? Colors.white
                                  : Colors.white24,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                      if (!hasItems) ...[
                        const SizedBox(height: 4),
                        const Text('Coming soon',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 10)),
                      ],
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAndSlotPicker() {
    final items = _activeCategory!.items;
    final catName = _activeCategory!.label.toLowerCase();
    final singular = catName.endsWith('s')
        ? catName.substring(0, catName.length - 1)
        : catName;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 — Pick a $singular',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: items.map((dec) {
              final selected   = _selectedDec == dec;
              final canAfford  = dec.price <= widget.userCoins;
              return Expanded(
                child: GestureDetector(
                  onTap: canAfford
                      ? () => setState(() => _selectedDec = dec)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF5CE1E6).withOpacity(0.15)
                          : canAfford
                          ? const Color(0xFF1A2B4A).withOpacity(0.4)
                          : const Color(0xFF1A2B4A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF5CE1E6)
                            : canAfford
                            ? const Color(0xFF5CE1E6).withOpacity(0.3)
                            : Colors.white24,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Icon(dec.icon,
                          color: canAfford
                              ? const Color(0xFF5CE1E6)
                              : Colors.white24,
                          size: 28),
                      const SizedBox(height: 8),
                      Text(dec.label,
                          style: TextStyle(
                              color: canAfford
                                  ? (selected
                                  ? const Color(0xFF5CE1E6)
                                  : Colors.white)
                                  : Colors.white24,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('${dec.price} coins',
                          style: TextStyle(
                              color: canAfford
                                  ? const Color(0xFF5CE1E6)
                                  : Colors.red.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Bird — no slot needed
          if (_selectedDec == CubeDecoration.bird) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF5CE1E6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF5CE1E6).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF5CE1E6), size: 16),
                    SizedBox(width: 6),
                    Text('Birds soar freely above the platform',
                        style: TextStyle(
                            color: Color(0xFF5CE1E6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onPlace(0, 0, CubeDecoration.bird);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.flight, size: 18),
                      label: const Text('Release birds!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CE1E6),
                        foregroundColor: const Color(0xFF0A1628),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_selectedDec != null) ...[
            // Insufficient coins warning
            if (_selectedDec!.price > widget.userCoins)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Need ${_selectedDec!.price} coins — you have ${widget.userCoins}.',
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Land animals — slot picker
              const Text('Step 2 — Choose a slot',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                'Row 1 = front of platform  ·  Row ${widget.rows} = back',
                style: const TextStyle(
                    color: Colors.white30, fontSize: 11),
              ),
              const SizedBox(height: 12),
              for (int r = widget.rows - 1; r >= 0; r--) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        r == 0 ? 'Front' : 'Row ${r + 1}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                    ...List.generate(widget.cols, (c) {
                      final slot = widget.slots.firstWhere(
                              (s) => s.col == c && s.row == r);
                      final occupied =
                          slot.decoration != CubeDecoration.none;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.onPlace(c, r, _selectedDec!);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin:
                            const EdgeInsets.fromLTRB(0, 0, 6, 0),
                            height: 52,
                            decoration: BoxDecoration(
                              color: occupied
                                  ? const Color(0xFF388E3C)
                                  .withOpacity(0.2)
                                  : const Color(0xFF1A2B4A)
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: occupied
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFF5CE1E6)
                                    .withOpacity(0.45),
                                width: occupied ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  occupied
                                      ? slot.decoration.icon
                                      : Icons.add,
                                  color: occupied
                                      ? const Color(0xFF66BB6A)
                                      : Colors.white38,
                                  size: 18,
                                ),
                                const SizedBox(height: 3),
                                Text('${c + 1}',
                                    style: TextStyle(
                                        color: occupied
                                            ? const Color(0xFF66BB6A)
                                            : Colors.white24,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],

          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              for (final s in widget.slots) {
                widget.onPlace(s.col, s.row, CubeDecoration.none);
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_sweep,
                color: Colors.redAccent, size: 18),
            label: const Text('Clear all',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ─── Platform painter ─────────────────────────────────────────────────────────

class _IsometricPlatformPainter extends CustomPainter {
  final int cols;
  final int rows;
  // ── Returns Map<String,Offset> keyed as "col_row" ──────────────────────────
  final void Function(Map<String, Offset> centers)? onSlotCenters;

  const _IsometricPlatformPainter({
    this.cols = 4,
    this.rows = 2,
    this.onSlotCenters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final p1  = Offset(w * 0.08, h * 0.46);
    final p2  = Offset(w * 0.37, h * 0.13);
    final p3  = Offset(w * 0.92, h * 0.30);
    final p4  = Offset(w * 0.63, h * 0.62);
    final p1b = Offset(w * 0.08, h * 0.76);
    final p4b = Offset(w * 0.63, h * 0.92);
    final p3b = Offset(w * 0.92, h * 0.60);

    final topPath = Path()
      ..moveTo(p1.dx, p1.dy) ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy) ..lineTo(p4.dx, p4.dy) ..close();
    final frontPath = Path()
      ..moveTo(p1.dx,  p1.dy)  ..lineTo(p4.dx,  p4.dy)
      ..lineTo(p4b.dx, p4b.dy) ..lineTo(p1b.dx, p1b.dy) ..close();
    final rightPath = Path()
      ..moveTo(p4.dx,  p4.dy)  ..lineTo(p3.dx,  p3.dy)
      ..lineTo(p3b.dx, p3b.dy) ..lineTo(p4b.dx, p4b.dy) ..close();

    final topPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(p2, p4));

    canvas.drawPath(frontPath, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFF5D4037));
    canvas.drawPath(topPath,   topPaint);

    _drawGrassStrokes(canvas, p1, p2, p3, p4, w, h);
    _drawDirtStrokes(canvas, p1, p4, p4b, p1b, isRight: false);
    _drawDirtStrokes(canvas, p4, p3, p3b, p4b, isRight: true);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    edgePaint.color = const Color(0xFF1B5E20);
    canvas.drawPath(topPath, edgePaint);
    edgePaint.color = const Color(0xFF3E2723);
    canvas.drawPath(frontPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
    canvas.drawLine(p4, p4b, edgePaint);

    // ── Slot centres keyed "col_row" ─────────────────────────────────────────
    final colVec = p4 - p1;
    final rowVec = p2 - p1;
    final centers = <String, Offset>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tc = (c + 0.5) / cols;
        final tr = (r + 0.5) / rows;
        centers['${c}_$r'] = p1 + colVec * tc + rowVec * tr;
      }
    }
    onSlotCenters?.call(centers);
  }

  void _drawGrassStrokes(Canvas canvas, Offset p1, Offset p2, Offset p3,
      Offset p4, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int row = 1; row < 5; row++) {
      final t = row / 5;
      final leftEdge  = Offset.lerp(p1, p2, t)!;
      final rightEdge = Offset.lerp(p4, p3, t)!;
      final path = Path();
      bool first = true;
      for (int col = 0; col <= 8; col++) {
        final s    = col / 8;
        final base = Offset.lerp(leftEdge, rightEdge, s)!;
        final up   = Offset(
          (p2 - p1).dx / (p2 - p1).distance,
          (p2 - p1).dy / (p2 - p1).distance,
        ) * (h * 0.045);
        final tip = base - up * (col.isEven ? 1.0 : 0.4);
        if (first) { path.moveTo(base.dx, base.dy); first = false; }
        path.lineTo(tip.dx, tip.dy);
        path.lineTo(base.dx, base.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawDirtStrokes(Canvas canvas, Offset tl, Offset tr, Offset br,
      Offset bl, {required bool isRight}) {
    final paint = Paint()
      ..color = isRight ? const Color(0xFF4E342E) : const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < 5; i++) {
      final t     = i / 5;
      final left  = Offset.lerp(tl, bl, t)!;
      final right = Offset.lerp(tr, br, t)!;
      final path  = Path();
      path.moveTo(left.dx, left.dy);
      for (int s = 1; s <= 10; s++) {
        final u    = s / 10;
        final mid  = Offset.lerp(left, right, u)!;
        final wave = math.sin(u * math.pi * 4) * 2.5;
        path.lineTo(mid.dx, mid.dy + wave);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricPlatformPainter old) =>
      old.cols != cols || old.rows != rows;
}

// ─── Static tree painter ──────────────────────────────────────────────────────

class _DecorationPainter extends CustomPainter {
  final CubeDecoration type;
  const _DecorationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case CubeDecoration.oakTree:  _drawOakTree(canvas, size);  break;
      case CubeDecoration.palmTree: _drawPalmTree(canvas, size); break;
      case CubeDecoration.pineTree: _drawPineTree(canvas, size); break;
      default: break;
    }
  }

  void _drawOakTree(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final trunkW  = size.width * 0.16;
    final trunkH  = size.height * 0.35;
    final trunkTop = size.height - trunkH;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - trunkW / 2, trunkTop, trunkW, trunkH),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawCircle(
        Offset(cx + size.width * 0.06, trunkTop - size.width * 0.18),
        size.width * 0.44, Paint()..color = const Color(0xFF1B5E20));
    canvas.drawCircle(
        Offset(cx, trunkTop - size.width * 0.22),
        size.width * 0.44, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(
        Offset(cx - size.width * 0.08, trunkTop - size.width * 0.32),
        size.width * 0.28, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        Offset(cx + size.width * 0.14, trunkTop - size.width * 0.26),
        size.width * 0.22, Paint()..color = const Color(0xFF43A047));
  }

  void _drawPalmTree(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final trunkPath = Path()
      ..moveTo(cx, size.height)
      ..quadraticBezierTo(cx + size.width * 0.18, size.height * 0.55,
          cx - size.width * 0.08, size.height * 0.22);
    canvas.drawPath(trunkPath, Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(trunkPath, Paint()
      ..color = const Color(0xFFBCAAA4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round);
    final tipX = cx - size.width * 0.08;
    final tipY = size.height * 0.22;
    for (final angle in [-80.0, -45.0, -10.0, 25.0, 60.0, 95.0, 130.0]) {
      final rad  = angle * math.pi / 180;
      final len  = size.width * 0.55;
      final ex   = tipX + len * math.cos(rad);
      final ey   = tipY + len * math.sin(rad);
      final ctrlX = tipX + len * 0.5 * math.cos(rad) +
          math.sin(rad) * size.width * 0.08;
      final ctrlY = tipY + len * 0.5 * math.sin(rad) -
          math.cos(rad).abs() * size.width * 0.12;
      final frond = Path()
        ..moveTo(tipX, tipY)
        ..quadraticBezierTo(ctrlX, ctrlY, ex, ey);
      canvas.drawPath(frond, Paint()
        ..color = const Color(0xFF33691E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..strokeCap = StrokeCap.round);
      canvas.drawPath(frond, Paint()
        ..color = const Color(0xFF558B2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(
        Offset(tipX + size.width * 0.08, tipY + size.height * 0.05),
        size.width * 0.07, Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(
        Offset(tipX - size.width * 0.06, tipY + size.height * 0.07),
        size.width * 0.06, Paint()..color = const Color(0xFF6D4C41));
  }

  void _drawPineTree(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - size.width * 0.09, size.height * 0.72,
              size.width * 0.18, size.height * 0.28),
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF5D4037),
    );
    for (final layer in [
      (yB: size.height * 0.80, hW: size.width * 0.50, c: const Color(0xFF1B5E20)),
      (yB: size.height * 0.62, hW: size.width * 0.38, c: const Color(0xFF2E7D32)),
      (yB: size.height * 0.44, hW: size.width * 0.26, c: const Color(0xFF388E3C)),
      (yB: size.height * 0.26, hW: size.width * 0.15, c: const Color(0xFF43A047)),
    ]) {
      final tipY = layer.yB - size.height * 0.25;
      final path = Path()
        ..moveTo(cx, tipY)
        ..lineTo(cx - layer.hW, layer.yB)
        ..lineTo(cx + layer.hW, layer.yB)
        ..close();
      canvas.drawPath(path, Paint()..color = layer.c);
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter old) => old.type != type;
}