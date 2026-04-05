import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_page.dart';
import 'login_page.dart';
import 'profile_page.dart';

// ─── Decoration types ─────────────────────────────────────────────────────────

enum CubeDecoration { none, oakTree, palmTree, pineTree }

extension CubeDecorationLabel on CubeDecoration {
  String get label {
    switch (this) {
      case CubeDecoration.none:     return 'Empty';
      case CubeDecoration.oakTree:  return 'Oak Tree';
      case CubeDecoration.palmTree: return 'Palm Tree';
      case CubeDecoration.pineTree: return 'Pine Tree';
    }
  }

  IconData get icon {
    switch (this) {
      case CubeDecoration.none:     return Icons.crop_square;
      case CubeDecoration.oakTree:  return Icons.park;
      case CubeDecoration.palmTree: return Icons.nature;
      case CubeDecoration.pineTree: return Icons.forest;
    }
  }
}

// ─── Slot model ───────────────────────────────────────────────────────────────

class PlatformSlot {
  final int col; // 0 = left, cols-1 = right
  final int row; // 0 = front, rows-1 = back
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
    with WidgetsBindingObserver {
  int _totalCoins = 0;

  // Grid dimensions — change these to add more slots
  static const int _cols = 5;
  static const int _rows = 2;

  late List<PlatformSlot> _slots;

  // Populated after each paint — maps "col_row" → screen-space Offset of
  // that slot's centre on the platform top face
  Map<String, Offset> _slotCenters = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTotalCoins();
    _slots = [
      for (int r = 0; r < _rows; r++)
        for (int c = 0; c < _cols; c++)
          PlatformSlot(col: c, row: r),
    ];
  }

  @override
  void dispose() {
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
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalCoins = prefs.getInt('totalCoins') ?? 0);
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
        onPlace: (col, row, dec) {
          setState(() {
            _slots
                .firstWhere((s) => s.col == col && s.row == row)
                .decoration = dec;
          });
        },
      ),
    );
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
        title: Image.asset('assets/images/sWorld_Logo.png', height: 40),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF5CE1E6)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Platform + decorations ────────────────────────────────────
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Original platform — visually untouched
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _IsometricPlatformPainter(
                                  cols: _cols,
                                  rows: _rows,
                                  onSlotCenters: (centers) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(
                                                () => _slotCenters = centers);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),

                            // Decoration widgets — one per occupied slot
                            ..._slots
                                .where((s) =>
                            s.decoration != CubeDecoration.none)
                                .map((slot) {
                              final key = '${slot.col}_${slot.row}';
                              final center = _slotCenters[key];
                              if (center == null) {
                                return const SizedBox.shrink();
                              }

                              // Scale tree size to slot width so they fit neatly
                              final treeH = h * 0.55;
                              final treeW = w / _cols * 0.85;

                              return Positioned(
                                left: center.dx - treeW / 2,
                                top:  center.dy - treeH,
                                child: SizedBox(
                                  width: treeW,
                                  height: treeH,
                                  child: CustomPaint(
                                    painter: _DecorationPainter(
                                        type: slot.decoration),
                                  ),
                                ),
                              );
                            }),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _showDecorateBottomSheet,
                  icon: const Icon(Icons.design_services, size: 20),
                  label: const Text(
                    'Decorate',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
              padding: EdgeInsets.only(bottom: 24.0, top: 8),
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

  // ── Drawer ────────────────────────────────────────────────────────────────

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
                Text(widget.username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
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
                          builder: (context) => const ActivityPage()),
                    ).then((_) => _loadTotalCoins());
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )),
      tileColor: isActive ? const Color(0xFF1A2B4A) : null,
      onTap: onTap,
    );
  }
}

// ─── Decorate bottom sheet ────────────────────────────────────────────────────

class _DecorateSheet extends StatefulWidget {
  final List<PlatformSlot> slots;
  final int cols;
  final int rows;
  final void Function(int col, int row, CubeDecoration dec) onPlace;

  const _DecorateSheet({
    required this.slots,
    required this.cols,
    required this.rows,
    required this.onPlace,
  });

  @override
  State<_DecorateSheet> createState() => _DecorateSheetState();
}

class _DecorateSheetState extends State<_DecorateSheet> {
  CubeDecoration? _selectedDec;

