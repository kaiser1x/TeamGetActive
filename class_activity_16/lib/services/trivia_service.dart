import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/quiz_config.dart';

/// Handles all communication with the QuizAPI Questions endpoint.
///
/// Run the app with:
///   flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY
class TriviaService {
  static const String _apiKey = String.fromEnvironment('QUIZ_API_KEY');

  /// Fetches and parses questions from QuizAPI.
  /// Throws a descriptive [Exception] on failure so the UI can show a
  /// friendly error message rather than crashing.
  static Future<List<Question>> fetchQuestions(QuizConfig config) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'QUIZ_API_KEY is missing.\n'
        'Run with: flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY',
      );
    }

    final params = config.toQueryParams();
    final uri = Uri.https('quizapi.io', '/api/v1/questions', params);

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        throw Exception('Invalid QUIZ_API_KEY. Check your API key and try again.');
      }
      if (response.statusCode != 200) {
        throw Exception(
          'QuizAPI error ${response.statusCode}. Please try again.',
        );
      }

      final List<dynamic> raw;
      try {
        raw = json.decode(response.body) as List<dynamic>;
      } catch (_) {
        throw Exception('Unexpected response from QuizAPI. Please try again.');
      }

      // Parse each entry, silently skip malformed ones
      final questions = raw
          .whereType<Map<String, dynamic>>()
          .map(Question.tryParse)
          .whereType<Question>() // removes nulls from tryParse
          .toList();

      if (questions.isEmpty) {
        throw Exception(
          'No valid questions found for "${config.category}" at '
          '${config.difficultyLabel} difficulty.\n'
          'Try a different category or difficulty level.',
        );
      }

      return questions;
    } on Exception {
      rethrow;
    }
  }
}
