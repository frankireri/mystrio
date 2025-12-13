import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:confetti/confetti.dart';
import 'package:mystrio/widgets/score_avatar.dart';
import 'package:mystrio/pages/leaderboard_page.dart';

class QuizPage extends StatefulWidget {
  final String username; // The username of the quiz owner
  final String quizId; // The ID of the quiz to play

  const QuizPage({super.key, required this.username, required this.quizId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  late ConfettiController _confettiController;
  Quiz? _quiz;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    // Load the specific quiz when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.selectQuiz(widget.quizId); // Select the quiz to ensure currentQuiz is set
      setState(() {
        _quiz = quizProvider.currentQuiz;
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _answerQuestion(String answer) {
    if (_quiz == null) return;

    final question = _quiz!.questions[_currentQuestionIndex];
    if (question.answers[question.correctAnswerIndex] == answer) {
      _score++;
    }

    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _quizCompleted = true;
        _confettiController.play();
        // Add entry to the specific quiz's leaderboard
        Provider.of<QuizProvider>(context, listen: false).addLeaderboardEntryToCurrentQuiz(
          LeaderboardEntry(username: 'Player', score: _score), // 'Player' can be replaced with actual user if logged in
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final theme = Theme.of(context);

    if (_quiz == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Loading Quiz...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectedQuizTheme = quizProvider.selectedQuizTheme;

    if (_quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Quiz for @${widget.username}',
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
          child: Center(
            child: Text('This user has not created a quiz yet.', style: theme.textTheme.bodyMedium),
          ),
        ),
      );
    }

    if (_quizCompleted) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Quiz Results',
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
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScoreAvatar(
                      score: _score,
                      totalQuestions: _quiz!.questions.length,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You scored $_score out of ${_quiz!.questions.length}!',
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeaderboardPage(quizId: widget.quizId),
                              ),
                            );
                          },
                          child: const Text('View Leaderboard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ],
          ),
        ),
      );
    }

    final question = _quiz!.questions[_currentQuestionIndex];
    final allAnswers = List<String>.from(question.answers)..shuffle();

    return Scaffold(
      appBar: CustomAppBar(
        title: _quiz!.name,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${_quiz!.questions.length}',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                question.question,
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ...allAnswers.map((answer) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(answer),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(answer),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
