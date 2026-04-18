import 'package:flutter/material.dart';
import '../models/quiz_config.dart';

/// Displays the parsed quiz settings so the user can confirm them
/// before starting. Makes the Gemini interpretation transparent and
/// gives students confidence in what they are about to practice.
class QuizConfigCard extends StatelessWidget {
  final QuizConfig config;

  const QuizConfigCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF4A90D9)),
                const SizedBox(width: 8),
                Text(
                  'Quiz Settings',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Row(
              icon: Icons.category_outlined,
              label: 'Category',
              value: config.category,
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.bar_chart_outlined,
              label: 'Difficulty',
              value: config.difficultyLabel,
              valueColor: _difficultyColor(config.difficulty),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.quiz_outlined,
              label: 'Type',
              value: 'Multiple Choice',
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.format_list_numbered,
              label: 'Questions',
              value: '${config.limit}',
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String diff) {
    switch (diff.toUpperCase()) {
      case 'MEDIUM':
        return const Color(0xFFF57C00);
      case 'HARD':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
