import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/buddy_service.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/streak_utils.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/weekly_reflection.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/log_repository.dart';
import '../../../data/repositories/reflection_repository.dart';

/// Insights tab — weekly coach analysis, habit performance grid,
/// weekly reflection form, and past reflection history.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<Habit> _habits = [];
  WeeklyReflection? _thisWeek;
  List<WeeklyReflection> _pastReflections = [];

  double _thisWeekRate = 0;
  double _lastWeekRate = 0;
  int _thisWeekXp = 0;
  int _bestStreak = 0;
  String? _bestHabitTitle;
  Map<int, List<bool>> _habitWeekGrid = {};
  String _coachInsight = '';

  bool _loading = true;

  static DateTime _monday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final weekStart = _monday(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));

    final habits = await HabitRepository.instance.getAll();
    final thisWeekAllLogs =
        await LogRepository.instance.getAllLogsInRange(weekStart, weekEnd);
    final lastWeekAllLogs =
        await LogRepository.instance.getAllLogsInRange(lastWeekStart, lastWeekEnd);

    final thisWeekXp =
        thisWeekAllLogs.fold(0, (sum, l) => sum + l.pointsEarned);

    final Map<int, List<bool>> grid = {};
    int bestStreak = 0;
    String? bestHabitTitle;
    final List<String> skipped = [];

    for (final h in habits) {
      final hThisLogs =
          thisWeekAllLogs.where((l) => l.habitId == h.id).toList();
      final completedDates = hThisLogs.map((l) {
        final d = l.completedDate;
        return DateTime(d.year, d.month, d.day);
      }).toSet();

      grid[h.id!] = List.generate(
          7, (i) => completedDates.contains(weekStart.add(Duration(days: i))));

      if (hThisLogs.isEmpty) skipped.add(h.title);

      final from = weekEnd.subtract(const Duration(days: 90));
      final allLogs =
          await LogRepository.instance.getLogsInRange(h.id!, from, weekEnd);
      final s = StreakUtils.computeStreak(allLogs);
      if (s > bestStreak) {
        bestStreak = s;
        bestHabitTitle = h.title;
      }
    }

    final daysElapsed = now.weekday;
    final thisWeekPossible = habits.length * daysElapsed;
    final lastWeekPossible = habits.length * 7;
    final thisRate = thisWeekPossible == 0
        ? 0.0
        : (thisWeekAllLogs.length / thisWeekPossible).clamp(0.0, 1.0);
    final lastRate = lastWeekPossible == 0
        ? 0.0
        : (lastWeekAllLogs.length / lastWeekPossible).clamp(0.0, 1.0);

    final insight = BuddyService.instance.getWeeklyCoachInsight(
      thisWeekRate: thisRate,
      lastWeekRate: lastRate,
      thisWeekXp: thisWeekXp,
      bestStreak: bestStreak,
      bestHabit: bestHabitTitle,
      skippedAllWeek: skipped,
    );

    final reflection =
        await ReflectionRepository.instance.getForWeek(weekStart);
    final past = await ReflectionRepository.instance.getRecent(limit: 5);

    if (!mounted) return;
    setState(() {
      _habits = habits;
      _thisWeek = reflection;
      _pastReflections =
          past.where((r) => r.weekStart != weekStart).toList();
      _thisWeekRate = thisRate;
      _lastWeekRate = lastRate;
      _thisWeekXp = thisWeekXp;
      _bestStreak = bestStreak;
      _bestHabitTitle = bestHabitTitle;
      _habitWeekGrid = grid;
      _coachInsight = insight;
      _loading = false;
    });
  }

  void _openReflectionSheet() async {
    final weekStart = _monday(DateTime.now());
    final result = await showModalBottomSheet<WeeklyReflection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _ReflectionSheet(weekStart: weekStart, existing: _thisWeek),
    );
    if (result != null) setState(() => _thisWeek = result);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _monday(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));
    final daysLeft = 7 - DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _WeekIndicatorCard(
                      weekStart: weekStart,
                      weekEnd: weekEnd,
                      daysLeft: daysLeft),
                  const SizedBox(height: 12),
                  _WeeklyStatsCard(
                    thisWeekRate: _thisWeekRate,
                    lastWeekRate: _lastWeekRate,
                    thisWeekXp: _thisWeekXp,
                    bestStreak: _bestStreak,
                    bestHabit: _bestHabitTitle,
                  ),
                  const SizedBox(height: 12),
                  _CoachInsightCard(
                    insight: _coachInsight,
                    personality: PrefsService.instance.buddyPersonality,
                  ),
                  const SizedBox(height: 20),
                  if (_habits.isNotEmpty) ...[
                    Text('This Week\'s Performance',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    _HabitPerformanceSection(
                      habits: _habits,
                      weekGrid: _habitWeekGrid,
                      weekStart: weekStart,
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekly Reflection',
                          style: AppTextStyles.headlineMedium),
                      if (_thisWeek != null)
                        TextButton.icon(
                          onPressed: _openReflectionSheet,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _thisWeek == null
                      ? _EmptyReflection(onTap: _openReflectionSheet)
                      : _ReflectionSummaryCard(
                          reflection: _thisWeek!,
                          onEdit: _openReflectionSheet),
                  const SizedBox(height: 20),
                  if (_pastReflections.isNotEmpty) ...[
                    Text('Past Reflections',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    ..._pastReflections
                        .map((r) => _PastReflectionTile(reflection: r)),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week indicator
// ---------------------------------------------------------------------------

class _WeekIndicatorCard extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int daysLeft;

  const _WeekIndicatorCard(
      {required this.weekStart,
      required this.weekEnd,
      required this.daysLeft});

  String _fmt(DateTime d) => '${_m(d.month)} ${d.day}';
  String _m(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    final daysPassed = 7 - daysLeft;
    final Color urgency = daysLeft == 0
        ? Colors.red
        : daysLeft <= 2
            ? Colors.orange
            : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primaryPurple, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Week of ${_fmt(weekStart)} – ${_fmt(weekEnd)}',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textDark),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgency.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysLeft == 0
                      ? 'Last day'
                      : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                  style: AppTextStyles.caption.copyWith(
                      color: urgency, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
              final isPast = i < daysPassed;
              final isToday = i == daysPassed - 1;
              return Expanded(
                child: Column(
                  children: [
                    Text(label,
                        style: AppTextStyles.caption.copyWith(
                            color: isPast
                                ? AppColors.primaryPurple
                                : AppColors.textLight,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppColors.primaryPurple
                            : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text('Resets every Monday',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly stats card
// ---------------------------------------------------------------------------

class _WeeklyStatsCard extends StatelessWidget {
  final double thisWeekRate;
  final double lastWeekRate;
  final int thisWeekXp;
  final int bestStreak;
  final String? bestHabit;

  const _WeeklyStatsCard({
    required this.thisWeekRate,
    required this.lastWeekRate,
    required this.thisWeekXp,
    required this.bestStreak,
    required this.bestHabit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (thisWeekRate * 100).round();
    final lastPct = (lastWeekRate * 100).round();
    final diff = pct - lastPct;
    final improved = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.primaryPurpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$pct%',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('completion this week',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70)),
                  if (lastWeekRate > 0)
                    Row(
                      children: [
                        Icon(
                          improved
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: improved
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${diff.abs()}% vs last week ($lastPct%)',
                          style: AppTextStyles.caption.copyWith(
                              color: improved
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: thisWeekRate,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentGold),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.streakFire, size: 16),
                const SizedBox(width: 4),
                Text(
                  bestHabit != null
                      ? '$bestStreak-day streak'
                      : 'No streak yet',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                ),
              ]),
              const SizedBox(width: 16),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.accentGold, size: 16),
                const SizedBox(width: 4),
                Text('$thisWeekXp XP this week',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coach insight card
// ---------------------------------------------------------------------------

class _CoachInsightCard extends StatelessWidget {
  final String insight;
  final String personality;
  const _CoachInsightCard(
      {required this.insight, required this.personality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryPurple,
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(personality,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primaryPurple)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Weekly Analysis',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(insight, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Habit performance 7-day grid
// ---------------------------------------------------------------------------

class _HabitPerformanceSection extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, List<bool>> weekGrid;
  final DateTime weekStart;

  const _HabitPerformanceSection({
    required this.habits,
    required this.weekGrid,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon…6=Sun

    return Column(
      children: habits.map((h) {
        final color = AppColors.categoryColors[
            h.colorIndex.clamp(0, AppColors.categoryColors.length - 1)];
        final days = weekGrid[h.id!] ?? List.filled(7, false);
        final doneCount = days.where((d) => d).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(h.title,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              ...List.generate(7, (i) {
                final done = days[i];
                final isFuture = i > todayIndex;
                final isToday = i == todayIndex;
                return Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: done
                        ? color
                        : isFuture
                            ? Colors.transparent
                            : AppColors.lightDivider,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday && !done
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13)
                      : null,
                );
              }),
              const SizedBox(width: 8),
              Text('$doneCount/7',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textLight)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection widgets
// ---------------------------------------------------------------------------

class _EmptyReflection extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyReflection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.edit_note_rounded,
                size: 40, color: AppColors.primaryPurple),
            const SizedBox(height: 8),
            Text('Reflect on this week',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primaryPurple)),
            const SizedBox(height: 4),
            Text(
              'Capture your wins, obstacles, and focus for next week.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionSummaryCard extends StatelessWidget {
  final WeeklyReflection reflection;
  final VoidCallback onEdit;
  const _ReflectionSummaryCard(
      {required this.reflection, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reflection.winsText?.isNotEmpty == true)
            _ReflectionRow(
                icon: Icons.celebration_rounded,
                color: AppColors.accentGreen,
                label: 'Wins',
                text: reflection.winsText!),
          if (reflection.obstaclesText?.isNotEmpty == true)
            _ReflectionRow(
                icon: Icons.warning_amber_rounded,
                color: AppColors.accentGold,
                label: 'Obstacles',
                text: reflection.obstaclesText!),
          if (reflection.nextFocusText?.isNotEmpty == true)
            _ReflectionRow(
                icon: Icons.arrow_forward_rounded,
                color: AppColors.primaryPurple,
                label: 'Next Focus',
                text: reflection.nextFocusText!),
        ],
      ),
    );
  }
}

class _ReflectionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;
  const _ReflectionRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelLarge.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(text, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastReflectionTile extends StatelessWidget {
  final WeeklyReflection reflection;
  const _PastReflectionTile({required this.reflection});

  String _weekLabel(DateTime monday) {
    final end = monday.add(const Duration(days: 6));
    String m(int mo) => const [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ][mo];
    return '${m(monday.month)} ${monday.day} – ${m(end.month)} ${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(_weekLabel(reflection.weekStart),
          style:
              AppTextStyles.labelLarge.copyWith(color: AppColors.textMedium)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reflection.winsText?.isNotEmpty == true)
                _ReflectionRow(
                    icon: Icons.celebration_rounded,
                    color: AppColors.accentGreen,
                    label: 'Wins',
                    text: reflection.winsText!),
              if (reflection.obstaclesText?.isNotEmpty == true)
                _ReflectionRow(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.accentGold,
                    label: 'Obstacles',
                    text: reflection.obstaclesText!),
              if (reflection.nextFocusText?.isNotEmpty == true)
                _ReflectionRow(
                    icon: Icons.arrow_forward_rounded,
                    color: AppColors.primaryPurple,
                    label: 'Next Focus',
                    text: reflection.nextFocusText!),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reflection bottom sheet form
// ---------------------------------------------------------------------------

class _ReflectionSheet extends StatefulWidget {
  final DateTime weekStart;
  final WeeklyReflection? existing;
  const _ReflectionSheet({required this.weekStart, this.existing});

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  late final TextEditingController _winsCtrl;
  late final TextEditingController _obstaclesCtrl;
  late final TextEditingController _focusCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _winsCtrl = TextEditingController(text: widget.existing?.winsText ?? '');
    _obstaclesCtrl =
        TextEditingController(text: widget.existing?.obstaclesText ?? '');
    _focusCtrl =
        TextEditingController(text: widget.existing?.nextFocusText ?? '');
  }

  @override
  void dispose() {
    _winsCtrl.dispose();
    _obstaclesCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final reflection = WeeklyReflection(
      id: widget.existing?.id,
      weekStart: widget.weekStart,
      winsText: _winsCtrl.text.trim(),
      obstaclesText: _obstaclesCtrl.text.trim(),
      nextFocusText: _focusCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ReflectionRepository.instance.upsert(reflection);
    if (mounted) Navigator.pop(context, reflection);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Weekly Reflection', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('What happened this week?',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textLight)),
          const SizedBox(height: 20),
          _Field(
              controller: _winsCtrl,
              label: '🏆 Wins',
              hint: 'What went well this week?'),
          const SizedBox(height: 12),
          _Field(
              controller: _obstaclesCtrl,
              label: '⚡ Obstacles',
              hint: 'What got in your way?'),
          const SizedBox(height: 12),
          _Field(
              controller: _focusCtrl,
              label: '🎯 Next week focus',
              hint: 'What will you prioritise?'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Reflection'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _Field(
      {required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}
