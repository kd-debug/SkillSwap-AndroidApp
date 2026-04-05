import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> with TickerProviderStateMixin {
  // Accelerometer
  double _accX = 0, _accY = 0, _accZ = 0;
  // Gyroscope
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  StreamSubscription? _accSubscription;
  StreamSubscription? _gyroSubscription;

  // Shake detection
  static const double _shakeThreshold = 15.0;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(_shakeAnimController);

    _accSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((AccelerometerEvent e) {
      if (!mounted) return;
      setState(() {
        _accX = e.x;
        _accY = e.y;
        _accZ = e.z;
      });
      _detectShake(e.x, e.y, e.z);
    });

    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((GyroscopeEvent e) {
      if (!mounted) return;
      setState(() {
        _gyroX = e.x;
        _gyroY = e.y;
        _gyroZ = e.z;
      });
    });
  }

  void _detectShake(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    final force = magnitude - 9.8;
    if (force > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > const Duration(milliseconds: 800)) {
        _lastShakeTime = now;
        setState(() => _shakeCount++);
        _shakeAnimController.forward(from: 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📳 Shake detected! (×$_shakeCount)'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _accSubscription?.cancel();
    _gyroSubscription?.cancel();
    _shakeAnimController.dispose();
    super.dispose();
  }

  String _getActivityLevel() {
    final magnitude = sqrt(_accX * _accX + _accY * _accY + _accZ * _accZ);
    if (magnitude < 5) return '😴 Calm';
    if (magnitude < 12) return '🚶 Active';
    return '🏃 Vigorous';
  }

  Color _activityColor() {
    final magnitude = sqrt(_accX * _accX + _accY * _accY + _accZ * _accZ);
    if (magnitude < 5) return Colors.green;
    if (magnitude < 12) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Sensor Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 8),
                  SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityCard(),
            const SizedBox(height: 16),
            _buildSensorCard(
              title: '📡 Accelerometer',
              subtitle: 'Linear acceleration (m/s²)',
              icon: Icons.speed,
              color: Colors.tealAccent,
              values: {'X': _accX, 'Y': _accY, 'Z': _accZ},
              rangeMin: -20,
              rangeMax: 20,
            ),
            const SizedBox(height: 16),
            _buildSensorCard(
              title: '🌀 Gyroscope',
              subtitle: 'Angular velocity (rad/s)',
              icon: Icons.rotate_90_degrees_ccw,
              color: Colors.purpleAccent,
              values: {'X': _gyroX, 'Y': _gyroY, 'Z': _gyroZ},
              rangeMin: -10,
              rangeMax: 10,
            ),
            const SizedBox(height: 16),
            _buildShakeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _activityColor().withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _activityColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_run, color: _activityColor(), size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity Level',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                _getActivityLevel(),
                style: TextStyle(
                  color: _activityColor(),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Shakes: $_shakeCount',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Map<String, double> values,
    required double rangeMin,
    required double rangeMax,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          ...values.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildAxisBar(
              axis: e.key,
              value: e.value,
              color: color,
              rangeMin: rangeMin,
              rangeMax: rangeMax,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAxisBar({
    required String axis,
    required double value,
    required Color color,
    required double rangeMin,
    required double rangeMax,
  }) {
    final normalized =
        ((value - rangeMin) / (rangeMax - rangeMin)).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(axis,
              style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: normalized,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.5), color],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
                color: color, fontSize: 12, fontFamily: 'monospace'),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildShakeCard() {
    return ScaleTransition(
      scale: _shakeAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.vibration, color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 12),
            const Text('Shake Detection',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$_shakeCount',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text('shakes detected',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _shakeCount = 0),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
