import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/question_style_service.dart';

class ShareableStoryCard extends StatelessWidget {
  final Question question;
  final String username;

  const ShareableStoryCard({
    super.key,
    required this.question,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final questionStyleService = Provider.of<QuestionStyleService>(context);

    // Get the chosen question and style for the profile owner
    final String displayQuestionText = authService.chosenQuestionText ?? question.questionText;
    final QuestionStyle chosenStyle = questionStyleService.getStyleById(authService.chosenQuestionStyleId ?? 'default');

    return Container(
      width: 300, // Standard story size width
      height: 500, // Standard story size height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.secondary, width: 2),
        color: Colors.black, // Fallback background
      ),
      child: Column(
        children: [
          // Top part with gradient
          Expanded(
            flex: 2, // Takes 2/3 of the space
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: chosenStyle.gradientColors,
                  begin: chosenStyle.begin,
                  end: chosenStyle.end,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Q: $displayQuestionText',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Bottom part in white
          Expanded(
            flex: 1, // Takes 1/3 of the space
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'A: ${question.answerText ?? 'Not answered yet...'}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black87, // Dark text on white background
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      '@$username on Mystrio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600], // Subtle branding
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
