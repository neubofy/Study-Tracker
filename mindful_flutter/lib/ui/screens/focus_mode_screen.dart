import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful/services/focus_mode_manager.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({Key? key}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedSessionType = 'Work';
  FocusMode _selectedMode = FocusMode.countdown;
  int _durationInMinutes = 25;

  final List<String> sessionTypes = ['Study', 'Work', 'Creative', 'Break'];
  final List<int> durationOptions = [5, 15, 25, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        elevation: 0,
      ),
      body: Consumer<FocusModeManager>(
        builder: (context, focusManager, _) {
          if (focusManager.isActive) {
            return _buildActiveFocusSession(context, focusManager);
          }
          return _buildFocusSetup(context, focusManager);
        },
      ),
    );
  }

  Widget _buildActiveFocusSession(
      BuildContext context, FocusModeManager focusManager) {
    final session = focusManager.currentSession;
    if (session == null) return const SizedBox();

    final minutes = focusManager.remainingSeconds ~/ 60;
    final seconds = focusManager.remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Animated circle for timer
            ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                ),
                child: Center(
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              session.sessionType,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.isCalendarTriggered ? 'Calendar Event' : 'Manual Session',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: focusManager.status == FocusStatus.paused
                      ? () => focusManager.resumeFocusSession()
                      : () => focusManager.pauseFocusSession(),
                  icon: Icon(focusManager.status == FocusStatus.paused
                      ? Icons.play_arrow
                      : Icons.pause),
                  label: Text(focusManager.status == FocusStatus.paused
                      ? 'Resume'
                      : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => focusManager.completeFocusSession(),
                  icon: const Icon(Icons.check),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => focusManager.cancelFocusSession(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSetup(
      BuildContext context, FocusModeManager focusManager) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Start a Focus Session',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Session Type Selection
            const Text(
              'Session Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sessionTypes.map((type) {
                  final isSelected = _selectedSessionType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedSessionType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            // Mode Selection
            const Text(
              'Focus Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<FocusMode>(
                    title: const Text('Countdown'),
                    value: FocusMode.countdown,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedMode = value);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<FocusMode>(
                    title: const Text('Stopwatch'),
                    value: FocusMode.stopwatch,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedMode = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Duration Selection
            const Text(
              'Duration (minutes)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: durationOptions.map((duration) {
                  final isSelected = _durationInMinutes == duration;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$duration m'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _durationInMinutes = duration);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 48),
            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  focusManager.startFocusSession(
                    sessionType: _selectedSessionType,
                    mode: _selectedMode,
                    durationInSeconds: _durationInMinutes * 60,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Start Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
