import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_config.dart';
import '../services/trivia_service.dart';
import '../widgets/answer_button.dart';
import '../widgets/feedback_banner.dart';
import 'result_screen.dart';

/// The main quiz gameplay screen.
///
/// Responsibilities:
///   - Fetch questions from QuizAPI using the provided [QuizConfig]
///   - Show one question at a time with shuffled multiple-choice answers
///   - Give immediate answer feedback (green correct / red wrong + icon)
///   - Track score, missed categories, and missed difficulties for the summary
///   - Navigate to [ResultScreen] after the last question
class QuizScreen extends StatefulWidget {
  final QuizConfig config;

  const QuizScreen({super.key, required this.config});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ─── Loading / error state ─────────────────────────────────────────────────
  bool _isLoadingQuestions = true;
  String? _errorMessage;

  // ─── Quiz data ─────────────────────────────────────────────────────────────
  List<Question> _questions = [];
  int _currentIndex = 0;

  // ─── Per-question answer state ─────────────────────────────────────────────
  String? _selectedAnswer;
  bool _hasAnswered = false;

  /// Cached shuffled answers for each question index.
  /// Populated once and never re-shuffled to avoid rebuilds reordering choices.
  final Map<int, List<String>> _shuffledAnswersCache = {};

  // ─── Score tracking ────────────────────────────────────────────────────────
  int _score = 0;
  final Map<String, int> _missedCategories = {};
  final Map<String, int> _missedDifficulties = {};

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
      _errorMessage = null;
    });

    try {
      final questions = await TriviaService.fetchQuestions(widget.config);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoadingQuestions = false;
          _currentIndex = 0;
          _score = 0;
          _selectedAnswer = null;
          _hasAnswered = false;
          _shuffledAnswersCache.clear();
          _missedCategories.clear();
          _missedDifficulties.clear();
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ─── Answer handling ───────────────────────────────────────────────────────

  void _selectAnswer(String answer) {
    if (_hasAnswered) return; // prevent selecting more than once

    final question = _questions[_currentIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      if (isCorrect) {
        _score++;
      } else {
        // Track missed categories and difficulties for Smart Review Summary
        _missedCategories[question.category] =
            (_missedCategories[question.category] ?? 0) + 1;
        _missedDifficulties[question.difficulty] =
            (_missedDifficulties[question.difficulty] ?? 0) + 1;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      _goToResults();
    }
  }

  void _goToResults() {
    final missed = _questions.length - _score;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          missedCategories: Map<String, int>.from(_missedCategories),
          missedDifficulties: Map<String, int>.from(_missedDifficulties),
          missed: missed,
        ),
      ),
    );
  }

  // ─── Shuffled answers (cached) ─────────────────────────────────────────────

  List<String> _getShuffledAnswers(int questionIndex) {
    if (!_shuffledAnswersCache.containsKey(questionIndex)) {
      final shuffled =
          List<String>.from(_questions[questionIndex].answers);
      shuffled.shuffle(Random());
      _shuffledAnswersCache[questionIndex] = shuffled;
    }
    return _shuffledAnswersCache[questionIndex]!;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    return _buildQuiz();
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A90D9)),
            const SizedBox(height: 20),
            Text(
              'Fetching questions…',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Could not load questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.black54, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final shuffled = _getShuffledAnswers(_currentIndex);
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category + difficulty badge row
            Row(
              children: [
                _Badge(label: question.category, color: const Color(0xFF4A90D9)),
                const SizedBox(width: 8),
                _Badge(
                  label: question.difficulty,
                  color: _difficultyColor(question.difficulty),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Answer buttons
            ...shuffled.map((answer) {
              final state = _getAnswerState(answer, question.correctAnswer);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnswerButton(
                  text: answer,
                  state: state,
                  onTap: _hasAnswered ? null : () => _selectAnswer(answer),
                ),
              );
            }),

            const SizedBox(height: 10),

            // Feedback banner — shown after answering
            if (_hasAnswered) ...[
              FeedbackBanner(
                isCorrect: _selectedAnswer == question.correctAnswer,
                correctAnswer: question.correctAnswer,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: Icon(
                      isLast ? Icons.emoji_events : Icons.arrow_forward),
                  label: Text(
                    isLast ? 'See Results' : 'Next Question',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  AnswerState _getAnswerState(String answer, String correct) {
    if (!_hasAnswered) return AnswerState.idle;
    if (answer == _selectedAnswer && answer == correct) {
      return AnswerState.correct;
    }
    if (answer == _selectedAnswer && answer != correct) {
      return AnswerState.wrong;
    }
    if (answer == correct) {
      return AnswerState.revealCorrect; // show correct after wrong selection
    }
    return AnswerState.idle;
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'medium':
        return const Color(0xFFF57C00);
      case 'hard':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF388E3C);
    }
  }
}

/// Small pill-shaped badge for category/difficulty labels.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