  static const _plants = [
    CubeDecoration.oakTree,
    CubeDecoration.palmTree,
    CubeDecoration.pineTree,
  ];

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
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF5CE1E6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Icon(Icons.design_services, color: Color(0xFF5CE1E6), size: 24),
              SizedBox(width: 12),
              Text('Decorate Platform',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          const Divider(
              color: Color(0xFF5CE1E6), height: 16, indent: 20, endIndent: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: pick a decoration
                  const Text('Step 1 — Pick a plant',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    children: _plants.map((dec) {
                      final selected = _selectedDec == dec;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDec = dec),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF5CE1E6).withOpacity(0.15)
                                  : const Color(0xFF1A2B4A).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF5CE1E6)
                                    : const Color(0xFF5CE1E6).withOpacity(0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(children: [
                              Icon(dec.icon,
                                  color: const Color(0xFF5CE1E6), size: 28),
                              const SizedBox(height: 8),
                              Text(dec.label,
                                  style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF5CE1E6)
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Step 2: pick a slot
                  Text('Step 2 — Choose a slot',
                      style: TextStyle(
                          color: _selectedDec == null
                              ? Colors.white30
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    'Row 1 = front of platform  ·  Row ${widget.rows} = back',
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Rows drawn back-to-front to match the platform's perspective
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
                          final canTap = _selectedDec != null;
                          return Expanded(
                            child: GestureDetector(
                              onTap: canTap
                                  ? () {
                                widget.onPlace(c, r, _selectedDec!);
                                Navigator.pop(context);
                              }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.fromLTRB(0, 0, 6, 0),
                                height: 52,
                                decoration: BoxDecoration(
                                  color: occupied
                                      ? const Color(0xFF388E3C).withOpacity(0.2)
                                      : const Color(0xFF1A2B4A).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: occupied
                                        ? const Color(0xFF66BB6A)
                                        : canTap
                                        ? const Color(0xFF5CE1E6)
                                        .withOpacity(0.45)
                                        : Colors.white12,
                                    width: occupied ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      occupied
                                          ? slot.decoration.icon
                                          : Icons.add,
                                      color: occupied
                                          ? const Color(0xFF66BB6A)
                                          : canTap
                                          ? Colors.white38
                                          : Colors.white12,
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

                  const SizedBox(height: 8),

                  // Clear all
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
            ),
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
}

// ─── Platform painter ─────────────────────────────────────────────────────────
//
// Visually IDENTICAL to the original _IsometricPlatformPainter.
// The only addition is slot centre computation at the end of paint().
//
// The top face is a parallelogram with four corners:
//   p1 = left vertex      p2 = back-left vertex
//   p3 = back-right       p4 = front-right
//
// Slot centres are computed by bilinear interpolation inside this quad:
//   col axis: p1 → p4  (left to right)
//   row axis: p1 → p2  (front to back)
//
// Cell centre fraction = (index + 0.5) / count

class _IsometricPlatformPainter extends CustomPainter {
  final int cols;
  final int rows;
  final void Function(Map<String, Offset> centers)? onSlotCenters;

  const _IsometricPlatformPainter({
    this.cols = 5,
    this.rows = 2,
    this.onSlotCenters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Original vertices — do not change these ───────────────────────────
    final p1  = Offset(w * 0.08, h * 0.46);
    final p2  = Offset(w * 0.37, h * 0.13);
    final p3  = Offset(w * 0.92, h * 0.30);
    final p4  = Offset(w * 0.63, h * 0.62);

    final p1b = Offset(w * 0.08, h * 0.76);
    final p4b = Offset(w * 0.63, h * 0.92);
    final p3b = Offset(w * 0.92, h * 0.60);

    // ── Paths — original ──────────────────────────────────────────────────
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

    // ── Paints — original ─────────────────────────────────────────────────
    final topRect = Rect.fromPoints(p2, p4);
    final topPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(topRect);

    final frontPaint = Paint()..color = const Color(0xFF8D6E63);
    final rightPaint = Paint()..color = const Color(0xFF5D4037);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;

    // ── Draw — original order ─────────────────────────────────────────────
    canvas.drawPath(frontPath, frontPaint);
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(topPath,   topPaint);

    _drawGrassStrokes(canvas, p1, p2, p3, p4, w, h);
    _drawDirtStrokes(canvas, p1, p4, p4b, p1b, isRight: false);
    _drawDirtStrokes(canvas, p4, p3, p3b, p4b, isRight: true);

    edgePaint.color = const Color(0xFF1B5E20);
    canvas.drawPath(topPath, edgePaint);
    edgePaint.color = const Color(0xFF3E2723);
    canvas.drawPath(frontPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
    canvas.drawLine(p4, p4b, edgePaint);

    // ── Invisible slot grid on top face ───────────────────────────────────
    //
    // Parameterise the top-face parallelogram:
    //   tc = fraction along p1→p4 (column, left→right)
    //   tr = fraction along p1→p2 (row, front→back)
    //
    // Each slot centre = p1 + (p4-p1)*tc + (p2-p1)*tr

    final slotCenters = <String, Offset>{};
    final colVec = p4 - p1;
    final rowVec = p2 - p1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tc = (c + 0.5) / cols;
        final tr = (r + 0.5) / rows;
        slotCenters['${c}_$r'] = p1 + colVec * tc + rowVec * tr;
      }
    }

    onSlotCenters?.call(slotCenters);
  }

  // ── Original grass strokes — untouched ────────────────────────────────────
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

    const int rowCount = 5;
    const int colCount = 8;

    for (int row = 1; row < rowCount; row++) {
      final t = row / rowCount;
      final leftEdge  = Offset.lerp(p1, p2, t)!;
      final rightEdge = Offset.lerp(p4, p3, t)!;

      final path = Path();
      bool first = true;

      for (int col = 0; col <= colCount; col++) {
        final s = col / colCount;
        final base = Offset.lerp(leftEdge, rightEdge, s)!;

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

  // ── Original dirt strokes — untouched ─────────────────────────────────────
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

      final path = Path();
      const int segments = 10;
      path.moveTo(left.dx, left.dy);

      for (int s = 1; s <= segments; s++) {
        final u    = s / segments;
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

// ─── Decoration painter ───────────────────────────────────────────────────────

class _DecorationPainter extends CustomPainter {
  final CubeDecoration type;
  const _DecorationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case CubeDecoration.oakTree:  _drawOakTree(canvas, size);  break;
      case CubeDecoration.palmTree: _drawPalmTree(canvas, size); break;
      case CubeDecoration.pineTree: _drawPineTree(canvas, size); break;
      case CubeDecoration.none:     break;
    }
  }

  void _drawOakTree(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final trunkW = size.width * 0.16;
    final trunkH = size.height * 0.35;
    final trunkTop = size.height - trunkH;

    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - trunkW / 2, trunkTop, trunkW, trunkH),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Shadow layer
    canvas.drawCircle(
      Offset(cx + size.width * 0.06, trunkTop - size.width * 0.18),
      size.width * 0.44,
      Paint()..color = const Color(0xFF1B5E20),
    );
    // Main canopy
    canvas.drawCircle(
      Offset(cx, trunkTop - size.width * 0.22),
      size.width * 0.44,
      Paint()..color = const Color(0xFF2E7D32),
    );
    // Highlight clusters
    canvas.drawCircle(
      Offset(cx - size.width * 0.08, trunkTop - size.width * 0.32),
      size.width * 0.28,
      Paint()..color = const Color(0xFF388E3C),
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.14, trunkTop - size.width * 0.26),
      size.width * 0.22,
      Paint()..color = const Color(0xFF43A047),
    );
  }

  void _drawPalmTree(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final trunkPath = Path()
      ..moveTo(cx, size.height)
      ..quadraticBezierTo(
        cx + size.width * 0.18, size.height * 0.55,
        cx - size.width * 0.08, size.height * 0.22,
      );

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
      final rad = angle * math.pi / 180;
      final len = size.width * 0.55;
      final ex = tipX + len * math.cos(rad);
      final ey = tipY + len * math.sin(rad);
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
        size.width * 0.07,
        Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(
        Offset(tipX - size.width * 0.06, tipY + size.height * 0.07),
        size.width * 0.06,
        Paint()..color = const Color(0xFF6D4C41));
  }

  void _drawPineTree(Canvas canvas, Size size) {
    final cx = size.width / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - size.width * 0.09, size.height * 0.72,
            size.width * 0.18, size.height * 0.28),
        const Radius.circular(2),
      ),
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