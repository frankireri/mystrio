import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';

class ShareQuizPage extends StatelessWidget {
  final String quizId;

  const ShareQuizPage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final theme = Theme.of(context);
    
    // Find the quiz using the quizId. If it's not found, handle it gracefully.
    final Quiz? quiz = quizProvider.userQuizzes.firstWhere((q) => q.id == quizId);

    if (quiz == null) {
      // This is a fallback. Ideally, the user should always land here with a valid quiz.
      return Scaffold(
        appBar: const CustomAppBar(title: 'Error'),
        body: const Center(child: Text('Quiz not found. Please go back and try again.')),
      );
    }

    final quizTheme = quizProvider.themes.firstWhere(
      (t) => t.name == quiz.selectedThemeName,
      orElse: () => quizProvider.themes.first,
    );

    // The link to be shared. You can customize the domain and path.
    final shareLink = 'https://mystrio.app/play?quizId=${quiz.id}';

    return Scaffold(
      appBar: const CustomAppBar(title: 'Share Your Quiz'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your quiz is ready!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // The shareable card widget
            _buildShareCard(quiz, quizTheme, theme),
            const SizedBox(height: 32),
            // The share button
            ElevatedButton.icon(
              onPressed: () {
                final shareText = 'I just created a quiz on Mystrio! Can you beat my score?\n\n"${quiz.name}"\n\nPlay it here: $shareLink';
                Share.share(shareText, subject: 'Check out my new quiz!');
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Link'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard(Quiz quiz, QuizTheme quizTheme, ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: quizTheme.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              quiz.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [const Shadow(blurRadius: 3, color: Colors.black38)],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${quiz.questions.length} Questions',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
