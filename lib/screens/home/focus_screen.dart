import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/auth/auth_service.dart';
import '../../core/focus/focus_intent_bus.dart';
import '../../core/focus/focus_service.dart';
import '../../core/tasks/task_service.dart';
import '../../core/tasks/task_store.dart';
import '../../models/task_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/cards/focus_card.dart';
import '../../widgets/empty_tasks_state.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../focus_session/focus_session_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  String? _selectedTaskId;
  int _sessionDurationMinutes = 25;

  List<TaskItem> get _tasks => TaskStore.instance.remaining;

  @override
  void initState() {
    super.initState();
    // Pull today's completed-session count so the progress card reflects
    // reality instead of a hardcoded placeholder. Concurrent refreshes
    // (tab switch, post-session) collapse onto one in-flight request.
    // Deferred to post-frame: refresh() notifies synchronously, and this
    // screen now sits inside a LoadingOverlay that listens to FocusService —
    // notifying mid-build would trip a "setState during build" assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusService.instance.refresh();
    });
    // Subscribe directly to the intent bus so every requestStart(...) call
    // (e.g. each tap of ابدأ الآن on home) re-fires consumption — the
    // IndexedStack keeps us mounted so didChangeDependencies wouldn't
    // re-fire on tab switch, and a one-shot flag would break the 2nd tap.
    FocusIntentBus.instance.addListener(_onIntentChanged);
    // An intent might already be queued before this screen first mounts
    // (home tapped a pill that also switched tabs). Run once after the
    // first frame so we still consume it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onIntentChanged();
    });
  }

  @override
  void dispose() {
    FocusIntentBus.instance.removeListener(_onIntentChanged);
    super.dispose();
  }

  void _onIntentChanged() {
    if (!mounted) return;
    if (!FocusIntentBus.instance.hasIntent) return;
    final intent = FocusIntentBus.instance.consume();
    // The home screen routes "ابدأ الآن" here. With the preset grid removed,
    // a task-bearing intent simply pre-selects that task in the existing
    // task list so the user can tap "ابدأ الجلسة"; a task-less intent (the
    // خذ لحظة تركيز card) just lands the user on this tab.
    final String? taskId = intent.taskId;
    if (taskId == null) return;
    if (TaskStore.instance.remaining.indexWhere((t) => t.id == taskId) < 0) {
      return;
    }
    setState(() => _selectedTaskId = taskId);
  }

  Future<void> _onAddTask() async {
    // Tasks save to the account (backend-first) — gated for guests.
    if (AuthService.isGuest) {
      showLoginRequiredToast(context);
      return;
    }
    final String? label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _AddTaskSheet(),
    );
    if (!mounted || label == null || label.isEmpty) return;
    // Persist through the backend so the task carries a real UUID — a
    // local-only id (microsecond timestamp) is rejected by
    // POST /focus/sessions/start ("task id must be a valid UUID"), which is
    // what produced "ما قدرنا نبدأ الجلسة".
    final TaskItem? created = await TaskService.instance.add(label);
    if (!mounted) return;
    if (created == null) {
      _showSnack('ما قدرنا نضيف المهمة، جرّب مرة ثانية.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message, type: AppToastType.error);
  }

  /// Swipe right→left → delete. Returns whether to dismiss the row (true on a
  /// successful backend delete; false keeps it on failure).
  Future<bool> _onDeleteTask(TaskItem task) async {
    final bool ok = await TaskService.instance.remove(task.id);
    if (!mounted) return ok;
    if (!ok) {
      _showSnack('ما قدرنا نحذف المهمة، جرّب مرة ثانية.');
      return false;
    }
    if (_selectedTaskId == task.id) {
      setState(() => _selectedTaskId = null);
    }
    return true;
  }

  /// Swipe left→right → edit the task name via the (pre-filled) add-task sheet.
  Future<void> _onEditTask(TaskItem task) async {
    final String? label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _AddTaskSheet(
        initialValue: task.label,
        submitLabel: 'حفظ',
      ),
    );
    if (!mounted || label == null || label.trim().isEmpty) return;
    if (label.trim() == task.label) return;
    final bool ok = await TaskService.instance.update(task.id, label.trim());
    if (!mounted) return;
    if (!ok) _showSnack('ما قدرنا نعدّل المهمة، جرّب مرة ثانية.');
  }

  Future<void> _onCustomizeSession() async {
    final _SessionConfig? config = await showModalBottomSheet<_SessionConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) =>
          _CustomizeSessionSheet(initialDuration: _sessionDurationMinutes),
    );
    if (!mounted || config == null) return;
    // Must persist on the backend to obtain a UUID the focus-session start
    // endpoint will accept. If the network add fails, surface an error and
    // abort rather than starting with a local id that would 422.
    final TaskItem? added = await TaskService.instance.add(config.task);
    if (!mounted) return;
    if (added == null) {
      _showSnack('ما قدرنا ننشئ المهمة، جرّب مرة ثانية.');
      return;
    }
    setState(() {
      _selectedTaskId = added.id;
      _sessionDurationMinutes = config.durationMinutes;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FocusSessionScreen(
          taskId: added.id,
          task: added.label,
          durationMinutes: config.durationMinutes,
        ),
      ),
    );
    if (!mounted) return;
    await _confirmTaskDone(added.id);
  }

  void _onSelectTask(String id) {
    setState(() {
      _selectedTaskId = _selectedTaskId == id ? null : id;
    });
  }

  /// Direct completion via the "تم" pill — marks the task completed without a
  /// focus session (uses the same TaskService.complete path as the dialog).
  Future<void> _onCompleteTask(TaskItem task) async {
    final bool ok = await TaskService.instance.complete(task.id);
    if (!mounted) return;
    if (!ok) {
      _showSnack('ما قدرنا نحدّث المهمة، جرّب مرة ثانية.');
      return;
    }
    if (_selectedTaskId == task.id) {
      setState(() => _selectedTaskId = null);
    }
  }

  /// Picks the line shown under "أنهيت اليوم" based on how many real
  /// tasks the user still has. Buckets live in Flutter (not admin) so
  /// the strip stays responsive without a network round-trip.
  String _motivationFor(int remaining) {
    if (remaining == 0) return 'ابدأ بإضافة مهمة، خطوة وحدة تكفي ✨';
    if (remaining == 1) return 'جلسة واحدة وتكمل هدفك 👏';
    if (remaining == 2) return 'جلستين وتكمل هدفك 💪';
    if (remaining == 3) return 'ثلاث جلسات وتكمل هدفك 🌟';
    return 'خذها مهمة بمهمة، الإنجاز يتجمع ✨';
  }

  Future<void> _onStartSession() async {
    final String? id = _selectedTaskId;
    if (id == null) return;
    if (_tasks.indexWhere((t) => t.id == id) == -1) return;

    final int? minutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) =>
          _PickDurationSheet(initialDuration: _sessionDurationMinutes),
    );
    if (!mounted || minutes == null) return;

    final int idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final TaskItem task = _tasks[idx];

    setState(() => _sessionDurationMinutes = minutes);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FocusSessionScreen(
          taskId: task.id,
          task: task.label,
          durationMinutes: minutes,
        ),
      ),
    );
    if (!mounted) return;
    await _confirmTaskDone(task.id);
  }

  /// After a session, ask whether the task is finished. "نعم، أنجزتها" marks it
  /// completed (so it moves to "أنجزت هذه المهام"); "لا" keeps it active.
  /// Selecting/starting a task never completes it — only this explicit yes does.
  Future<void> _confirmTaskDone(String taskId) async {
    // Skip if the task is no longer active (already completed or deleted).
    if (TaskStore.instance.remaining.indexWhere((t) => t.id == taskId) < 0) {
      return;
    }
    final bool? done = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _TaskDoneDialog(),
    );
    if (done != true || !mounted) return;
    await TaskService.instance.complete(taskId);
    if (!mounted) return;
    if (_selectedTaskId == taskId) {
      setState(() => _selectedTaskId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppTopNav(title: 'التركيز', showBackButton: false),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FocusCard(
                      primaryLabel: 'تخصيص الجلسة',
                      primaryIconAsset: AppSvgIcons.focusSparkle,
                      onStart: _onCustomizeSession,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedBuilder(
                      animation: TaskStore.instance,
                      builder: (context, _) {
                        return _AddTasksCard(
                          tasks: _tasks,
                          selectedTaskId: _selectedTaskId,
                          onAddTask: _onAddTask,
                          onSelectTask: _onSelectTask,
                          onCompleteTask: _onCompleteTask,
                          onStartSession: _onStartSession,
                          onDeleteTask: _onDeleteTask,
                          onEditTask: _onEditTask,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedBuilder(
                      animation: TaskStore.instance,
                      builder: (context, _) {
                        // "أنهيت اليوم" now counts completed TASKS, not focus
                        // sessions. The task list isn't dated, so "today" is the
                        // current task list (completed / total). FocusService's
                        // session counting is left intact and separate.
                        final int total = TaskStore.instance.tasks.length;
                        final int done = TaskStore.instance.completed.length;
                        return _ProgressCard(done: done, total: total);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnimatedBuilder(
                      animation: TaskStore.instance,
                      builder: (context, _) {
                        final int remaining =
                            TaskStore.instance.remaining.length;
                        return _MotivationStrip(
                          text: _motivationFor(remaining),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: TaskStore.instance,
                      builder: (context, _) {
                        final List<TaskItem> done =
                            TaskStore.instance.completed;
                        if (done.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            _CompletedTasksCard(
                              tasks: [for (final t in done) t.label],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryPillButton extends StatelessWidget {
  const _SecondaryPillButton({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppPalettePurple.shade400, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(iconAsset, width: 16, height: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  fontWeight: AppFontWeights.medium,
                  color: AppPalettePurple.shade200,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTasksCard extends StatelessWidget {
  const _AddTasksCard({
    required this.tasks,
    required this.selectedTaskId,
    required this.onAddTask,
    required this.onSelectTask,
    required this.onCompleteTask,
    required this.onStartSession,
    required this.onDeleteTask,
    required this.onEditTask,
  });

  final List<TaskItem> tasks;
  final String? selectedTaskId;
  final VoidCallback onAddTask;
  final ValueChanged<String> onSelectTask;

  /// Marks a task completed directly (the "تم" pill), without a focus session.
  final ValueChanged<TaskItem> onCompleteTask;
  final VoidCallback onStartSession;

  /// Returns whether the row should be dismissed (true after a successful delete).
  final Future<bool> Function(TaskItem task) onDeleteTask;
  final Future<void> Function(TaskItem task) onEditTask;

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    if (selectedTaskId != null) {
      for (final t in tasks) {
        if (t.id == selectedTaskId) {
          selectedLabel = t.label;
          break;
        }
      }
    }

    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  tasks.isEmpty
                      ? '📌 أضف مهامك وابدأ لاحقًا'
                      : '📌 اختر مهمة لجلستك',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFontFamily.title,
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.bold,
                    color: context.colors.shade600,
                    height: 1.3,
                    fontFeatures: AppFontFamily.titleFeatures,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              _SecondaryPillButton(
                label: 'إضافة مهمة',
                iconAsset: AppSvgIcons.focusPlus,
                onTap: onAddTask,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (tasks.isEmpty)
            const EmptyTasksState()
          else
            for (int i = 0; i < tasks.length; i++) ...[
              if (i != 0) const SizedBox(height: AppSpacing.md),
              Dismissible(
                key: ValueKey(tasks[i].id),
                direction: DismissDirection.horizontal,
                // RTL: startToEnd = swipe right→left → delete;
                //      endToStart = swipe left→right → edit name.
                background: const _TaskSwipeBackground(isDelete: true),
                secondaryBackground: const _TaskSwipeBackground(isDelete: false),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    return onDeleteTask(tasks[i]);
                  }
                  await onEditTask(tasks[i]);
                  return false;
                },
                child: _TaskBulletRow(
                  label: tasks[i].label,
                  isSelected: tasks[i].id == selectedTaskId,
                  onTap: () => onSelectTask(tasks[i].id),
                  onComplete: () => onCompleteTask(tasks[i]),
                ),
              ),
            ],
          if (selectedLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            _StartSessionButton(
              label: 'ابدأ التركيز على $selectedLabel',
              onTap: onStartSession,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskBulletRow extends StatelessWidget {
  const _TaskBulletRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onComplete,
  });

  final String label;
  final bool isSelected;

  /// Selects the task for a focus session (does NOT complete it).
  final VoidCallback onTap;

  /// Marks the task completed directly — the green "تم" pill, separate from
  /// selection.
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? context.purpleSoftFill(AppPalettePurple.shade600)
            : context.colors.white,
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: AppPalettePurple.shade200, width: 0.5)
            : Border.all(color: context.colors.shade400, width: 0.2),
      ),
      child: Row(
        children: [
          // The body (most of the card) selects the task for focus.
          Expanded(
            child: Semantics(
              button: true,
              label: 'اختيار المهمة للتركيز، $label',
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        // Selected = a FILLED purple radio (not a check) so it
                        // never reads as "completed". Unselected = empty ring.
                        if (isSelected)
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPalettePurple.shade200,
                            ),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppNeutralColors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppPalettePurple.shade200,
                                width: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              label,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.xs,
                                fontWeight: AppFontWeights.regular,
                                color: context.colors.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Direct completion — green "تم", on the start (left in RTL).
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
            child: _TaskDonePill(onTap: onComplete),
          ),
        ],
      ),
    );
  }
}

/// Small green "تم" pill that marks a task completed directly (no focus
/// session). Visually distinct from the purple selection radio; conveys state
/// via icon + text, not colour alone.
class _TaskDonePill extends StatelessWidget {
  const _TaskDonePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.full);
    return Semantics(
      button: true,
      label: 'تمييز المهمة كمنجزة',
      child: Material(
        // Neutral grey — NOT green. Green/check is reserved for tasks already
        // completed under "أنجزت هذه المهام 👏"; a green action pill here would
        // read as "already done". `context.colors` is theme-aware (light/dark).
        color: context.colors.shade100,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: context.colors.shade300, width: 0.5),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: context.colors.shade500,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'تم',
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: AppFontWeights.semibold,
                      color: context.colors.shade600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coloured background revealed behind a task row while swiping:
/// red + trash for delete (swipe right→left), purple + edit for rename
/// (swipe left→right). The icon hugs the edge the swipe reveals.
class _TaskSwipeBackground extends StatelessWidget {
  const _TaskSwipeBackground({required this.isDelete});

  final bool isDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDelete ? AppDangerColors.shade500 : AppPalettePurple.shade200,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      alignment: isDelete
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: SvgPicture.asset(
        isDelete
            ? AppSvgIcons.profileDeleteAccount
            : AppSvgIcons.profileEditPencil,
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          AppNeutralColors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _StartSessionButton extends StatelessWidget {
  const _StartSessionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalettePurple.shade200,
          borderRadius: radius,
          boxShadow: AppShadows.xs,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xs,
                        fontWeight: AppFontWeights.semibold,
                        color: AppNeutralColors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SvgPicture.asset(
                    AppSvgIcons.arrowLeft,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppNeutralColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : done / total;
    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تقدّم المهام',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.title,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.bold,
              color: context.colors.shade600,
              height: 1.3,
              fontFeatures: AppFontFamily.titleFeatures,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'أكملت $done من $total مهام',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _BalanceBar(progress: progress),
        ],
      ),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.progress});

  final double progress;
  static const double _height = 16;

  static const List<Color> _gradientColors = [
    AppPalettePurple.shade500,
    AppPalettePurple.shade400,
    AppPalettePurple.shade300,
    AppPalettePurple.shade200,
  ];

  Color get _percentColor {
    final double t = progress.clamp(0.0, 1.0);
    final double scaled = t * (_gradientColors.length - 1);
    final int idx = scaled.floor().clamp(0, _gradientColors.length - 2);
    final double frac = scaled - idx;
    return Color.lerp(_gradientColors[idx], _gradientColors[idx + 1], frac)!;
  }

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double fullWidth = constraints.maxWidth;
              return Container(
                height: _height,
                decoration: BoxDecoration(
                  color: context.colors.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: fullWidth * clamped,
                    height: _height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: OverflowBox(
                        maxWidth: fullWidth,
                        minWidth: fullWidth,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: fullWidth,
                          height: _height,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.centerStart,
                              end: AlignmentDirectional.centerEnd,
                              colors: _gradientColors,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xs,
            fontWeight: AppFontWeights.bold,
            color: _percentColor,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MotivationStrip extends StatelessWidget {
  const _MotivationStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xs,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade600,
          height: 1.4,
        ),
      ),
    );
  }
}

class _CompletedTasksCard extends StatelessWidget {
  const _CompletedTasksCard({required this.tasks});

  final List<String> tasks;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '👏 أنجزت هذه المهام',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.title,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.bold,
              color: context.colors.shade600,
              height: 1.3,
              fontFeatures: AppFontFamily.titleFeatures,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (int i = 0; i < tasks.length; i++) ...[
            if (i != 0) const SizedBox(height: AppSpacing.md),
            _CompletedTaskRow(text: tasks[i]),
          ],
        ],
      ),
    );
  }
}

class _CompletedTaskRow extends StatelessWidget {
  const _CompletedTaskRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.forDark(
          AppSuccessColors.shade25,
          AppSuccessColors.shade950,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppSuccessColors.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppSvgIcons.focusCheck, width: 20, height: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.forDark(
                  context.colors.shade500,
                  AppSuccessColors.shade300,
                ),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asked after a focus session: did the user finish the task? "نعم، أنجزتها"
/// pops true (caller marks it completed → it moves to "أنجزت هذه المهام"); the
/// other option keeps it active.
class _TaskDoneDialog extends StatelessWidget {
  const _TaskDoneDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 325,
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '👏',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'هل تم إنجاز المهمة؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'إذا خلصت، نضيفها لقائمة الإنجاز.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _TaskDoneButton(
                  label: 'نعم، تم إنجازها',
                  filled: true,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.md),
                _TaskDoneButton(
                  label: 'لا، تبقى في المهام',
                  filled: false,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDoneButton extends StatelessWidget {
  const _TaskDoneButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: filled ? AppPalettePurple.shade200 : context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: filled ? AppShadows.xs : null,
            border: filled
                ? null
                : Border.all(color: AppPalettePurple.shade200, width: 1),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: filled ? AppNeutralColors.white : AppPalettePurple.shade200,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({this.initialValue, this.submitLabel = 'إضافة'});

  /// Pre-fills the field when editing an existing task; null for a new task.
  final String? initialValue;

  /// The action button label ('إضافة' for new, 'حفظ' for edit).
  final String submitLabel;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');
  late bool _canSubmit = (widget.initialValue ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final bool now = _controller.text.trim().isNotEmpty;
    if (now != _canSubmit) setState(() => _canSubmit = now);
  }

  void _onSubmit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeader(onClose: () => Navigator.of(context).pop()),
                const SizedBox(height: AppSpacing.xxxl),
                _TaskQuestionCard(controller: _controller),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: widget.submitLabel,
                  expand: true,
                  onPressed: _canSubmit ? _onSubmit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkResponse(
          onTap: onClose,
          radius: 20,
          child: SvgPicture.asset(
            AppSvgIcons.closeSmall,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              context.colors.shade700,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            'إضافـة مهمـة',
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.sm,
              color: context.colors.shade700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskQuestionCard extends StatelessWidget {
  const _TaskQuestionCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '📌 المهمة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.medium,
              color: context.colors.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TaskInput(controller: controller),
        ],
      ),
    );
  }
}

class _SessionConfig {
  const _SessionConfig({required this.durationMinutes, required this.task});

  final int durationMinutes;
  final String task;
}

class _CustomizeSessionSheet extends StatefulWidget {
  const _CustomizeSessionSheet({required this.initialDuration});

  final int initialDuration;

  @override
  State<_CustomizeSessionSheet> createState() => _CustomizeSessionSheetState();
}

class _CustomizeSessionSheetState extends State<_CustomizeSessionSheet> {
  static const List<int> _durationOptions = [25, 35, 45, 60];

  final TextEditingController _controller = TextEditingController();
  late int _selectedDuration;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final bool now = _controller.text.trim().isNotEmpty;
    if (now != _canSubmit) setState(() => _canSubmit = now);
  }

  void _onSelectDuration(int minutes) {
    setState(() => _selectedDuration = minutes);
  }

  void _onSubmit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(
      context,
    ).pop(_SessionConfig(durationMinutes: _selectedDuration, task: value));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeaderCustom(
                  title: 'تخصيـص الجلسـة',
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _DurationAndTaskCard(
                  options: _durationOptions,
                  selected: _selectedDuration,
                  onSelect: _onSelectDuration,
                  controller: _controller,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: 'ابدأ الجلسة',
                  expand: true,
                  trailing: Builder(
                    builder: (context) {
                      final Color color =
                          IconTheme.of(context).color ?? AppNeutralColors.white;
                      return SvgPicture.asset(
                        AppSvgIcons.arrowLeft,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      );
                    },
                  ),
                  onPressed: _canSubmit ? _onSubmit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeaderCustom extends StatelessWidget {
  const _SheetHeaderCustom({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkResponse(
          onTap: onClose,
          radius: 20,
          child: SvgPicture.asset(
            AppSvgIcons.closeSmall,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              context.colors.shade700,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.sm,
              color: context.colors.shade700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _DurationAndTaskCard extends StatelessWidget {
  const _DurationAndTaskCard({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.controller,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = TextStyle(
      fontFamily: AppFontFamily.text,
      fontSize: AppFontSizes.sm,
      fontWeight: AppFontWeights.medium,
      color: context.colors.shade700,
      height: 1.3,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '📌 المهمة',
            textAlign: TextAlign.right,
            style: labelStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          _TaskInput(controller: controller),
          const SizedBox(height: AppSpacing.xl),
          Text('⏰ المدة', textAlign: TextAlign.right, style: labelStyle),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i != 0) const SizedBox(width: 10),
                Expanded(
                  child: _DurationChip(
                    minutes: options[i],
                    isSelected: options[i] == selected,
                    onTap: () => onSelect(options[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: isSelected
          ? context.purpleSoftFill(AppPalettePurple.shade600)
          : context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
          ),
          child: SizedBox(
            height: 26,
            child: Center(
              child: Text(
                '$minutes د',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.sm,
                  fontWeight: AppFontWeights.medium,
                  color: isSelected
                      ? context.forDark(
                          AppPalettePurple.shade100,
                          AppPalettePurple.shade500,
                        )
                      : context.colors.shade500,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskInput extends StatelessWidget {
  const _TaskInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.shade200, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        cursorColor: AppPalettePurple.shade300,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xxs,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade700,
        ),
        decoration: InputDecoration(
          hintText: 'اكتب هنا مهمتك ..',
          hintStyle: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xxs,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade400,
          ),
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PickDurationSheet extends StatefulWidget {
  const _PickDurationSheet({required this.initialDuration});

  final int initialDuration;

  @override
  State<_PickDurationSheet> createState() => _PickDurationSheetState();
}

class _PickDurationSheetState extends State<_PickDurationSheet> {
  static const List<int> _durationOptions = [25, 35, 45, 60];

  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
  }

  void _onSubmit() {
    Navigator.of(context).pop(_selectedDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SheetHeaderCustom(
                  title: 'حـدد مـدة الجلســة',
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _DurationOnlyCard(
                  options: _durationOptions,
                  selected: _selectedDuration,
                  onSelect: (m) => setState(() => _selectedDuration = m),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: 'ابدأ الجلسة',
                  expand: true,
                  trailing: Builder(
                    builder: (context) {
                      final Color color =
                          IconTheme.of(context).color ?? AppNeutralColors.white;
                      return SvgPicture.asset(
                        AppSvgIcons.arrowLeft,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      );
                    },
                  ),
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationOnlyCard extends StatelessWidget {
  const _DurationOnlyCard({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '⏰ المدة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.medium,
              color: context.colors.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i != 0) const SizedBox(width: 10),
                Expanded(
                  child: _DurationChip(
                    minutes: options[i],
                    isSelected: options[i] == selected,
                    onTap: () => onSelect(options[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
