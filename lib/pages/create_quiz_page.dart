import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/quiz_results_page.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final List<Color> _cardColors = [
    Colors.orange.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
    Colors.teal.shade100,
    Colors.pink.shade100,
    Colors.amber.shade100,
    Colors.indigo.shade100,
    Colors.cyan.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Error'),
        body: const Center(child: Text('No quiz selected!')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: currentQuiz.name,
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Click the radio button next to an answer to mark it as the correct one.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currentQuiz.questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(context, index);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final suggestedQuestions = quizProvider.getSuggestedQuestions(quizProvider.selectedQuizTheme.name);
                    QuizQuestion newQuestion;

                    if (suggestedQuestions.isNotEmpty) {
                      final random = Random();
                      newQuestion = suggestedQuestions[random.nextInt(suggestedQuestions.length)];
                    } else {
                      newQuestion = QuizQuestion(
                        question: 'Your question here',
                        answers: ['Correct answer', 'Dummy 1', 'Dummy 2'],
                        correctAnswerIndex: 0,
                      );
                    }
                    quizProvider.addQuestionToCurrentQuiz(newQuestion);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add More Cards'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizResultsPage(quizId: currentQuiz.id),
                      ),
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int questionIndex) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final question = quizProvider.currentQuiz!.questions[questionIndex];
    final cardColor = _cardColors[questionIndex % _cardColors.length];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: question.question,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Question',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                final newQuestion = QuizQuestion(
                  question: value,
                  answers: question.answers,
                  correctAnswerIndex: question.correctAnswerIndex,
                );
                quizProvider.updateQuestionInCurrentQuiz(questionIndex, newQuestion);
              },
            ),
            const SizedBox(height: 16),
            ..._buildAnswerFields(context, questionIndex, cardColor),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerFields(BuildContext context, int questionIndex, Color themeColor) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final question = quizProvider.currentQuiz!.questions[questionIndex];

    return List.generate(question.answers.length, (index) {
      final isSelected = index == question.correctAnswerIndex;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final newQuestion = QuizQuestion(
                  question: question.question,
                  answers: question.answers,
                  correctAnswerIndex: index,
                );
                quizProvider.updateQuestionInCurrentQuiz(questionIndex, newQuestion);
              },
              child: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.radio_button_unchecked),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: question.answers[index],
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Answer ${index + 1}',
                  filled: true,
                  fillColor: isSelected ? Colors.green.shade50 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  final newAnswers = List<String>.from(question.answers);
                  newAnswers[index] = value;
                  final newQuestion = QuizQuestion(
                    question: question.question,
                    answers: newAnswers,
                    correctAnswerIndex: question.correctAnswerIndex,
                  );
                  quizProvider.updateQuestionInCurrentQuiz(questionIndex, newQuestion);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
