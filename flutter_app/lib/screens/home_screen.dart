import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'workout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Animated background blobs
          const _BackgroundBlobs(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Logo badge
                  _LogoBadge()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.3, end: 0),

                  const SizedBox(height: 16),

                  // Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                      children: [
                        TextSpan(text: 'Workout'),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: Color(0xFF00FF88)),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 6),

                  Text(
                    'AI-Powered Rep Counter',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // Feature card
                  _FeatureCard()
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 16),

                  // Exercise card
                  _ExerciseCard()
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: 0.2, end: 0),

                  const SizedBox(height: 28),

                  // Steps
                  _StepsList()
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // Start button
                  _StartButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, a1, a2) => const WorkoutScreen(),
                          transitionsBuilder: (_, anim, __, child) {
                            return FadeTransition(opacity: anim, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      '📷 Camera access required for body tracking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background animated blobs ─────────────────────────
class _BackgroundBlobs extends StatefulWidget {
  const _BackgroundBlobs();
  @override
  State<_BackgroundBlobs> createState() => _BackgroundBlobsState();
}

class _BackgroundBlobsState extends State<_BackgroundBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Stack(
          children: [
            Positioned(
              top: -100 + t * 30,
              left: -100 + t * 20,
              child: _Blob(color: const Color(0xFF00FF88), size: 380),
            ),
            Positioned(
              bottom: -80 + t * -20,
              right: -80 + t * 20,
              child: _Blob(color: const Color(0xFF3742FA), size: 340),
            ),
            Positioned(
              top: 300 + t * 40,
              left: 100 + t * -20,
              child: _Blob(color: const Color(0xFFFF4757), size: 240),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
      ),
    );
  }
}

// ── Logo badge ────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: const Text(
        'GO',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Detection',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Your camera tracks body movement in real-time using on-device AI',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12121E), Color(0xFF1E1E3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          const Text('💪', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Push-Ups',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Target: 15 reps',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8888AA))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('AI',
                style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Steps list ────────────────────────────────────────
class _StepsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      'Allow camera access',
      'Position yourself in push-up stance',
      'The AI counts your reps automatically',
    ];
    return Column(
      children: steps.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF00FF88),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${e.key + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(e.value,
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Start button ──────────────────────────────────────
class _StartButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF88),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
          elevation: 0,
          shadowColor: const Color(0xFF00FF88).withOpacity(0.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 22),
            SizedBox(width: 8),
            Text('Start Workout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
