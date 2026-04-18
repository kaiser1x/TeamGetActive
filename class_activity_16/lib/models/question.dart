/// Represents a single trivia question returned by QuizAPI.
///
/// New QuizAPI shape (answers as array with is_correct flag):
///   id, question/content, category, difficulty,
///   answers: [ { id, content/text, is_correct }, … ]
///
/// Also handles the legacy shape (answers as a keyed map + correct_answer key)
/// in case the endpoint returns the older format.
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

  /// Parse a single question. Returns null if the data is unusable so
  /// callers can skip malformed entries without crashing.
  static Question? tryParse(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? '';

      // "question" or "content" depending on API version
      final questionText = _decodeHtml(
        ((json['question'] ?? json['content'] ?? '') as String).trim(),
      );

      final category = json['category'] as String? ?? 'General';
      final difficulty = json['difficulty'] as String? ?? 'Easy';

      final rawAnswers = json['answers'];
      final answers = <String>[];
      String correctAnswerText = '';

      if (rawAnswers is List) {
        // New format: answers is an array of objects
        // [ { "id": "...", "content": "...", "is_correct": true }, … ]
        for (final item in rawAnswers) {
          if (item is! Map<String, dynamic>) continue;
          final text = _decodeHtml(
            ((item['content'] ?? item['text'] ?? item['answer'] ?? '') as String)
                .trim(),
          );
          if (text.isEmpty) continue;
          answers.add(text);
          final isCorrect = item['is_correct'];
          if (isCorrect == true ||
              isCorrect == 1 ||
              isCorrect?.toString() == 'true' ||
              isCorrect?.toString() == '1') {
            correctAnswerText = text;
          }
        }
      } else if (rawAnswers is Map<String, dynamic>) {
        // Legacy format: { "answer_a": "text", "answer_b": "text", … }
        final correctKey = json['correct_answer'] as String? ?? '';
        for (final entry in rawAnswers.entries) {
          if (entry.value is! String) continue;
          final text = _decodeHtml((entry.value as String).trim());
          if (text.isEmpty) continue;
          answers.add(text);
          if (entry.key == correctKey) correctAnswerText = text;
        }
      }

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
