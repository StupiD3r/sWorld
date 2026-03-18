import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final List<ActivityLog> _activityLogs = [];
  bool _isRunning = false;

  void _addActivityLog(String activity) {
    setState(() {
      _activityLogs.insert(0, ActivityLog(
        timestamp: DateTime.now(),
        activity: activity,
      ));
    });
  }

  void _startRunning() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
    });
    
    _addActivityLog('🏃‍♂️ Started running session');
    
    // Simulate running activities
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addActivityLog('📊 Distance: 0.5 km');
      }
    });
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _addActivityLog('💓 Heart rate: 125 bpm');
      }
    });
    
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _addActivityLog('🔥 Calories burned: 45 kcal');
      }
    });
    
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _addActivityLog('🏁 Running session completed');
        setState(() {
          _isRunning = false;
        });
      }
    });
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
            // Activity Image Placeholder
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Color(0xFF5CE1E6),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Activity Image',
                      style: TextStyle(
                        color: Color(0xFF5CE1E6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Image will be placed here',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Let's Run Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _startRunning,
                icon: _isRunning
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
                  _isRunning ? 'Running...' : "Let's run",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE1E6),
                  foregroundColor: const Color(0xFF0A1628),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(0xFF5CE1E6).withOpacity(0.5),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Activity Logs Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: Color(0xFF5CE1E6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Activity Logs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_activityLogs.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activityLogs.clear();
                        });
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Color(0xFF5CE1E6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Scrollable Activity Logs
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2B4A).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5CE1E6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: _activityLogs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No activities yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap "Let\'s run" to start',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _activityLogs.length,
                        itemBuilder: (context, index) {
                          final log = _activityLogs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1628).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF5CE1E6).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.activity,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(log.timestamp),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ActivityLog {
  final DateTime timestamp;
  final String activity;

  ActivityLog({
    required this.timestamp,
    required this.activity,
  });
}
