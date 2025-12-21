import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/create_quiz_page.dart';
import 'package:mystrio/pages/quiz_welcome_page.dart';
import 'package:mystrio/pages/quiz_player_page.dart';
import 'package:mystrio/pages/quiz_results_page.dart';

class MyQuizzesPage extends StatefulWidget {
  const MyQuizzesPage({super.key});

  @override
  State<MyQuizzesPage> createState() => _MyQuizzesPageState();
}

class _MyQuizzesPageState extends State<MyQuizzesPage> {
  void _navigateToWelcomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizWelcomePage()),
    );
  }

  void _confirmDeleteQuiz(BuildContext context, QuizProvider quizProvider, String quizId, String quizName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "$quizName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog first
              quizProvider.removeQuiz(quizId).then((_) {
                // Check if the widget is still mounted before showing a SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Quiz "$quizName" deleted.')),
                  );
                }
              });
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
      appBar: const CustomAppBar(
        title: 'My Quizzes',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToWelcomePage,
        tooltip: 'Create New Quiz',
        child: const Icon(Icons.add),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return provider.userQuizzes.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildQuizList(context, theme, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Quizzes Yet!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to create your first quiz.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList(BuildContext context, ThemeData theme, QuizProvider quizProvider) {
    return ListView.builder(
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
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: quizTheme.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Dark overlay for better text contrast
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Title and Popup Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            quiz.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(blurRadius: 2, color: Colors.black26)
                              ],
                            ),
                          ),
                        ),
                        _buildPopupMenu(context, quizProvider, quiz),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Question Count
                    Text(
                      '${quiz.questions.length} Questions',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _actionButton(
                          context,
                          icon: Icons.bar_chart,
                          label: 'Results',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QuizResultsPage(quizId: quiz.id)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          context,
                          icon: Icons.play_circle_outline,
                          label: 'Play',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QuizPlayerPage(quizId: quiz.id)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupMenu(BuildContext context, QuizProvider quizProvider, Quiz quiz) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          quizProvider.selectQuiz(quiz.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateQuizPage()),
          );
        } else if (value == 'delete') {
          _confirmDeleteQuiz(context, quizProvider, quiz.id, quiz.name);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert, color: Colors.white),
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.white.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
