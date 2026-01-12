import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/data/entries_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';

// Updated class to hold the timer state including the task name
class TimerState {
  final Job? activeJob;
  final DateTime? startTime;
  final String? taskName; // Added to store the name entered in the dialog

  TimerState({this.activeJob, this.startTime, this.taskName});
}

// The Controller that manages the logic
class TimerController extends StateNotifier<TimerState> {
  TimerController(this.ref) : super(TimerState());
  final Ref ref;

  // 1. START TIMER - Updated to accept a taskName
  void startTimer(Job job, String taskName) {
    // We overwrite any existing timer with the new one and store the task description
    state = TimerState(
      activeJob: job,
      startTime: DateTime.now(),
      taskName: taskName, // Save the task name for later
    );
  }

  // 2. STOP TIMER (AND SAVE ENTRY) - Updated to use the stored taskName
  Future<void> stopTimer() async {
    final job = state.activeJob;
    final start = state.startTime;
    final taskName = state.taskName; // Retrieve the task name from the state
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (job != null && start != null && user != null) {
      final end = DateTime.now();
      
      // Save to Firebase using the taskName as the entry comment
      await ref.read(entriesRepositoryProvider).addEntry(
        uid: user.uid,
        jobId: job.id,
        start: start,
        end: end,
        comment: taskName ?? '', // Use the saved name as the comment
      );
    }

    // Clear the timer state completely
    state = TimerState();
  }
}

// The Provider
final timerControllerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref);
});