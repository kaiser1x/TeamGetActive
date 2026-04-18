import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/quiz_config.dart';

/// Fetches questions directly from the QuizAPI Questions endpoint.
///
/// Endpoint: GET https://quizapi.io/api/v1/questions
/// Auth:     Authorization: Bearer YOUR_KEY
/// Response: { "success": true, "data": [...], "meta": {...} }
///
/// Run with:
///   flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY
class TriviaService {
  // .trim() guards against invisible whitespace copied from the dashboard
  static final String _cleanKey =
      String.fromEnvironment('QUIZ_API_KEY').trim();
  static const String _endpoint = 'https://quizapi.io/api/v1/questions';

  static Future<List<Question>> fetchQuestions(QuizConfig config) async {
    if (_cleanKey.isEmpty) {
      throw Exception(
        'QUIZ_API_KEY is missing.\n'
        'Run with: flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY',
      );
    }

    // Build query params matching QuizAPI spec exactly
    final params = {
      'limit': config.limit.toString(),
      'type': 'MULTIPLE_CHOICE',
      'random': 'true',
      'offset': '0',
      if (config.category.isNotEmpty) 'category': config.category,
      // difficulty must be uppercase: EASY / MEDIUM / HARD / EXPERT
      if (config.difficulty.isNotEmpty) 'difficulty': config.difficulty,
    };

    final uri = Uri.parse(_endpoint).replace(queryParameters: params);

    // ── KEY DIAGNOSTICS ────────────────────────────────────────────────────
    debugPrint('=== KEY LOADED: ${_cleanKey.isNotEmpty}');
    debugPrint('=== KEY LENGTH: ${_cleanKey.length}');
    debugPrint('=== KEY PREVIEW: ${_cleanKey.substring(0, _cleanKey.length.clamp(0, 8))}...');
    debugPrint('=== KEY HAS SPACES: ${_cleanKey.contains(' ')}');
    debugPrint('=== KEY HAS ASTERISK: ${_cleanKey.contains('*')}');
    debugPrint('=== REQUEST URL: $uri');

    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $_cleanKey',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('=== STATUS: ${response.statusCode}');
    debugPrint('=== BODY: ${response.body}');

    // Handle error status codes
    if (response.statusCode == 401) {
      throw Exception(
          'Invalid QUIZ_API_KEY. Check your key at quizapi.io and try again.');
    }
    if (response.statusCode == 429) {
      throw Exception('Rate limit reached. Wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      throw Exception('QuizAPI error ${response.statusCode}. Please try again.');
    }

    // Parse response — shape: { "success": true, "data": [...], "meta": {...} }
    final dynamic decodedBody;
    try {
      decodedBody = json.decode(response.body);
    } catch (_) {
      throw Exception('Unexpected response from QuizAPI. Please try again.');
    }

    final rawList = _extractQuestionList(decodedBody);
    if (rawList == null) {
      throw Exception('Unexpected response shape from QuizAPI.');
    }

    // Check empty BEFORE parsing to give the clearest error message
    if (rawList.isEmpty) {
      throw Exception(
        'QuizAPI has no ${config.difficulty} ${config.category} questions.\n'
        'Try a lower difficulty (e.g. MEDIUM or EASY) or a different category.',
      );
    }

    final questions = rawList
        .whereType<Map<String, dynamic>>()
        .map(Question.tryParse)
        .whereType<Question>()
        .toList();

    debugPrint('=== PARSED QUESTIONS: ${questions.length}');

    if (questions.isEmpty) {
      // Questions came back but all failed to parse — field name mismatch
      throw Exception(
        'Questions loaded but could not be read.\n'
        'Try a different category or difficulty.',
      );
    }

    return questions;
  }

  static List<dynamic>? _extractQuestionList(dynamic decodedBody) {
    if (decodedBody is List) {
      return decodedBody;
    }

    if (decodedBody is Map<String, dynamic>) {
      if (decodedBody['success'] == false) {
        return null;
      }

      final data = decodedBody['data'];
      if (data is List) {
        return data;
      }
    }

    return null;
  }
}
