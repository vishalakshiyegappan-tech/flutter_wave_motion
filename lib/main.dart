import 'package:flutter/material.dart';

void main() {
  runApp(const WaveApp());
}

class WaveApp extends StatelessWidget {
  const WaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECG Wave Motion',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const WaveScreen(),
    );
  }
}

class WaveScreen extends StatefulWidget {
  const WaveScreen({super.key});

  @override
  State<WaveScreen> createState() => _WaveScreenState();
}

class _WaveScreenState extends State<WaveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool isPlaying = false;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPlayPressed() {
    setState(() {
      hasStarted = true;
      if (isPlaying) {
        _ctrl.stop();
        isPlaying = false;
      } else {
        _ctrl.repeat();
        isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('ECG Wave Motion'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: EcgPainter(_ctrl.value, hasStarted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            child: ElevatedButton(
              onPressed: _onPlayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isPlaying ? 'Pause' : 'Play'),
            ),
          ),
        ],
      ),
    );
  }
}

// Draws a heartbeat style line on a grid background.
// The shape repeats - one "beat" every cycleWidth pixels.
class EcgPainter extends CustomPainter {
  final double t; // animation value, 0 -> 1, repeating
  final bool hasStarted;

  EcgPainter(this.t, this.hasStarted);

  // points that make up one heartbeat - x is fraction across the beat,
  // y is how far up/down from the middle line (-1 = top, 1 = bottom)
  final beatPoints = const [
    Offset(0.00, 0),
    Offset(0.12, 0),
    Offset(0.18, -0.15),
    Offset(0.24, 0),
    Offset(0.30, 0),
    Offset(0.34, 0.25),
    Offset(0.38, -1),
    Offset(0.42, 1),
    Offset(0.46, -0.1),
    Offset(0.50, 0),
    Offset(0.62, 0),
    Offset(0.70, -0.35),
    Offset(0.78, 0),
    Offset(1.00, 0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);

    final midY = size.height / 2;

    if (!hasStarted) {
      final flatLine = Paint()
        ..color = Colors.greenAccent
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), flatLine);
      return;
    }

    final amp = size.height * 0.28;
    final beatWidth = size.width * 0.7;
    final offset = t * beatWidth;

    // pen position stays in the middle of the screen
    final penX = size.width / 2;
    final penY = midY + heightAt(((penX + offset) % beatWidth) / beatWidth) * amp;

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, midY);

    for (double x = 0; x <= penX; x++) {
      final pos = ((x + offset) % beatWidth) / beatWidth;
      final y = midY + heightAt(pos) * amp;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, linePaint);

    // glowing tip where the line is currently being drawn
    canvas.drawCircle(
      Offset(penX, penY),
      10,
      Paint()
        ..color = Colors.greenAccent.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(Offset(penX, penY), 3, Paint()..color = Colors.white);
  }

  void drawGrid(Canvas canvas, Size size) {
    final gridLine = Paint()
      ..color = Colors.green.withOpacity(0.12)
      ..strokeWidth = 0.5;

    const gap = 24.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridLine);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLine);
    }
  }

  // finds the y value for a position between 0 and 1 along the beat,
  // by interpolating between the nearest two points in beatPoints
  double heightAt(double pos) {
    for (var i = 0; i < beatPoints.length - 1; i++) {
      final a = beatPoints[i];
      final b = beatPoints[i + 1];
      if (pos >= a.dx && pos <= b.dx) {
        final span = b.dx - a.dx;
        final ratio = span == 0 ? 0.0 : (pos - a.dx) / span;
        return a.dy + (b.dy - a.dy) * ratio;
      }
    }
    return 0;
  }

  @override
  bool shouldRepaint(EcgPainter old) =>
      old.t != t || old.hasStarted != hasStarted;
}