import '../../data/models/habit.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../constants/app_constants.dart';
import '../services/prefs_service.dart';
import '../utils/streak_utils.dart';

/// Rule-based buddy message + micro-goal generator.
/// No external API calls. Generates once per day and caches in SharedPreferences.
class BuddyService {
  BuddyService._();
  static final BuddyService instance = BuddyService._();

  /// Returns today's (pep message, micro-goal). Uses cache if already generated today.
  Future<(String, String)> getMessages() async {
    if (PrefsService.instance.isBuddyMessageFresh) {
      return (
        PrefsService.instance.lastBuddyMessage ?? _fallback(),
        PrefsService.instance.lastMicroGoal ?? _fallbackGoal(),
      );
    }
    final result = await _generate();
    await PrefsService.instance.cacheMessages(result.$1, result.$2);
    return result;
  }

  /// Convenience method — returns just the pep message.
  Future<String> getMessage() async => (await getMessages()).$1;

  /// Convenience method — returns just the micro-goal.
  Future<String> getMicroGoal() async => (await getMessages()).$2;

  Future<(String, String)> _generate() async {
    final name = PrefsService.instance.userName;
    final personality = PrefsService.instance.buddyPersonality;
    final habits = await HabitRepository.instance.getAll();

    if (habits.isEmpty) {
      return (_welcomeMessage(name, personality), _welcomeGoal(personality));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = now.subtract(const Duration(days: 30));

    // Collect stats for message
    int maxStreak = 0;
    double totalRate = 0;
    for (final h in habits) {
      final logs = await LogRepository.instance.getLogsInRange(h.id!, from, now);
      final s = StreakUtils.computeStreak(logs);
      if (s > maxStreak) maxStreak = s;
      totalRate += StreakUtils.completionRate(logs, 7);
    }
    final avgRate = totalRate / habits.length;

    // Collect incomplete habits for micro-goal
    final completedToday =
        await LogRepository.instance.getCompletedHabitIdsForDate(today);
    final incomplete =
        habits.where((h) => !completedToday.contains(h.id)).toList();

    final message =
        _buildMessage(name, personality, maxStreak, avgRate, habits.length);
    final microGoal = _buildMicroGoal(name, personality, incomplete, maxStreak);

    return (message, microGoal);
  }

  // ---------------------------------------------------------------------------
  // Pep message
  // ---------------------------------------------------------------------------

  String _buildMessage(
    String name,
    String personality,
    int maxStreak,
    double avgRate,
    int habitCount,
  ) {
    final pct = (avgRate * 100).round();

    if (personality == AppConstants.buddyPersonalities[1]) {
      // Strict Trainer
      if (maxStreak == 0) return '$name, zero streak is unacceptable. Get moving — now.';
      if (pct < 50) return 'Only $pct%? $name, you\'re capable of more. No excuses.';
      if (maxStreak >= 7) return '$maxStreak days straight, $name. Acceptable. Keep the pace.';
      return '$name, $pct% this week. Push harder tomorrow.';
    }

    if (personality == AppConstants.buddyPersonalities[2]) {
      // Calm Mentor
      if (maxStreak == 0) return 'Every journey begins with a single step, $name. Begin today.';
      if (pct < 50) return 'Progress, not perfection, $name. Each small effort shapes who you become.';
      if (maxStreak >= 7) return 'A $maxStreak-day streak speaks to your commitment, $name. Stay present.';
      return 'You\'re doing meaningful work, $name. $pct% completion is a real foundation.';
    }

    if (personality == AppConstants.buddyPersonalities[3]) {
      // Playful Friend
      if (maxStreak == 0) return 'Hey $name! 👀 Your habits miss you — time to show up!';
      if (pct < 50) return '$pct%? $name you\'ve totally got this, let\'s gooo!';
      if (maxStreak >= 7) return 'SEVEN days?! $name you\'re literally unstoppable 🔥';
      return 'Look at you, $name! $pct% this week, keeping it real 💪';
    }

    // Default: Encouraging Coach
    if (maxStreak == 0) return 'Ready to start, $name? Every streak begins with today\'s first check-in!';
    if (pct < 50) return 'You\'re at $pct% this week, $name. Small wins add up — keep going!';
    if (maxStreak >= 7) return 'Incredible, $name! A $maxStreak-day streak shows real dedication. You\'re building something lasting.';
    return 'Great work, $name! $pct% completion this week across $habitCount habits. You\'re on track!';
  }

  // ---------------------------------------------------------------------------
  // Micro-goal
  // ---------------------------------------------------------------------------

  String _buildMicroGoal(
    String name,
    String personality,
    List<Habit> incomplete,
    int maxStreak,
  ) {
    if (incomplete.isEmpty) {
      return _allDoneGoal(personality);
    }

    // Pick target habit: prefer easy first for momentum
    final easy = incomplete.where((h) => h.difficulty == 'easy').toList();
    final hard = incomplete.where((h) => h.difficulty == 'hard').toList();
    final target = personality == AppConstants.buddyPersonalities[1]
        ? (hard.isNotEmpty ? hard.first : incomplete.first) // Strict Trainer attacks hard first
        : (easy.isNotEmpty ? easy.first : incomplete.first);

    final timeEst = _timeEstimate(target.difficulty);

    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'Attack "${target.title}" first — no warm-up needed. Do it now.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Begin with "${target.title}". $timeEst of focused effort is all it takes.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '🎯 Knock out "${target.title}" first — $timeEst and you\'re winning already!';
    }
    // Encouraging Coach
    if (maxStreak >= 3) {
      return 'Keep the streak alive: start with "${target.title}" ($timeEst). You\'ve got momentum!';
    }
    return 'Today\'s focus: "${target.title}" — just $timeEst. Start there and build up.';
  }

  String _allDoneGoal(String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'All done. Now think about raising the difficulty tomorrow.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'All missions complete. Take a quiet moment to acknowledge your consistency.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '🎉 All done!! You totally crushed today — treat yourself!';
    }
    return 'All missions complete! Spend 5 minutes reflecting on what went well today.';
  }

  String _timeEstimate(String difficulty) {
    switch (difficulty) {
      case 'easy':   return '5–10 min';
      case 'medium': return '15–30 min';
      case 'hard':   return '30–60 min';
      default:       return 'a few minutes';
    }
  }

  // ---------------------------------------------------------------------------
  // Welcome messages (no habits yet)
  // ---------------------------------------------------------------------------

  String _welcomeMessage(String name, String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return '$name, no habits created yet. Fix that immediately.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Welcome, $name. Add your first habit and let the journey unfold.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return 'Hey $name! Add your first habit and let\'s get this party started 🎉';
    }
    return 'Welcome, $name! Add your first habit to get started on your journey.';
  }

  String _welcomeGoal(String personality) {
    if (personality == AppConstants.buddyPersonalities[1]) {
      return 'Create at least one habit. That is today\'s only acceptable goal.';
    }
    if (personality == AppConstants.buddyPersonalities[2]) {
      return 'Micro-goal: add one habit that truly matters to you today.';
    }
    if (personality == AppConstants.buddyPersonalities[3]) {
      return '✨ Micro-goal: create your first habit and let\'s kick things off!';
    }
    return 'Micro-goal: create your first habit and check it off today!';
  }

  String _fallback() => 'Keep going — every day counts!';
  String _fallbackGoal() => 'Complete at least one habit today to build momentum.';
}
