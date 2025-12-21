import 'package:flutter/material.dart';
import 'package:mystrio/services/user_question_service.dart'; // Import for AnsweredQuestion

// MODIFIED: This widget is now more generic and reusable.
class ShareableStoryCard extends StatelessWidget {
  final AnsweredQuestion question;
  final String username;
  final List<Color> gradientColors; // NEW

  const ShareableStoryCard({
    super.key,
    required this.question,
    required this.username,
    required this.gradientColors, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGradient = LinearGradient(
      colors: gradientColors, // Use the provided colors
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: 350, // A good width for social media story posts
      height: 600, // A good height for social media story posts
      decoration: BoxDecoration(
        gradient: effectiveGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymous Question Part
            Text(
              'Anonymous asked:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            // The User's Answer Part
            Text(
              'I answered:',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.answerText,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Footer with app branding
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Answered by @$username on Mystrio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
