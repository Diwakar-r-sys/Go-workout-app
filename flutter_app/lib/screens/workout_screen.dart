import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_state.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutState>().startWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutState>(
      builder: (context, state, _) {
        if (state.workoutComplete) {
          return _CompletionView(state: state);
        }
        return _ActiveWorkoutView(state: state);
      },
    );
  }
}

class _ActiveWorkoutView extends StatelessWidget {
  final WorkoutState state;
  const _ActiveWorkoutView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 28),
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
                      'LIVE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Status
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: state.poseDetected
                      ? const Color(0xFF00FF88).withOpacity(0.15)
                      : const Color(0xFFFF4757).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  state.statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: state.poseDetected
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF4757),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Rep counter
              AnimatedScale(
                scale: state.repJustCounted ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${state.repCount}',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: state.repJustCounted
                        ? const Color(0xFF00FF88)
                        : Colors.white,
                    height: 1.0,
                  ),
                ),
              ),

              Text(
                '/ ${state.targetReps}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),

              const SizedBox(height: 24),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progressFraction,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00FF88)),
                ),
              ),

              const SizedBox(height: 24),

              // Form tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.formTip,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Finish early button
              TextButton(
                onPressed: () => state.finishEarly(),
                child: Text(
                  'Finish Early',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final WorkoutState state;
  const _CompletionView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'Great Work!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00FF88),
                ),
              ),
              const SizedBox(height: 32),

              // Stats row
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF00FF88).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                        label: 'Reps', value: '${state.finalReps}', icon: '💪'),
                    _StatItem(
                        label: 'Time',
                        value: state.formattedDuration,
                        icon: '⏱️'),
                    _StatItem(
                        label: 'Calories',
                        value: '${state.estimatedCalories}',
                        icon: '🔥'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60)),
                  ),
                  child: const Text('Done',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
