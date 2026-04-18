/// Represents a single trivia question from QuizAPI.
///
/// QuizAPI response shape per question:
/// {
///   "id": "ques_xyz789",
///   "text": "What is typeof null in JavaScript?",
///   "type": "MULTIPLE_CHOICE",
///   "difficulty": "MEDIUM",
///   "category": "Programming",
///   "answers": [
///     { "text": "object", "isCorrect": true },
///     { "text": "string", "isCorrect": false }
///   ]
/// }
class Question {
  final String id;
  final String questionText;
  final String category;
  final String difficulty;
  final String correctAnswer;
  final List<String> answers;

  const Question({
    required this.id,
    required this.questionText,
    required this.category,
    required this.difficulty,
    required this.correctAnswer,
    required this.answers,
  });

  /// Parses one question from the QuizAPI `data` array entry.
  /// Returns null if data is unusable so callers can skip it without crashing.
  static Question? tryParse(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? '';

      // Field name is "text" per QuizAPI docs
      final questionText =
          _decodeHtml((json['text'] as String? ?? '').trim());

      final category = json['category'] as String? ?? 'General';
      final difficulty = json['difficulty'] as String? ?? 'EASY';

      // answers is an array: [{ "text": "...", "isCorrect": true }, ...]
      final rawAnswers = json['answers'];
      final answers = <String>[];
      String correctAnswerText = '';

      if (rawAnswers is List) {
        for (final item in rawAnswers) {
          if (item is! Map<String, dynamic>) continue;

          // Field name is "text" per QuizAPI docs
          final text =
              _decodeHtml((item['text'] as String? ?? '').trim());
          if (text.isEmpty) continue;

          answers.add(text);

          // Correct flag is "isCorrect" (camelCase) per QuizAPI docs
          final isCorrect = item['isCorrect'];
          if (isCorrect == true) {
            correctAnswerText = text;
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
