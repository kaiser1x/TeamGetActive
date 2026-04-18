import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/quiz_config.dart';
import '../services/gemini_service.dart';
import '../utils/quiz_constants.dart';
import '../widgets/quiz_config_card.dart';
import 'quiz_screen.dart';

/// The entry screen for the quiz app.
///
/// Provides the Natural Language Question Search feature (Advanced Feature 2):
/// - User types what they want to practice in plain English
/// - Gemini 2.5 Flash interprets the text and returns structured quiz settings
/// - The interpreted settings are shown in a QuizConfigCard for confirmation
/// - Pressing "Start Quiz" passes the QuizConfig to QuizScreen
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isParsingIntent = false;
  QuizConfig? _parsedConfig;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Natural Language Question Search ─────────────────────────────────────

  Future<void> _findQuiz() async {
    final text = _inputController.text.trim();
    _focusNode.unfocus();

    // If empty, fall back to defaults so the student can still start
    if (text.isEmpty) {
      setState(() => _parsedConfig = QuizConfig.defaults());
      return;
    }

    setState(() {
      _isParsingIntent = true;
      _parsedConfig = null;
    });

    final config = await GeminiService.parseQuizIntent(text);

    if (mounted) {
      setState(() {
        _isParsingIntent = false;
        _parsedConfig = config;
      });
    }
  }

  void _startQuiz() {
    final config = _parsedConfig ?? QuizConfig.defaults();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(config: config)),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App header
              _buildHeader(theme),
              const SizedBox(height: 32),

              // NL search field + examples
              _buildSearchSection(theme),
              const SizedBox(height: 20),

              // "Find Quiz" button
              _buildFindQuizButton(),
              const SizedBox(height: 24),

              // Parsed config card (visible after Gemini responds)
              if (_parsedConfig != null) ...[
                QuizConfigCard(config: _parsedConfig!),
                const SizedBox(height: 20),
                _buildStartButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // loading.svg: clarifies the purpose of this screen —
        // you are about to search for quiz questions
        SvgPicture.asset(
          'assets/images/loading.svg',
          width: 110,
          height: 110,
        ),
        const SizedBox(height: 16),
        Text(
          'Trivia Quiz',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us what you want to practice\nand we\'ll build a quiz for you.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you want to practice?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _inputController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'e.g. "easy Linux questions"',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90D9)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBBDEFB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF4A90D9), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _findQuiz(),
          maxLines: 1,
        ),
        const SizedBox(height: 10),
        // Sample prompts help students understand what kinds of input work
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: QuizConstants.examplePrompts
              .take(3)
              .map(
                (p) => GestureDetector(
                  onTap: () {
                    // Strip surrounding quotes before inserting
                    _inputController.text =
                        p.replaceAll('"', '');
                    _inputController.selection =
                        TextSelection.fromPosition(
                      TextPosition(
                          offset: _inputController.text.length),
                    );
                  },
                  child: Chip(
                    label: Text(
                      p,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: const Color(0xFFE3F2FD),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFindQuizButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isParsingIntent ? null : _findQuiz,
        icon: _isParsingIntent
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isParsingIntent ? 'Thinking…' : 'Find Quiz',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90D9),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _startQuiz,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'Start Quiz',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
      ),
    );
  }
}
