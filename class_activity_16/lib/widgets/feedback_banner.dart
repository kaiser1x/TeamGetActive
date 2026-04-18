import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Appears after an answer is selected and shows whether the user was
/// correct or incorrect. Uses both color AND icon/text to meet
/// accessibility guidelines (not color-only feedback).
class FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer; // shown when the user answered wrong

  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFFE8F5E9) // light green
            : const Color(0xFFFFEBEE), // light red
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SVG icon: correct.svg / incorrect.svg for non-color feedback
          SvgPicture.asset(
            isCorrect
                ? 'assets/icons/correct.svg'
                : 'assets/icons/incorrect.svg',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCorrect
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Correct answer: $correctAnswer',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
