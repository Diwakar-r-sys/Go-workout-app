import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/exercise.dart';

class DayWorkoutScreen extends StatefulWidget {
  final DayWorkout dayWorkout;

  const DayWorkoutScreen({super.key, required this.dayWorkout});

  @override
  State<DayWorkoutScreen> createState() => _DayWorkoutScreenState();
}

class _DayWorkoutScreenState extends State<DayWorkoutScreen> {
  late List<Exercise> _exercises;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.dayWorkout.exercises);
  }

  int get _totalDurationMinutes {
    final totalSeconds =
        _exercises.fold<int>(0, (sum, e) => sum + e.totalDurationSeconds);
    return (totalSeconds / 60).ceil();
  }

  void _showEditDialog(int index) {
    final exercise = _exercises[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExerciseSheet(
        exercise: exercise,
        onSave: (updated) {
          setState(() {
            _exercises[index] = updated;
          });
        },
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded,
                  color: Color(0xFF00FF88)),
              title: const Text('Reset to Defaults',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _exercises =
                      List.from(widget.dayWorkout.exercises);
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded,
                  color: Color(0xFF3742FA)),
              title: const Text('Share Workout',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Day ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: '${widget.dayWorkout.day}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3742FA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMoreOptions,
                    child: const Icon(Icons.more_vert_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // ── Stats Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF14142A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00FF88).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$_totalDurationMinutes mins',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00FF88),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_exercises.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Exercises',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
            ),

            const SizedBox(height: 24),

            // ── Exercises Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });
                    },
                    child: Text(
                      _isEditMode ? 'Done >' : 'Edit >',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3742FA),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Exercise List ──
            Expanded(
              child: ReorderableListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF88).withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return _ExerciseTile(
                    key: ValueKey(exercise.id),
                    exercise: exercise,
                    isEditMode: _isEditMode,
                    onEdit: () => _showEditDialog(index),
                    index: index,
                  );
                },
              ),
            ),

            // ── Start Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to actual workout/tracking screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('🚀 Starting workout...'),
                        backgroundColor: const Color(0xFF00FF88),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 8),
                      Text('Start Day',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise tile ─────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool isEditMode;
  final VoidCallback onEdit;
  final int index;

  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.isEditMode,
    required this.onEdit,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF00FF88).withOpacity(0.1),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                // Drag handle (visible in edit mode)
                AnimatedOpacity(
                  opacity: isEditMode ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white38, size: 20),
                ),
                const SizedBox(width: 12),

                // Exercise emoji
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06)),
                  ),
                  alignment: Alignment.center,
                  child: Text(exercise.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),

                // Name & value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: exercise.type == ExerciseType.reps
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFF8C42),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.displayValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: exercise.type == ExerciseType.reps
                              ? const Color(0xFF00FF88).withOpacity(0.7)
                              : const Color(0xFFFF8C42).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit icon
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(duration: 300.ms).slideX(begin: 0.15, end: 0);
  }
}

