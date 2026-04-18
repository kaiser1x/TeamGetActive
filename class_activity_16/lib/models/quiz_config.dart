/// Holds the settings used to fetch questions from QuizAPI.
/// Created either by manual defaults or by Gemini's parseQuizIntent response.
class QuizConfig {
  final String category; // e.g. "Linux", "Code", "SQL"
  final String difficulty; // "EASY" | "MEDIUM" | "HARD" (stored uppercase)
  final String type; // always "Multiple_choice"
  final int limit; // 5–20

  const QuizConfig({
    required this.category,
    required this.difficulty,
    required this.type,
    required this.limit,
  });

  /// Sensible defaults used as fallback when Gemini is unavailable.
  factory QuizConfig.defaults() {
    return const QuizConfig(
      category: 'Code',
      difficulty: 'EASY',
      type: 'Multiple_choice',
      limit: 10,
    );
  }

  /// Parse from the JSON that Gemini returns for Natural Language Question Search.
  factory QuizConfig.fromJson(Map<String, dynamic> json) {
    return QuizConfig(
      category: json['category'] as String? ?? 'Code',
      difficulty: (json['difficulty'] as String? ?? 'EASY').toUpperCase(),
      type: json['type'] as String? ?? 'Multiple_choice',
      limit: (json['limit'] as num?)?.toInt() ?? 10,
    );
  }

  /// Converts to QuizAPI query parameters.
  /// QuizAPI expects difficulty as title-case (Easy / Medium / Hard).
  Map<String, String> toQueryParams() {
    return {
      'category': category,
      'difficulty': _difficultyForApi(),
      'type': type,
      'limit': limit.toString(),
      'random_order': 'true',
    };
  }

  String _difficultyForApi() {
    switch (difficulty.toUpperCase()) {
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  /// Human-readable label for the UI.
  String get difficultyLabel {
    switch (difficulty.toUpperCase()) {
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  QuizConfig copyWith({
    String? category,
    String? difficulty,
    String? type,
    int? limit,
  }) {
    return QuizConfig(
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      type: type ?? this.type,
      limit: limit ?? this.limit,
    );
  }
}
