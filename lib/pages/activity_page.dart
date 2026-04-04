import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _isTracking = false;
  int _stepCount = 0;
  double _distance = 0.0; // in kilometers
  double _lastAcceleration = 0.0;
  DateTime? _startTime;
  int _totalCoins = 0;

  // Step detection parameters
  static const double STEP_THRESHOLD = 12.0; // Acceleration threshold for step detection
  static const double STEP_LENGTH = 0.000762; // Average step length in km (76.2 cm)

  @override
  void initState() {
    super.initState();
    _initializeStepCounter();
    _loadTotalCoins();
  }

  Future<void> _loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCoins = prefs.getInt('totalCoins') ?? 0;
    });
  }

  Future<void> _saveTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalCoins', _totalCoins);
  }

  void _initializeStepCounter() {
    // Listen to accelerometer for step detection
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_isTracking) return;
      
      // Calculate magnitude of acceleration
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Detect step when acceleration crosses threshold
      if (_lastAcceleration < STEP_THRESHOLD && magnitude >= STEP_THRESHOLD) {
        _detectStep();
      }
      
      _lastAcceleration = magnitude;
    });
  }

  void _detectStep() {
    if (mounted && _isTracking) {
      setState(() {
        _stepCount++;
        _distance += STEP_LENGTH;
      });
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _stepCount = 0;
      _distance = 0.0;
      _startTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Step tracking started!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inMinutes
        : 0;

    // Calculate coins earned - new formula: (steps ÷ 100) × distance
    final coinsEarned = (_stepCount / 100).round();

    // Update total coins
    if (coinsEarned > 0) {
      setState(() {
        _totalCoins += coinsEarned;
      });
      _saveTotalCoins();
    }

    // Show coin reward dialog
    _showCoinRewardDialog(coinsEarned);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Tracking stopped! $_stepCount steps, ${_distance.toStringAsFixed(2)} km in ${duration}min'
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCoinRewardDialog(int coinsEarned) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: '🎉 Coins Earned!',
      desc: 'You earned $coinsEarned coins!\n\nSteps: $_stepCount\nDistance: ${_distance.toStringAsFixed(2)} km\nTotal Coins: $_totalCoins',
      btnOkOnPress: () {},
      btnOkText: 'Awesome!',
      btnOkColor: const Color(0xFF5CE1E6),
    ).show();
  }

  String _formatDistance(double distance) {
    return '${distance.toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5CE1E6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Activity Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A2B4A),
                    const Color(0xFF0A1628),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5CE1E6),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 48,
                    color: Color(0xFF5CE1E6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Step Tracker',
                    style: TextStyle(
                      color: Color(0xFF5CE1E6),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$_stepCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Steps',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _formatDistance(_distance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Distance',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_isTracking && _startTime != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CE1E6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF5CE1E6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tracking Active',
                            style: TextStyle(
                              color: Color(0xFF5CE1E6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Control Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: _toggleTracking,
                icon: _isTracking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1628)),
                  ),
                )
                    : const Icon(Icons.directions_run, size: 20),
                label: Text(
                  _isTracking ? 'Stop Tracking' : "Let's run",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking
                      ? Colors.red.withOpacity(0.8)
                      : const Color(0xFF5CE1E6),
                  foregroundColor: const Color(0xFF0A1628),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isTracking ? Icons.directions_walk : Icons.info_outline,
                      size: 64,
                      color: _isTracking
                          ? const Color(0xFF5CE1E6)
                          : Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTracking ? 'Keep Walking!' : 'Step Tracking',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTracking
                          ? 'Your steps are being counted automatically'
                          : 'Tap "Let\'s run" to start tracking your steps',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isTracking) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Uses device accelerometer to detect steps',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}