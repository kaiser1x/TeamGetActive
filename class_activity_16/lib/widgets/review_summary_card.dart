import 'package:flutter/material.dart';

/// Displays the Smart Review Summary (Advanced Feature 1).
///
/// Shows a loading state while Gemini generates the summary, then renders
/// the plain-text response in a card that feels rewarding and actionable.
/// If Gemini fails, the card shows the local fallback so the screen is
/// never left blank.
class ReviewSummaryCard extends StatelessWidget {
  final bool isLoading;
  final String summaryText;

  const ReviewSummaryCard({
    super.key,
    required this.isLoading,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF3E5F5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: Color(0xFF7B1FA2), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Smart Review Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A148C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF7B1FA2),
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Generating your study summary…',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                summaryText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
