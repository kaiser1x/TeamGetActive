import 'package:flutter/material.dart';

enum AnswerState { idle, correct, wrong, revealCorrect }

/// A tappable answer choice that changes appearance based on [state].
///
/// Pairs color with an icon + text label so feedback is accessible to
/// users who cannot distinguish red from green.
class AnswerButton extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerButton({
    super.key,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        button: true,
        label: _semanticLabel(),
        child: Material(
          borderRadius: BorderRadius.circular(14),
          color: _backgroundColor(),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              // Minimum 56 px height ensures a reachable touch target
              constraints: const BoxConstraints(minHeight: 56),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor(), width: 2),
              ),
              child: Row(
                children: [
                  // Icon provides a non-color indicator — important for accessibility
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: state == AnswerState.idle
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: _textColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (state) {
      case AnswerState.correct:
        return const Icon(Icons.check_circle, color: Colors.white, size: 22);
      case AnswerState.wrong:
        return const Icon(Icons.cancel, color: Colors.white, size: 22);
      case AnswerState.revealCorrect:
        return const Icon(Icons.check_circle_outline,
            color: Colors.white, size: 22);
      case AnswerState.idle:
        return Icon(Icons.circle_outlined, color: Colors.grey[400], size: 22);
    }
  }

  /// Describes the button state for screen readers — color-independent.
  String _semanticLabel() {
    switch (state) {
      case AnswerState.correct:
        return 'Correct answer: $text';
      case AnswerState.wrong:
        return 'Wrong answer selected: $text';
      case AnswerState.revealCorrect:
        return 'Correct answer was: $text';
      case AnswerState.idle:
        return 'Answer option: $text';
    }
  }

  Color _backgroundColor() {
    switch (state) {
      case AnswerState.correct:
        return const Color(0xFF388E3C); // dark green
      case AnswerState.wrong:
        return const Color(0xFFC62828); // dark red
      case AnswerState.revealCorrect:
        return const Color(0xFF2E7D32); // slightly lighter green
      case AnswerState.idle:
        return Colors.white;
    }
  }

  Color _borderColor() {
    switch (state) {
      case AnswerState.correct:
      case AnswerState.revealCorrect:
        return const Color(0xFF4CAF50);
      case AnswerState.wrong:
        return const Color(0xFFF44336);
      case AnswerState.idle:
        return const Color(0xFFBBDEFB);
    }
  }

  Color _textColor() {
    return state == AnswerState.idle ? Colors.black87 : Colors.white;
  }
}
