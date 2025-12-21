import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/quiz_results_page.dart';
import 'package:mystrio/auth_service.dart'; // Import AuthService

class QuizPlayerPage extends StatefulWidget {
  final String quizId;

  const QuizPlayerPage({super.key, required this.quizId});

  @override
  State<QuizPlayerPage> createState() => _QuizPlayerPageState();
}

class _QuizPlayerPageState extends State<QuizPlayerPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to show the dialog after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the quiz first to ensure it exists and has questions before prompting for a name.
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final Quiz? quiz = quizProvider.userQuizzes.firstWhere((q) => q.id == widget.quizId);
      if (quiz != null && quiz.questions.isNotEmpty) {
        _promptForPlayerName();
      }
    });
  }

  Future<void> _promptForPlayerName() async {
    final nameController = TextEditingController();
    // Get the current user's username if they are logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isFullyAuthenticated) {
      nameController.text = authService.username ?? '';
    }

    await showDialog(
      context: context,
      barrierDismissible: false, // User must enter a name
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Your name'),
          autofocus: true,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _playerName = nameController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(String answer, Quiz quiz) {
    final question = quiz.questions[_currentQuestionIndex];
    if (question.answers[question.correctAnswerIndex] == answer) {
      setState(() {
        _score++;
      });
    }

    if (_currentQuestionIndex < quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Quiz is complete
      setState(() {
        _quizCompleted = true;
      });
      _submitScoreAndFinish(quiz);
    }
  }

  void _submitScoreAndFinish(Quiz quiz) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    // The username of the person who CREATED the quiz.
    final quizOwnerUsername = authService.username ?? 'Unknown';

    quizProvider.addLeaderboardEntryToCurrentQuiz(
      LeaderboardEntry(username: _playerName ?? 'Anonymous', score: _score),
      quizOwnerUsername,
    ).then((_) {
      // Navigate to the results page after the score has been submitted
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsPage(quizId: widget.quizId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final Quiz? quiz = quizProvider.userQuizzes.firstWhere((q) => q.id == widget.quizId);
    final theme = Theme.of(context);

    if (quiz == null) {
      return const Scaffold(body: Center(child: Text('Quiz not found.')));
    }

    // Handle quizzes with no questions gracefully.
    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: quiz.name),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'This quiz has no questions yet!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add some questions in the editor to play this quiz.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show a loading indicator while waiting for the player's name
    if (_playerName == null) {
      return Scaffold(
        appBar: CustomAppBar(title: quiz.name),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // This state is now handled by navigating away, but it's good practice to keep it.
    if (_quizCompleted) {
      return Scaffold(
        appBar: CustomAppBar(title: quiz.name),
        body: const Center(child: Text('Quiz completed! Submitting score...')),
      );
    }

    final question = quiz.questions[_currentQuestionIndex];
    // Create a shuffled list of answers for display
    final answers = List<String>.from(question.answers)..shuffle();

    return Scaffold(
      appBar: CustomAppBar(
        title: quiz.name,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            Text(
              'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Question Text
            Text(
              question.question,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Answer Buttons
            ...answers.map((answer) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(answer, quiz),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(answer, style: theme.textTheme.titleMedium),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
