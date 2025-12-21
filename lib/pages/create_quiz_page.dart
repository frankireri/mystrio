import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/quiz_results_page.dart'; // Import the QuizResultsPage

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  late TextEditingController _quizNameController;
  final ScrollController _scrollController = ScrollController();

  // A palette of soft, pleasant colors for the question cards
  final List<Color> _cardColors = [
    Colors.orange.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
    Colors.teal.shade100,
    Colors.pink.shade100,
    Colors.amber.shade100,
  ];

  @override
  void initState() {
    super.initState();
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    _quizNameController = TextEditingController(text: quizProvider.currentQuiz?.name ?? '');

    _quizNameController.addListener(() {
      quizProvider.updateCurrentQuizName(_quizNameController.text);
    });
  }

  @override
  void dispose() {
    _quizNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final currentQuiz = quizProvider.currentQuiz!;
    final suggestedQuestions = quizProvider.getSuggestedQuestions(quizProvider.selectedQuizTheme.name);
    final random = Random();
    
    final existingQuestions = currentQuiz.questions.map((q) => q.question).toSet();
    final availableQuestions = suggestedQuestions.where((q) => !existingQuestions.contains(q.question)).toList();
    
    QuizQuestion newQuestion;
    if (availableQuestions.isNotEmpty) {
      newQuestion = availableQuestions[random.nextInt(availableQuestions.length)];
    } else {
      newQuestion = QuizQuestion(
        question: 'New Question #${currentQuiz.questions.length + 1}',
        answers: ['Correct Answer', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 0,
      );
    }
    quizProvider.addQuestionToCurrentQuiz(newQuestion);

    // Scroll to the bottom after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final currentQuiz = quizProvider.currentQuiz;
    final theme = Theme.of(context);

    if (currentQuiz == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: const CustomAppBar(
        title: 'Edit Quiz',
      ),
      body: Stack(
        children: [
          // Scrollable content
          Padding(
            padding: const EdgeInsets.only(bottom: 90.0), // Space for floating action panel
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                // Quiz Title Card
                _buildTitleCard(theme),
                const SizedBox(height: 24),
                // Question Cards
                ...List.generate(currentQuiz.questions.length, (index) {
                  return _buildQuestionCard(context, index, theme);
                }),
              ],
            ),
          ),
          // Floating Action Panel
          _buildFloatingActionPanel(context, currentQuiz.id),
        ],
      ),
    );
  }

  Widget _buildTitleCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _quizNameController,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: 'Quiz Title',
            border: InputBorder.none,
            icon: Icon(Icons.title),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int questionIndex, ThemeData theme) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final question = quizProvider.currentQuiz!.questions[questionIndex];
    final cardColor = _cardColors[questionIndex % _cardColors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0, // Use border instead of elevation for a flatter look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardColor.withOpacity(0.5), width: 1),
      ),
      color: cardColor.withOpacity(0.3), // Use a very light, translucent version of the card color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text and Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${questionIndex + 1}.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColorDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: question.question,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Your question...',
                      filled: true,
                      fillColor: Colors.grey.shade100, // Light grey background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      quizProvider.updateQuestionInCurrentQuiz(questionIndex, QuizQuestion(
                        question: value,
                        answers: question.answers,
                        correctAnswerIndex: question.correctAnswerIndex,
                      ));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete Question',
                  onPressed: () => quizProvider.removeQuestionFromCurrentQuiz(questionIndex),
                ),
              ],
            ),
            const Divider(height: 24),
            // Answer Fields
            ..._buildAnswerFields(context, questionIndex, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerFields(BuildContext context, int questionIndex, ThemeData theme) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final question = quizProvider.currentQuiz!.questions[questionIndex];

    return List.generate(question.answers.length, (index) {
      final isCorrect = index == question.correctAnswerIndex;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: () {
            quizProvider.updateQuestionInCurrentQuiz(questionIndex, QuizQuestion(
              question: question.question,
              answers: question.answers,
              correctAnswerIndex: index,
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? Colors.green.shade400 : Colors.grey.shade300,
                width: isCorrect ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCorrect ? Colors.green.shade700 : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: question.answers[index],
                    decoration: const InputDecoration.collapsed(hintText: 'Enter an option'),
                    onChanged: (value) {
                      final newAnswers = List<String>.from(question.answers);
                      newAnswers[index] = value;
                      quizProvider.updateQuestionInCurrentQuiz(questionIndex, QuizQuestion(
                        question: question.question,
                        answers: newAnswers,
                        correctAnswerIndex: question.correctAnswerIndex,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFloatingActionPanel(BuildContext context, String quizId) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Question'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizResultsPage(quizId: quizId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
