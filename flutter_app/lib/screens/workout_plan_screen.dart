import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/exercise.dart';
import 'day_workout_screen.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  late List<DayWorkout> _days;

  @override
  void initState() {
    super.initState();
    _days = getDefaultWorkoutPlan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Text(
                      'GO',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Plan',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a day to customize exercises & targets',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // ── Day Cards ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  return _DayCard(
                    dayWorkout: day,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a1, a2) =>
                              DayWorkoutScreen(dayWorkout: day),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration:
                              const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ).animate(delay: Duration(milliseconds: 150 + index * 80))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.2, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Card ──────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final DayWorkout dayWorkout;
  final VoidCallback onTap;

  const _DayCard({required this.dayWorkout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF00FF88),
      const Color(0xFF3742FA),
      const Color(0xFFFF8C42),
      const Color(0xFFFF4757),
      const Color(0xFF6C5CE7),
      const Color(0xFF00CEC9),
      const Color(0xFFF368E0),
    ];
    final accentColor = colors[(dayWorkout.day - 1) % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: accentColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.06),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            // Day number badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${dayWorkout.day}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${dayWorkout.day}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoPill(Icons.timer_outlined,
                          '${dayWorkout.totalDurationMinutes}m', accentColor),
                      const SizedBox(width: 10),
                      _infoPill(Icons.fitness_center_rounded,
                          '${dayWorkout.totalExercises} exercises', accentColor),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
