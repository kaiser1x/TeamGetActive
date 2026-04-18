/// Holds the settings used to fetch questions from QuizAPI.
/// Created either by manual defaults or by Gemini's parseQuizIntent response.
class QuizConfig {
  final String category;   // e.g. "Code", "Linux", "SQL"
  final String difficulty; // "EASY" | "MEDIUM" | "HARD" | "EXPERT" (uppercase)
  final String type;       // "MULTIPLE_CHOICE"
  final int limit;         // 5–20

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
      type: 'MULTIPLE_CHOICE',
      limit: 10,
    );
  }

  /// Parse from the JSON that Gemini returns for Natural Language Question Search.
  factory QuizConfig.fromJson(Map<String, dynamic> json) {
    return QuizConfig(
      category: json['category'] as String? ?? 'Code',
      difficulty: (json['difficulty'] as String? ?? 'EASY').toUpperCase(),
      type: 'MULTIPLE_CHOICE',
      limit: (json['limit'] as num?)?.toInt() ?? 10,
    );
  }

  /// Human-readable difficulty label for the UI (title-case).
  String get difficultyLabel {
    switch (difficulty.toUpperCase()) {
      case 'MEDIUM': return 'Medium';
      case 'HARD':   return 'Hard';
      case 'EXPERT': return 'Expert';
      default:       return 'Easy';
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
