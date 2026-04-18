/// Represents a single trivia question returned by QuizAPI.
///
/// QuizAPI response shape:
///   id, question, category, difficulty, correct_answer (key like "answer_a"),
///   answers: { answer_a: "text", answer_b: "text", answer_c: null, … }
class Question {
  final int id;
  final String questionText;
  final String category;
  final String difficulty;
  final String correctAnswer; // actual answer text (not the key)
  final List<String> answers; // all non-null answer texts

  const Question({
    required this.id,
    required this.questionText,
    required this.category,
    required this.difficulty,
    required this.correctAnswer,
    required this.answers,
  });

  /// Parse a single question from QuizAPI JSON. Returns null if the data
  /// is malformed so callers can skip it without crashing.
  static Question? tryParse(Map<String, dynamic> json) {
    try {
      final id = (json['id'] as num?)?.toInt() ?? 0;
      final questionText =
          _decodeHtml((json['question'] as String? ?? '').trim());
      final category = json['category'] as String? ?? 'General';
      final difficulty = json['difficulty'] as String? ?? 'Easy';

      // correct_answer is a key like "answer_b"
      final correctAnswerKey = json['correct_answer'] as String? ?? '';

      final rawAnswers = json['answers'];
      final answers = <String>[];
      String correctAnswerText = '';

      if (rawAnswers is Map<String, dynamic>) {
        for (final entry in rawAnswers.entries) {
          if (entry.value is String &&
              (entry.value as String).trim().isNotEmpty) {
            final text = _decodeHtml((entry.value as String).trim());
            answers.add(text);
            if (entry.key == correctAnswerKey) {
              correctAnswerText = text;
            }
          }
        }
      }

      // Skip questions that would break the quiz experience
      if (questionText.isEmpty ||
          correctAnswerText.isEmpty ||
          answers.length < 2 ||
          !answers.contains(correctAnswerText)) {
        return null;
      }

      return Question(
        id: id,
        questionText: questionText,
        category: category,
        difficulty: difficulty,
        correctAnswer: correctAnswerText,
        answers: answers,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes common HTML entities that QuizAPI sometimes includes.
  static String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&apos;', "'");
  }
}
