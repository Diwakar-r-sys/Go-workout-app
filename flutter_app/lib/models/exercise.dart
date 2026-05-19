import 'package:flutter/foundation.dart';

enum ExerciseType { reps, duration }

class Exercise {
  final String id;
  final String name;
  final String emoji;
  final ExerciseType type;
  int targetReps;       // for rep-based exercises
  int targetSeconds;    // for duration-based exercises
  int? targetCount;     // optional target count for timed exercises (e.g., 30 mountain climbers)

  Exercise({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    this.targetReps = 15,
    this.targetSeconds = 30,
    this.targetCount,
  });

  Exercise copyWith({
    int? targetReps,
    int? targetSeconds,
    int? targetCount,
  }) {
    return Exercise(
      id: id,
      name: name,
      emoji: emoji,
      type: type,
      targetReps: targetReps ?? this.targetReps,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      targetCount: targetCount ?? this.targetCount,
    );
  }

  String get displayValue {
    if (type == ExerciseType.duration) {
      final mins = targetSeconds ~/ 60;
      final secs = targetSeconds % 60;
      final time = mins > 0
          ? '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
          : '00:${secs.toString().padLeft(2, '0')}';
      if (targetCount != null) {
        return '$time (Target: $targetCount)';
      }
      return time;
    }
    return 'x$targetReps';
  }

  int get totalDurationSeconds {
    if (type == ExerciseType.duration) return targetSeconds;
    // Estimate ~3 seconds per rep
    return (targetReps * 3);
  }
}

class DayWorkout {
  final int day;
  final List<Exercise> exercises;

  DayWorkout({required this.day, required this.exercises});

  int get totalExercises => exercises.length;

  int get totalDurationMinutes {
    final totalSeconds =
        exercises.fold<int>(0, (sum, e) => sum + e.totalDurationSeconds);
    return (totalSeconds / 60).ceil();
  }
}

// Default workout plans
List<DayWorkout> getDefaultWorkoutPlan() {
  return [
    DayWorkout(day: 1, exercises: [
      Exercise(
        id: 'd1_mountain_climber',
        name: 'Mountain Climber',
        emoji: '🏃',
        type: ExerciseType.duration,
        targetSeconds: 30,
        targetCount: 30,
      ),
      Exercise(
        id: 'd1_squats',
        name: 'Squats',
        emoji: '🏋️',
        type: ExerciseType.reps,
        targetReps: 16,
      ),
      Exercise(
        id: 'd1_high_stepping',
        name: 'High Stepping',
        emoji: '🏃',
        type: ExerciseType.duration,
        targetSeconds: 30,
      ),
      Exercise(
        id: 'd1_reverse_crunches',
        name: 'Reverse Crunches',
        emoji: '🤸',
        type: ExerciseType.reps,
        targetReps: 16,
      ),
      Exercise(
        id: 'd1_pushups',
        name: 'Push-Ups',
        emoji: '💪',
        type: ExerciseType.reps,
        targetReps: 15,
      ),
      Exercise(
        id: 'd1_plank',
        name: 'Plank Hold',
        emoji: '🧘',
        type: ExerciseType.duration,
        targetSeconds: 30,
      ),
      Exercise(
        id: 'd1_jumping_jacks',
        name: 'Jumping Jacks',
        emoji: '⭐',
        type: ExerciseType.reps,
        targetReps: 20,
      ),
    ]),
    DayWorkout(day: 2, exercises: [
      Exercise(
        id: 'd2_burpees',
        name: 'Burpees',
        emoji: '🔥',
        type: ExerciseType.reps,
        targetReps: 10,
      ),
      Exercise(
        id: 'd2_lunges',
        name: 'Lunges',
        emoji: '🦵',
        type: ExerciseType.reps,
        targetReps: 12,
      ),
      Exercise(
        id: 'd2_high_knees',
        name: 'High Knees',
        emoji: '🏃',
        type: ExerciseType.duration,
        targetSeconds: 30,
      ),
      Exercise(
        id: 'd2_bicycle_crunches',
        name: 'Bicycle Crunches',
        emoji: '🚴',
        type: ExerciseType.reps,
        targetReps: 20,
      ),
      Exercise(
        id: 'd2_pushups',
        name: 'Push-Ups',
        emoji: '💪',
        type: ExerciseType.reps,
        targetReps: 18,
      ),
      Exercise(
        id: 'd2_side_plank',
        name: 'Side Plank',
        emoji: '🧘',
        type: ExerciseType.duration,
        targetSeconds: 20,
      ),
    ]),
    DayWorkout(day: 3, exercises: [
      Exercise(
        id: 'd3_jump_squats',
        name: 'Jump Squats',
        emoji: '🏋️',
        type: ExerciseType.reps,
        targetReps: 12,
      ),
      Exercise(
        id: 'd3_mountain_climber',
        name: 'Mountain Climber',
        emoji: '🏃',
        type: ExerciseType.duration,
        targetSeconds: 45,
        targetCount: 40,
      ),
      Exercise(
        id: 'd3_tricep_dips',
        name: 'Tricep Dips',
        emoji: '💪',
        type: ExerciseType.reps,
        targetReps: 12,
      ),
      Exercise(
        id: 'd3_flutter_kicks',
        name: 'Flutter Kicks',
        emoji: '🦵',
        type: ExerciseType.duration,
        targetSeconds: 30,
      ),
      Exercise(
        id: 'd3_pushups',
        name: 'Push-Ups',
        emoji: '💪',
        type: ExerciseType.reps,
        targetReps: 20,
      ),
    ]),
  ];
}
