import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mystrio/pages/leaderboard_page.dart';
import 'package:mystrio/pages/quiz_welcome_page.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForPlayerName();
    });
  }

  Future<void> _promptForPlayerName() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _playerName = nameController.text;
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
      setState(() {
        _quizCompleted = true;
        final authService = Provider.of<AuthService>(context, listen: false);
        final quizOwnerUsername = authService.username ?? 'Unknown'; // Get the current user's username

        Provider.of<QuizProvider>(context, listen: false).addLeaderboardEntryToCurrentQuiz(
          LeaderboardEntry(username: _playerName ?? 'Anonymous', score: _score),
          quizOwnerUsername, // Pass the quiz owner's username
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardPage(quizId: widget.quizId),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final quiz = quizProvider.userQuizzes.firstWhere((q) => q.id == widget.quizId);
    final theme = Theme.of(context);

    if (_playerName == null) {
      return Scaffold(
        appBar: CustomAppBar(title: quiz.name),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizCompleted) {
      // This part is now handled by navigating to the LeaderboardPage
      return Container();
    }

    final question = quiz.questions[_currentQuestionIndex];
    final answers = List<String>.from(question.answers)..shuffle();

    return Scaffold(
      appBar: CustomAppBar(
        title: quiz.name,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${quiz.questions.length}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...answers.map((answer) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(answer, quiz),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(answer),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
