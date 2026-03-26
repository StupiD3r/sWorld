import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'jungle_demo_page.dart';
import '../widgets/jungle_platform.dart';

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
  String _lastPlatformAction = 'No interaction yet';
  int _platformTapCount = 0;
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

  @override
  void dispose() {
    super.dispose();
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
                  // Coin Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
