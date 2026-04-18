import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/quiz_config.dart';

/// Handles all communication with the QuizAPI v1 REST API.
///
/// New QuizAPI is a two-step flow:
///   Step 1 — GET /api/v1/quizzes   → pick a quiz, get its id
///   Step 2 — GET /api/v1/questions?quiz_id=ID&include_answers=true
///
/// Run the app with:
///   flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY
class TriviaService {
  static const String _apiKey = String.fromEnvironment('QUIZ_API_KEY');
  static const String _base = 'https://quizapi.io/api/v1';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  static Future<List<Question>> fetchQuestions(QuizConfig config) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'QUIZ_API_KEY is missing.\n'
        'Run with: flutter run --dart-define=QUIZ_API_KEY=YOUR_KEY',
      );
    }

    // ── Step 1: find a quiz matching category / difficulty ──────────────────
    final quizParams = {
      'limit': '10',
      if (config.category.isNotEmpty) 'category': config.category,
      if (config.difficulty.isNotEmpty)
        'difficulty': config.difficultyLabel, // "Easy" / "Medium" / "Hard"
    };

    final quizzesUri =
        Uri.parse('$_base/quizzes').replace(queryParameters: quizParams);

    final quizzesRes = await http
        .get(quizzesUri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    _checkStatus(quizzesRes);

    final quizzesBody = _decodeBody(quizzesRes.body);
    final quizList = _extractList(quizzesBody);

    if (quizList.isEmpty) {
      throw Exception(
        'No quizzes found for "${config.category}" at '
        '${config.difficultyLabel} difficulty.\n'
        'Try a different category or difficulty.',
      );
    }

    // Pick a random quiz from the results so replays feel fresh
    final quiz =
        quizList[Random().nextInt(quizList.length)] as Map<String, dynamic>;
    final quizId = quiz['id']?.toString() ?? '';

    if (quizId.isEmpty) {
      throw Exception('Could not read quiz id from QuizAPI response.');
    }

    // ── Step 2: fetch questions for that quiz ───────────────────────────────
    final questionsUri = Uri.parse('$_base/questions').replace(
      queryParameters: {
        'quiz_id': quizId,
        'include_answers': 'true',
        'limit': config.limit.toString(),
      },
    );

    final questionsRes = await http
        .get(questionsUri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    _checkStatus(questionsRes);

    final questionsBody = _decodeBody(questionsRes.body);
    final questionList = _extractList(questionsBody);

    final questions = questionList
        .whereType<Map<String, dynamic>>()
        .map(Question.tryParse)
        .whereType<Question>()
        .toList();

    if (questions.isEmpty) {
      throw Exception(
        'No valid questions found in this quiz.\n'
        'Try a different category or difficulty.',
      );
    }

    return questions;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static void _checkStatus(http.Response res) {
    if (res.statusCode == 401) {
      throw Exception(
          'Invalid QUIZ_API_KEY. Check your key at quizapi.io and try again.');
    }
    if (res.statusCode == 429) {
      throw Exception('Rate limit reached. Wait a moment and try again.');
    }
    if (res.statusCode != 200) {
      throw Exception('QuizAPI error ${res.statusCode}. Please try again.');
    }
  }

  /// Decodes JSON body — handles both List and Map (with a "data" key) shapes.
  static dynamic _decodeBody(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      throw Exception('Unexpected response from QuizAPI. Please try again.');
    }
  }

  /// Extracts a list from either a raw JSON array or a {"data": [...]} wrapper.
  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
    }
    return [];
  }
}
