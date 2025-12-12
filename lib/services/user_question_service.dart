import 'dart:math';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart'; // For ChangeNotifier

class UserQuestionService with ChangeNotifier {
  // This is a placeholder for a real API endpoint.
  // In a real app, you would replace this with your actual backend URL.
  static const String _baseUrl = 'https://your-backend-api.com/api';

  // In-memory mock database to simulate persistence for the current session
  // Key: code, Value: {'username': ..., 'questionText': ..., 'styleId': ..., 'replies': []}
  static final Map<String, Map<String, dynamic>> _mockDatabase = {}; // Changed to dynamic for replies

  /// Simulates saving a new question or updating an existing one on a backend.
  /// In a real application, this would make an HTTP POST/PUT request to your backend.
  /// Returns the unique code for the question.
  Future<String> saveOrUpdateQuestion({
    required String username,
    required String questionText,
    required String styleId,
    String? existingCode, // Optional: if updating an existing question
  }) async {
    debugPrint('UserQuestionService: saveOrUpdateQuestion called');
    debugPrint('  Username: $username');
    debugPrint('  Question: $questionText');
    debugPrint('  Style ID: $styleId');
    debugPrint('  Existing Code: $existingCode');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    String codeToReturn;

    if (existingCode != null && _mockDatabase.containsKey(existingCode)) {
      // Simulate updating an existing question
      _mockDatabase[existingCode]!['username'] = username;
      _mockDatabase[existingCode]!['questionText'] = questionText;
      _mockDatabase[existingCode]!['styleId'] = styleId;
      codeToReturn = existingCode;
      debugPrint('  Backend simulated: Updated question for code=$codeToReturn');
    } else {
      // Simulate creating a new question
      final random = Random();
      String newCode;
      do {
        newCode = (random.nextInt(900) + 100).toString(); // Random 3-digit code
      } while (_mockDatabase.containsKey(newCode)); // Ensure uniqueness in mock DB

      _mockDatabase[newCode] = {
        'username': username,
        'questionText': questionText,
        'styleId': styleId,
        'code': newCode, // Ensure code is stored
        'replies': [], // Initialize replies list
      };
      codeToReturn = newCode;
      debugPrint('  Backend simulated: Created new question with code=$codeToReturn');
    }
    debugPrint('  Current _mockDatabase state: $_mockDatabase');
    notifyListeners(); // Notify listeners of change
    return codeToReturn;
  }

  /// Simulates fetching a question from a backend using a unique code.
  /// This method would be used when someone opens a shared link.
  /// In a real application, this would make an HTTP GET request to your backend.
  Future<Map<String, dynamic>?> getQuestionByCode({
    required String username,
    required String code,
  }) async {
    debugPrint('UserQuestionService: getQuestionByCode called');
    debugPrint('  Username: $username');
    debugPrint('  Code: $code');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1)); // Shorter delay for fetching

    final questionData = _mockDatabase[code];

    if (questionData != null && questionData['username'] == username) {
      debugPrint('  Backend simulated response: Found question for code $code');
      return questionData;
    } else {
      debugPrint('  Backend simulated response: Question not found or username mismatch for code $code');
      return null;
    }
  }

  /// Returns all questions in the mock database.
  /// This is a helper method for the mock service.
  List<Map<String, dynamic>> getAllQuestions() {
    debugPrint('UserQuestionService: getAllQuestions called. Current _mockDatabase state: $_mockDatabase');
    return _mockDatabase.values.toList();
  }

  /// Adds an anonymous reply to a specific question.
  void addReplyToQuestion({
    required String questionCode,
    required String replyText,
  }) {
    debugPrint('UserQuestionService: addReplyToQuestion called');
    debugPrint('  Question Code: $questionCode');
    debugPrint('  Reply Text: $replyText');

    if (_mockDatabase.containsKey(questionCode)) {
      final question = _mockDatabase[questionCode]!;
      List<String> replies = List<String>.from(question['replies'] ?? []);
      replies.add(replyText);
      question['replies'] = replies;
      debugPrint('  Reply added to question $questionCode. Current replies: ${question['replies']}');
      notifyListeners(); // Notify listeners of change
    } else {
      debugPrint('  Question with code $questionCode not found. Reply not added.');
    }
  }

  /// Gets all replies for questions owned by a specific username.
  List<Map<String, String>> getRepliesForUser(String username) {
    List<Map<String, String>> userReplies = [];
    _mockDatabase.forEach((code, questionData) {
      if (questionData['username'] == username) {
        List<String> replies = List<String>.from(questionData['replies'] ?? []);
        for (String reply in replies) {
          userReplies.add({
            'questionText': questionData['questionText'] as String,
            'replyText': reply,
            'styleId': questionData['styleId'] as String,
            'questionCode': code,
          });
        }
      }
    });
    debugPrint('UserQuestionService: getRepliesForUser called for $username. Found ${userReplies.length} replies.');
    return userReplies;
  }

  /// Clears the entire mock database. Use with caution.
  void clearDatabase() {
    _mockDatabase.clear();
    debugPrint('UserQuestionService: Database cleared.');
    notifyListeners();
  }
}
