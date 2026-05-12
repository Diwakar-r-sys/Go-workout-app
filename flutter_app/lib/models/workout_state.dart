import 'package:flutter/foundation.dart';

// Push-up state machine phases
enum PushUpPhase { ready, down, up }

class WorkoutState extends ChangeNotifier {
  // ── Rep counting ──────────────────────────────────
  int repCount = 0;
  int targetReps = 15;
  PushUpPhase phase = PushUpPhase.ready;

  // ── Angle tracking ────────────────────────────────
  double? leftAngle;
  double? rightAngle;
  double? avgAngle;

  // ── Pose detection ────────────────────────────────
  bool poseDetected = false;
  bool repJustCounted = false;
  DateTime? lastRepTime;

  // ── Workout session ───────────────────────────────
  DateTime? workoutStartTime;
  bool workoutComplete = false;
  int finalReps = 0;
  int finalDurationSeconds = 0;

  // ── Thresholds ────────────────────────────────────
  static const double angleDown = 90.0;   // arms bent
  static const double angleUp   = 155.0;  // arms extended

  // ─────────────────────────────────────────────────
  // Start workout session
  // ─────────────────────────────────────────────────
  void startWorkout() {
    repCount = 0;
    phase = PushUpPhase.ready;
    poseDetected = false;
    repJustCounted = false;
    workoutComplete = false;
    workoutStartTime = DateTime.now();
    leftAngle = null;
    rightAngle = null;
    avgAngle = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  // Update angles from pose detection
  // ─────────────────────────────────────────────────
  void updateAngles({
    double? left,
    double? right,
    required bool detected,
  }) {
    poseDetected = detected;
    leftAngle = left;
    rightAngle = right;

    if (!detected) {
      avgAngle = null;
      notifyListeners();
      return;
    }

    // Average available angles
    final angles = [left, right].whereType<double>().toList();
    if (angles.isEmpty) {
      avgAngle = null;
      notifyListeners();
      return;
    }
    avgAngle = angles.reduce((a, b) => a + b) / angles.length;

    // ── State machine ────────────────────────────────
    final angle = avgAngle!;
    final now = DateTime.now();

    if (phase == PushUpPhase.ready || phase == PushUpPhase.up) {
      if (angle < angleDown) {
        phase = PushUpPhase.down;
      }
    } else if (phase == PushUpPhase.down) {
      if (angle > angleUp) {
        // Debounce: 300ms between reps
        final canCount = lastRepTime == null ||
            now.difference(lastRepTime!).inMilliseconds > 300;
        if (canCount) {
          repCount++;
          lastRepTime = now;
          phase = PushUpPhase.up;
          repJustCounted = true;

          // Check if target reached
          if (repCount >= targetReps) {
            _finishWorkout();
          }
        }
      }
    }

    notifyListeners();

    // Clear rep flash after 600ms
    if (repJustCounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        repJustCounted = false;
        notifyListeners();
      });
    }
  }

  // ─────────────────────────────────────────────────
  void _finishWorkout() {
    workoutComplete = true;
    finalReps = repCount;
    final elapsed = workoutStartTime != null
        ? DateTime.now().difference(workoutStartTime!).inSeconds
        : 0;
    finalDurationSeconds = elapsed;
  }

  void finishEarly() {
    _finishWorkout();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────
  double get progressFraction => (repCount / targetReps).clamp(0.0, 1.0);

  int get estimatedCalories => (finalReps * 0.4).round();

  String get formattedDuration {
    final s = finalDurationSeconds;
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m ${s % 60}s';
  }

  String get statusText {
    if (!poseDetected) return '🔍 SEARCHING';
    switch (phase) {
      case PushUpPhase.ready: return '⚡ GET READY';
      case PushUpPhase.down:  return '🔴 HOLD DOWN';
      case PushUpPhase.up:    return '🟢 PUSH UP ↑';
    }
  }

  String get formTip {
    if (!poseDetected) return 'Move into frame — full body visible';
    switch (phase) {
      case PushUpPhase.ready: return 'Lower your body to start counting reps';
      case PushUpPhase.down:  return 'Good! Now push up with full arm extension';
      case PushUpPhase.up:    return 'Lower yourself again for next rep';
    }
  }
}
