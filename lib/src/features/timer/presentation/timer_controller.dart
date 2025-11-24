import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter_architecture_flutter_firebase/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/entries/data/entries_repository.dart';
import 'package:starter_architecture_flutter_firebase/src/features/jobs/domain/job.dart';

// Simple class to hold the timer state
class TimerState {
  final Job? activeJob;
  final DateTime? startTime;

  TimerState({this.activeJob, this.startTime});
}

// The Controller that manages the logic
class TimerController extends StateNotifier<TimerState> {
  TimerController(this.ref) : super(TimerState());
  final Ref ref;

  // 1. START TIMER
  void startTimer(Job job) {
    // We overwrite any existing timer with the new one
    state = TimerState(
      activeJob: job,
      startTime: DateTime.now(),
    );
  }

  // 2. STOP TIMER (AND SAVE ENTRY)
  Future<void> stopTimer() async {
    final job = state.activeJob;
    final start = state.startTime;
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (job != null && start != null && user != null) {
      final end = DateTime.now();
      
      // Save to Firebase
      await ref.read(entriesRepositoryProvider).addEntry(
        uid: user.uid,
        jobId: job.id,
        start: start,
        end: end,
        comment: '', // Empty comment for auto-timer
      );
    }

    // Clear the timer
    state = TimerState();
  }
}

// The Provider
final timerControllerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  return TimerController(ref);
});