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
  static const String _apiKey = String.fromEnvironment('QUIZ_API_KEY');
  static const String _endpoint = 'https://quizapi.io/api/v1/questions';

  static Future<List<Question>> fetchQuestions(QuizConfig config) async {
    if (_apiKey.isEmpty) {
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

    debugPrint('=== REQUEST URL: $uri');

    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $_apiKey',
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
    final Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Unexpected response from QuizAPI. Please try again.');
    }

    if (body['success'] != true) {
      throw Exception('QuizAPI returned an error. Please try again.');
    }

    final rawList = body['data'];
    if (rawList is! List) {
      throw Exception('Unexpected response shape from QuizAPI.');
    }

    final questions = rawList
        .whereType<Map<String, dynamic>>()
        .map(Question.tryParse)
        .whereType<Question>()
        .toList();

    debugPrint('=== PARSED QUESTIONS: ${questions.length}');

    if (questions.isEmpty) {
      throw Exception(
        'No valid questions found for "${config.category}" at '
        '${config.difficulty} difficulty.\n'
        'Try a different category or difficulty.',
      );
    }

    return questions;
  }
}