// ── Edit Exercise Bottom Sheet ─────────────────────────────
class _EditExerciseSheet extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onSave;

  const _EditExerciseSheet({
    required this.exercise,
    required this.onSave,
  });

  @override
  State<_EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<_EditExerciseSheet> {
  late int _reps;
  late int _seconds;
  late int? _targetCount;

  @override
  void initState() {
    super.initState();
    _reps = widget.exercise.targetReps;
    _seconds = widget.exercise.targetSeconds;
    _targetCount = widget.exercise.targetCount;
  }

  @override
  Widget build(BuildContext context) {
    final isReps = widget.exercise.type == ExerciseType.reps;
    final accentColor =
        isReps ? const Color(0xFF00FF88) : const Color(0xFFFF8C42);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Exercise name & emoji
              Row(
                children: [
                  Text(widget.exercise.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          isReps ? 'Rep-Based Exercise' : 'Timed Exercise',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Controls ──
              if (isReps) ...[
                _buildLabel('Target Reps'),
                const SizedBox(height: 12),
                _buildStepper(
                  value: _reps,
                  min: 1,
                  max: 100,
                  accentColor: accentColor,
                  suffix: 'reps',
                  onChanged: (v) => setState(() => _reps = v),
                ),
              ] else ...[
                _buildLabel('Duration'),
                const SizedBox(height: 12),
                _buildTimeStepper(
                  seconds: _seconds,
                  accentColor: accentColor,
                  onChanged: (v) => setState(() => _seconds = v),
                ),
                if (_targetCount != null) ...[
                  const SizedBox(height: 20),
                  _buildLabel('Target Count (optional)'),
                  const SizedBox(height: 12),
                  _buildStepper(
                    value: _targetCount!,
                    min: 1,
                    max: 200,
                    accentColor: accentColor,
                    suffix: 'count',
                    onChanged: (v) => setState(() => _targetCount = v),
                  ),
                ],
              ],

              const SizedBox(height: 28),

              // ── Quick Presets ──
              _buildLabel(isReps ? 'Quick Set' : 'Quick Duration'),
              const SizedBox(height: 12),
              if (isReps)
                _buildQuickPresets(
                  values: [5, 10, 15, 20, 25, 30],
                  selected: _reps,
                  accentColor: accentColor,
                  suffix: '',
                  onTap: (v) => setState(() => _reps = v),
                )
              else
                _buildQuickPresets(
                  values: [15, 30, 45, 60, 90, 120],
                  selected: _seconds,
                  accentColor: accentColor,
                  suffix: 's',
                  onTap: (v) => setState(() => _seconds = v),
                ),

              const SizedBox(height: 28),

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = widget.exercise.copyWith(
                      targetReps: _reps,
                      targetSeconds: _seconds,
                      targetCount: _targetCount,
                    );
                    widget.onSave(updated);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int min,
    required int max,
    required Color accentColor,
    required String suffix,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepperBtn(Icons.remove, accentColor, () {
            if (value > min) onChanged(value - 1);
          }),
          // Minus 5
          _stepperBtn(null, accentColor, () {
            if (value - 5 >= min) onChanged(value - 5);
          }, label: '-5'),

          Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
            ],
          ),

          // Plus 5
          _stepperBtn(null, accentColor, () {
            if (value + 5 <= max) onChanged(value + 5);
          }, label: '+5'),
          _stepperBtn(Icons.add, accentColor, () {
            if (value < max) onChanged(value + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTimeStepper({
    required int seconds,
    required Color accentColor,
    required Function(int) onChanged,
  }) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final display =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepperBtn(Icons.remove, accentColor, () {
            if (seconds > 5) onChanged(seconds - 5);
          }),
          _stepperBtn(null, accentColor, () {
            if (seconds - 15 >= 5) onChanged(seconds - 15);
          }, label: '-15s'),
          Column(
            children: [
              Text(
                display,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              Text(
                'min : sec',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          _stepperBtn(null, accentColor, () {
            if (seconds + 15 <= 600) onChanged(seconds + 15);
          }, label: '+15s'),
          _stepperBtn(Icons.add, accentColor, () {
            if (seconds < 600) onChanged(seconds + 5);
          }),
        ],
      ),
    );
  }

  Widget _stepperBtn(IconData? icon, Color accentColor, VoidCallback onTap,
      {String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 48 : 40,
        height: 40,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: accentColor, size: 20)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
      ),
    );
  }

  Widget _buildQuickPresets({
    required List<int> values,
    required int selected,
    required Color accentColor,
    required String suffix,
    required Function(int) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isActive = v == selected;
        return GestureDetector(
          onTap: () => onTap(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor
                  : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? accentColor
                    : Colors.white.withOpacity(0.08),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            child: Text(
              '$v$suffix',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.black : Colors.white60,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
