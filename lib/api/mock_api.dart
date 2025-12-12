import 'dart:math';
import 'package:mystrio/question_provider.dart';

class MockApi {
  // Use a map to store questions for each user ID
  final Map<String, List<Question>> _userQuestions = {};

  // Predefined AI-generated questions
  static const List<String> _aiQuestions = [
    'Someone likes your vibe 😏',
    'Who was your crush? 👀',
    'What\'s your biggest secret?',
    'If you could travel anywhere, where would you go?',
    'What\'s a skill you wish you had?',
  ];

  // Helper to generate random hints
  Map<String, String> _generateRandomHints() {
    final random = Random();
    final devices = ['iPhone', 'Android', 'Web', 'iPad'];
    final locations = ['New York', 'London', 'Tokyo', 'Paris', 'Berlin'];
    final times = ['2 hours ago', '1 day ago', '3 days ago', '1 week ago'];

    return {
      'device': devices[random.nextInt(devices.length)],
      'time': times[random.nextInt(times.length)],
      'location': locations[random.nextInt(locations.length)],
      'mood': ['Happy', 'Curious', 'Playful'][random.nextInt(3)],
    };
  }

  Future<List<Question>> getQuestions(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Fetched questions for $userId');

    // If the user has no questions, initialize with some AI-generated ones
    _userQuestions.putIfAbsent(userId, () {
      return _aiQuestions.take(2).map((text) => Question(questionText: text, isFromAI: true, hints: _generateRandomHints())).toList();
    });

    // Ensure existing questions also have hints
    for (var question in _userQuestions[userId]!) {
      if (question.hints.isEmpty) {
        // Only add hints if they don't already exist
        _userQuestions[userId]![_userQuestions[userId]!.indexOf(question)] = Question(
          questionText: question.questionText,
          answerText: question.answerText,
          isFromAI: question.isFromAI,
          hints: _generateRandomHints(),
        );
      }
    }

    return _userQuestions[userId]!;
  }

  Future<void> postQuestion(String userId, String questionText) async {
    await Future.delayed(const Duration(seconds: 1));
    final questions = _userQuestions.putIfAbsent(userId, () => []);
    questions.add(Question(
      questionText: questionText,
      isFromAI: false,
      hints: _generateRandomHints(), // Add hints to new questions
    ));
    print('Posted question for $userId: $questionText');
  }

  Future<void> postAnswer(String userId, Question question, String answerText) async {
    await Future.delayed(const Duration(seconds: 1));
    final questions = _userQuestions[userId];
    if (questions != null) {
      final index = questions.indexWhere((q) => q.questionText == question.questionText);
      if (index != -1) {
        questions[index].answerText = answerText;
      }
    }
    print('Posted answer for question: ${question.questionText}');
  }
}
