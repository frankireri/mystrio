import 'package:flutter/material.dart';
import 'package:mystrio/api/mystrio_api.dart'; // Import the new API client
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/models/question.dart'; // Import the new Question model

class QuestionProvider with ChangeNotifier {
  final MystrioApi _api = MystrioApi(); // Use the new API client
  late AuthService _authService;

  List<Question> _questions = [];
  bool _isLoading = false;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;

  QuestionProvider() {
    // Removed mock answered questions from constructor.
    // These will now be fetched from the API.
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> fetchQuestions() async {
    if (_authService.userId == null || _authService.authToken == null) {
      _questions = []; // Clear questions if not authenticated
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    final response = await _api.getQuestions(
      authToken: _authService.authToken!,
    );

    if (response['success']) {
      _questions = (response['data'] as List)
          .map((json) => Question.fromJson(json))
          .toList();
    } else {
      print('Error fetching questions: ${response['message']}');
      _questions = []; // Clear questions on error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addQuestion(String questionText) async {
    if (_authService.userId == null || _authService.authToken == null) return;

    // For now, hints and isFromAI are hardcoded or derived.
    // In a real scenario, these might come from user input or backend logic.
    final response = await _api.postQuestion(
      questionText: questionText,
      isFromAI: false, // Assuming user-added questions are not AI
      hints: {}, // No hints for user-added questions initially
      authToken: _authService.authToken!,
    );

    if (response['success']) {
      // Assuming the API returns the newly created question with an ID
      _questions.add(Question.fromJson(response['data']));
      notifyListeners();
    } else {
      print('Error adding question: ${response['message']}');
    }
  }

  Future<void> addAnswer(Question question, String answerText) async {
    if (_authService.authToken == null) return;

    final response = await _api.postAnswer(
      questionId: question.id, // Use the question's ID
      answerText: answerText,
      authToken: _authService.authToken!,
    );

    if (response['success']) {
      final index = _questions.indexWhere((q) => q.id == question.id);
      if (index != -1) {
        _questions[index].answerText = answerText;
        notifyListeners();
      }
    } else {
      print('Error adding answer: ${response['message']}');
    }
  }
}
