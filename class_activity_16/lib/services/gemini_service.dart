import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_config.dart';
import '../utils/quiz_sanitizer.dart';

/// Handles two AI-powered features using Gemini 2.5 Flash:
///   1. parseQuizIntent  — Natural Language Question Search
///   2. generateReviewSummary — Smart Review Summary
///
/// Run the app with:
///   flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ───────────────────────────────────────────────────────────────────────────
  // Feature 2: Natural Language Question Search
  // ───────────────────────────────────────────────────────────────────────────

  /// Converts a free-text description (e.g. "easy Linux quiz") into a
  /// structured [QuizConfig]. Falls back to [QuizConfig.defaults()] if Gemini
  /// is unavailable or returns unparseable output.
  static Future<QuizConfig> parseQuizIntent(String userInput) async {
    if (_apiKey.isEmpty) {
      return QuizConfig.defaults();
    }

    const systemPrompt = '''
You are a quiz configuration parser. Convert the user description into quiz settings.

Return ONLY a valid JSON object — no explanation, no markdown fences:
{
  "category": "Code",
  "difficulty": "EASY",
  "type": "Multiple_choice",
  "limit": 10
}

Valid categories (use exactly): Linux, BASH, DevOps, Docker, SQL, CMS, Code, Cloud, MySQL
Valid difficulties: EASY, MEDIUM, HARD
type must always be: Multiple_choice
limit: integer 5–20, default 10

Mapping guide:
- "programming", "coding", "code" → Code
- "linux", "unix" → Linux
- "bash", "shell", "terminal" → BASH
- "sql", "database" → SQL
- "docker", "container" → Docker
- "devops", "ci/cd" → DevOps
- "cloud", "aws", "gcp", "azure" → Cloud
- "mysql" → MySQL
- "beginner", "easy" → EASY
- "intermediate", "medium" → MEDIUM
- "hard", "advanced", "expert" → HARD''';

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          '$systemPrompt\n\nConvert this: "${userInput.trim()}"'
                    }
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 150,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return QuizConfig.defaults();

      final data = json.decode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (text == null || text.isEmpty) return QuizConfig.defaults();

      final rawJson = QuizSanitizer.extractJson(text);
      final parsed = json.decode(rawJson) as Map<String, dynamic>;
      return QuizSanitizer.sanitizeConfig(QuizConfig.fromJson(parsed));
    } catch (_) {
      return QuizConfig.defaults();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Feature 1: Smart Review Summary
  // ───────────────────────────────────────────────────────────────────────────

  /// Generates a 3-5 sentence supportive study summary based on quiz results.
  /// Falls back to a locally-computed summary if Gemini fails.
  ///
  /// [performanceData] must include:
  ///   score (int), total (int), missed (int),
  ///   missedCategories (Map<String,int>), missedDifficulties (Map<String,int>)
  static Future<String> generateReviewSummary(
    Map<String, dynamic> performanceData,
  ) async {
    if (_apiKey.isEmpty) {
      return _localFallback(performanceData);
    }

    final score = performanceData['score'] as int? ?? 0;
    final total = performanceData['total'] as int? ?? 0;
    final missed = performanceData['missed'] as int? ?? 0;
    final cats =
        (performanceData['missedCategories'] as Map<String, int>?) ?? {};
    final diffs =
        (performanceData['missedDifficulties'] as Map<String, int>?) ?? {};

    final catsText = cats.entries.isEmpty
        ? 'none'
        : cats.entries.map((e) => '${e.key} (${e.value} missed)').join(', ');
    final diffsText = diffs.entries.isEmpty
        ? 'none'
        : diffs.entries.map((e) => '${e.key} (${e.value} missed)').join(', ');

    final prompt = '''
A student just finished a trivia quiz. Write a supportive, plain-English study summary.

Score: $score / $total  |  Missed: $missed questions
Weak categories: $catsText
Weak difficulty levels: $diffsText

Instructions:
- 3 to 5 sentences maximum
- Acknowledge their score warmly
- Name their weakest area from the data
- Give 1-2 concrete next study steps
- End encouragingly
- NO bullet points, NO markdown, plain text only''';

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 300,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return _localFallback(performanceData);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      return (text == null || text.isEmpty)
          ? _localFallback(performanceData)
          : text.trim();
    } catch (_) {
      return _localFallback(performanceData);
    }
  }

  /// Local fallback summary when Gemini is unavailable.
  static String _localFallback(Map<String, dynamic> data) {
    final score = data['score'] as int? ?? 0;
    final total = data['total'] as int? ?? 0;
    final cats = (data['missedCategories'] as Map<String, int>?) ?? {};

    final pct = total > 0 ? ((score / total) * 100).round() : 0;

    String topCat = '';
    if (cats.isNotEmpty) {
      final sorted = cats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key;
    }

    if (pct >= 80) {
      return 'Great job! You scored $score out of $total ($pct%). '
          '${topCat.isNotEmpty ? 'Your weakest area was $topCat — a quick review there will help you reach 100%. ' : ''}'
          'Keep practicing to lock in that knowledge!';
    } else if (pct >= 60) {
      return 'Good effort! You scored $score out of $total ($pct%). '
          '${topCat.isNotEmpty ? 'You struggled most with $topCat questions. ' : ''}'
          'Try reviewing that topic with easier questions before attempting a mixed set again.';
    } else {
      return 'You scored $score out of $total ($pct%). '
          '${topCat.isNotEmpty ? 'Most of your missed questions were in $topCat. ' : ''}'
          'Start with EASY $topCat questions to build confidence, then work your way up. You\'ve got this!';
    }
  }
}
