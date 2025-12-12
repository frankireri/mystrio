import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/quiz_welcome_page.dart'; // Import the welcome page

class LeaderboardPage extends StatelessWidget {
  final String quizId;

  const LeaderboardPage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final theme = Theme.of(context);

    // Ensure the correct quiz is selected before accessing its properties
    quizProvider.selectQuiz(quizId);
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Error'),
        body: Center(
          child: Text(
            'Quiz not found.',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedQuizTheme = quizProvider.selectedQuizTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${currentQuiz.name} Leaderboard',
        backgroundColor: selectedQuizTheme.gradientColors[0],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedQuizTheme.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: currentQuiz.leaderboard.isEmpty
                  ? Center(
                      child: Text(
                        'No one has played this quiz yet!',
                        style: theme.textTheme.headlineSmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentQuiz.leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = currentQuiz.leaderboard[index];
                        return Card(
                          margin: theme.cardTheme.margin,
                          elevation: theme.cardTheme.elevation,
                          shape: theme.cardTheme.shape,
                          color: theme.cardTheme.color?.withOpacity(0.1),
                          child: ListTile(
                            leading: Text(
                              '#${index + 1}',
                              style: theme.textTheme.headlineSmall,
                            ),
                            title: Text(
                              entry.username,
                              style: theme.textTheme.titleLarge,
                            ),
                            trailing: Text(
                              '${entry.score} pts',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizWelcomePage()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Create Your Own Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
