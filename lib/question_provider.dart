import 'package:flutter/material.dart';
import 'package:mystrio/api/mock_api.dart';
import 'package:mystrio/auth_service.dart';

class Question {
  final String questionText;
  String? answerText;
  final bool isFromAI;
  final Map<String, String> hints; // Add hints property

  Question({
    required this.questionText,
    this.answerText,
    this.isFromAI = false,
    this.hints = const {}, // Default to an empty map
  });
}

class QuestionProvider with ChangeNotifier {
  final MockApi _api = MockApi();
  late AuthService _authService;

  List<Question> _questions = [];
  bool _isLoading = false;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;

  QuestionProvider() {
    // Add some mock answered questions for testing
    _questions.add(Question(
      questionText: 'What\'s your favorite book and why?',
      answerText: 'My favorite book is "To Kill a Mockingbird" because it beautifully explores themes of justice, prejudice, and compassion through the eyes of a child.',
      isFromAI: false,
      hints: {'device': 'Android', 'time': 'Evening', 'location': 'Home', 'mood': 'Thoughtful'},
    ));
    _questions.add(Question(
      questionText: 'If you could travel anywhere, where would you go?',
      answerText: 'I would love to visit Japan to experience its rich culture, beautiful landscapes, and incredible food. Especially during cherry blossom season!',
      isFromAI: false,
      hints: {'device': 'iOS', 'time': 'Afternoon', 'location': 'Cafe', 'mood': 'Excited'},
    ));
    _questions.add(Question(
      questionText: 'What\'s a skill you\'d like to learn?',
      answerText: 'I\'ve always wanted to learn how to play the piano. The idea of creating music with my own hands is very appealing.',
      isFromAI: false,
      hints: {'device': 'Web', 'time': 'Morning', 'location': 'Office', 'mood': 'Inspired'},
    ));
    _questions.add(Question(
      questionText: 'What\'s your biggest dream?',
      answerText: 'My biggest dream is to build a successful app that genuinely helps people connect and express themselves creatively.',
      isFromAI: false,
      hints: {'device': 'Android', 'time': 'Night', 'location': 'Bed', 'mood': 'Hopeful'},
    ));
    _questions.add(Question(
      questionText: 'What makes you truly happy?',
      answerText: 'Spending quality time with loved ones, exploring new places, and learning new things are what truly make me happy.',
      isFromAI: false,
      hints: {'device': 'iOS', 'time': 'Weekend', 'location': 'Outdoors', 'mood': 'Joyful'},
    ));
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> fetchQuestions() async {
    if (_authService.userId == null) return;
    _isLoading = true;
    notifyListeners();
    // In a real app, you'd fetch questions from a backend here.
    // For now, we'll just use the mock data.
    // _questions = await _api.getQuestions(_authService.userId!);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addQuestion(String question) async {
    if (_authService.userId == null) return;
    await _api.postQuestion(_authService.userId!, question);
    _questions.add(Question(questionText: question));
    notifyListeners();
  }

  Future<void> addAnswer(Question question, String answer) async {
    if (_authService.userId == null) return;
    await _api.postAnswer(_authService.userId!, question, answer);
    final index = _questions.indexOf(question);
    if (index != -1) {
      _questions[index].answerText = answer;
      notifyListeners();
    }
  }
}
