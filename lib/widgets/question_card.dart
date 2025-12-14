import 'package:flutter/material.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/models/question.dart'; // Import the Question model

class QuestionCard extends StatelessWidget {
  final Question question;
  final bool isAnswered;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const QuestionCard({
    super.key,
    required this.question,
    this.isAnswered = false,
    this.onTap,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: theme.cardTheme.elevation,
      clipBehavior: Clip.antiAlias,
      shape: theme.cardTheme.shape,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Top Section: Gradient with Question
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q: ${question.questionText}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3, // Limit to 3 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                  ),
                  if (question.isFromAI)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'From AI',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom Section: White with Answer/Actions
            Container(
              color: theme.colorScheme.surface, // White background
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAnswered) ...[
                    Text(
                      'A: ${question.answerText!}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 3, // Limit to 3 lines
                      overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'Tap to answer anonymously',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sent via Mystrio',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (isAnswered && onShare != null)
                        IconButton(
                          icon: Icon(Icons.share, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                          onPressed: onShare,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
