import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter_architecture_flutter_firebase/src/constants/app_sizes.dart';
import 'package:starter_architecture_flutter_firebase/src/features/timer/presentation/timer_controller.dart';
import 'package:starter_architecture_flutter_firebase/src/utils/format.dart';

class TimerStickyBar extends ConsumerStatefulWidget {
  const TimerStickyBar({super.key});

  @override
  ConsumerState<TimerStickyBar> createState() => _TimerStickyBarState();
}

class _TimerStickyBarState extends ConsumerState<TimerStickyBar> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startTime = ref.read(timerControllerProvider).startTime;
      if (startTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerControllerProvider);
    final job = timerState.activeJob;
    final taskName = timerState.taskName; // Access the task name from state

    if (job == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: Sizes.p16, vertical: Sizes.p8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.circle, color: Colors.redAccent, size: 12),
            gapW12,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SHOW TASK NAME INSTEAD OF GENERIC MESSAGE
                  Text(
                    taskName != null && taskName.isNotEmpty 
                        ? taskName 
                        : 'Working on ${job.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Format.hours(_elapsed.inHours + (_elapsed.inMinutes / 60)), 
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref.read(timerControllerProvider.notifier).stopTimer(),
              icon: const Icon(Icons.stop_circle_outlined, size: 32),
              color: Colors.white,
              tooltip: 'Stop Timer',
            ),
          ],
        ),
      ),
    );
  }
}