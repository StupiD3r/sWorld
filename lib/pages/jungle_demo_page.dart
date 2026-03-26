import 'package:flutter/material.dart';
import '../widgets/jungle_platform.dart';

class JungleDemoPage extends StatefulWidget {
  const JungleDemoPage({super.key});

  @override
  State<JungleDemoPage> createState() => _JungleDemoPageState();
}

class _JungleDemoPageState extends State<JungleDemoPage> {
  String _lastTapPosition = 'No tap yet';
  int _tapCount = 0;

  void _handleTopSurfaceTap(Offset position) {
    setState(() {
      _tapCount++;
      _lastTapPosition = 'Tap #$_tapCount at (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})';
    });
  }

  void _handleLongPress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Long press detected! Ready for object placement.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue background
      appBar: AppBar(
        title: const Text('Jungle Platform Demo'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Instructions panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[700]?.withOpacity(0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controls:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Swipe left/right: Rotate platform\n'
                  '• Swipe up/down: Tilt platform\n'
                  '• Pinch: Zoom in/out\n'
                  '• Tap surface: Place objects\n'
                  '• Long press: Special actions',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lastTapPosition,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Platform display area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: JunglePlatform(
                width: 250,
                height: 150,
                depth: 60,
                onTopSurfaceTap: _handleTopSurfaceTap,
                onLongPress: _handleLongPress,
              ),
            ),
          ),
          
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[800]?.withOpacity(0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _tapCount = 0;
                      _lastTapPosition = 'No tap yet';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
