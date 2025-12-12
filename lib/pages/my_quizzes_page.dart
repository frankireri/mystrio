import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/create_quiz_page.dart';
import 'package:mystrio/pages/quiz_welcome_page.dart';
import 'package:mystrio/pages/quiz_player_page.dart';
import 'package:mystrio/pages/quiz_results_page.dart'; // Import the results page

class MyQuizzesPage extends StatelessWidget {
  const MyQuizzesPage({super.key});

  void _navigateToWelcomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizWelcomePage()),
    );
  }

  void _confirmDeleteQuiz(BuildContext context, QuizProvider quizProvider, String quizId, String quizName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "$quizName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              quizProvider.removeQuiz(quizId);
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quiz "$quizName" deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Quizzes',
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWelcomePage(context),
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Colors.white,
        child: quizProvider.userQuizzes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No quizzes created yet!',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToWelcomePage(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Your First Quiz'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizProvider.userQuizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizProvider.userQuizzes[index];
                  final quizTheme = quizProvider.themes.firstWhere(
                    (t) => t.name == quiz.selectedThemeName,
                    orElse: () => quizProvider.themes.first,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        quizProvider.selectQuiz(quiz.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateQuizPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: quizTheme.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    quiz.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white),
                                  onPressed: () => _confirmDeleteQuiz(context, quizProvider, quiz.id, quiz.name),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${quiz.questions.length} questions',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizResultsPage(quizId: quiz.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                                  label: const Text('View Results', style: TextStyle(color: Colors.white)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizPlayerPage(quizId: quiz.id),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
