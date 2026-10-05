import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../application/tasks_providers.dart';
import 'task_detail_dialog.dart';

class ActiveTimerBanner extends ConsumerStatefulWidget {
  const ActiveTimerBanner({super.key});

  @override
  ConsumerState<ActiveTimerBanner> createState() => _ActiveTimerBannerState();
}

class _ActiveTimerBannerState extends ConsumerState<ActiveTimerBanner> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-synchronize timer when app resumes
      ref.read(activeTimerProvider.notifier).checkActiveTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(activeTimerProvider);
    final entry = timerState.entry;

    if (!timerState.isRunning || entry == null) {
      return const SizedBox.shrink();
    }

    final isPaused = timerState.isPaused;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaused
              ? [const Color(0xFFD97706), const Color(0xFFB45309)] // Amber for paused
              : [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: (isPaused ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // Timer status icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaused ? Icons.pause : Icons.timer,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),

            // Task title and project name
            Expanded(
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => TaskDetailDialog(taskId: entry.taskId),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.taskTitle ?? 'Active Task #${entry.taskId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.projectName != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${entry.projectName}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isPaused ? 'Timer paused (tap to view task details)' : 'Timer running (tap to view task details)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Monospace Digital Timer Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPaused) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'PAUSED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    timerState.formattedTime,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Pause / Resume Button
            if (isPaused)
              ElevatedButton.icon(
                onPressed: timerState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(activeTimerProvider.notifier).resumeTimer(entry.taskId);
                        } catch (e) {
                          if (context.mounted) {
                            AppToast.error(context, e);
                          }
                        }
                      },
                icon: const Icon(Icons.play_arrow, size: 14),
                label: const Text('Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD97706),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: timerState.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(activeTimerProvider.notifier).pauseTimer(entry.taskId);
                        } catch (e) {
                          if (context.mounted) {
                            AppToast.error(context, e);
                          }
                        }
                      },
                icon: const Icon(Icons.pause, size: 14),
                label: const Text('Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),

            const SizedBox(width: 6),

            // Stop button
            ElevatedButton.icon(
              onPressed: timerState.isLoading
                  ? null
                  : () async {
                      try {
                        await ref.read(activeTimerProvider.notifier).stopTimer(entry.taskId);
                        if (context.mounted) {
                          AppToast.success(context, 'Task timer stopped and actual hours recorded.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.error(context, e);
                        }
                      }
                    },
              icon: const Icon(Icons.stop_circle_outlined, size: 14),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.rose,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
