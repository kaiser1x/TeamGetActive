import '../models/quiz_config.dart';
import 'quiz_constants.dart';

/// Helpers to safely extract JSON from Gemini responses and validate
/// quiz config values before they reach the API.
class QuizSanitizer {
  /// Extracts the first `{ … }` block from a string that may include
  /// markdown fences or surrounding explanation text.
  static String extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return '{}';
    return text.substring(start, end + 1);
  }

  /// Validates every field of a QuizConfig, replacing invalid values
  /// with safe defaults so the API call never receives garbage.
  static QuizConfig sanitizeConfig(QuizConfig config) {
    // Accept the category only if it is in the known valid list
    final category = QuizConstants.categories.contains(config.category)
        ? config.category
        : 'Code';

    // Difficulty must be EASY / MEDIUM / HARD / EXPERT
    final difficulty =
        QuizConstants.difficulties.contains(config.difficulty.toUpperCase())
            ? config.difficulty.toUpperCase()
            : 'EASY';

    // QuizAPI type value per docs
    const type = 'MULTIPLE_CHOICE';

    // Keep limit in a sensible range
    final limit = config.limit.clamp(5, 20);

    return QuizConfig(
      category: category,
      difficulty: difficulty,
      type: type,
      limit: limit,
    );
  }
}
