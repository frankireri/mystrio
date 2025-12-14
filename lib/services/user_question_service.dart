import 'dart:math';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart'; // For ChangeNotifier

enum InboxItemType { questionReply, quizAnswer }

class InboxItem {
  final String id;
  final InboxItemType type;
  final String ownerUsername; // The user who owns the question/quiz
  final String senderIdentifier; // The anonymous sender (e.g., "Someone")
  final String title; // e.g., "Your question: What's your dream?" or "Your quiz: Fun Facts"
  final String content; // e.g., "A: My dream is..." or "Scored 8/10"
  final DateTime timestamp;
  final String? questionCode; // For question replies
  final String? styleId; // For question replies
  final String? quizId; // For quiz answers
  final int? score; // For quiz answers
  final int? totalQuestions; // For quiz answers

  InboxItem({
    required this.id,
    required this.type,
    required this.ownerUsername,
    required this.senderIdentifier,
    required this.title,
    required this.content,
    required this.timestamp,
    this.questionCode,
    this.styleId,
    this.quizId,
    this.score,
    this.totalQuestions,
  });
}

class UserQuestionService with ChangeNotifier {
  // This is a placeholder for a real API endpoint.
  // In a real app, you would replace this with your actual backend URL.
  static const String _baseUrl = 'https://your-backend-api.com/api';

  // In-memory mock database to simulate persistence for the current session
  // Key: code, Value: {'username': ..., 'questionText': ..., 'styleId': ...}
  static final Map<String, Map<String, dynamic>> _mockQuestions = {};

  // In-memory mock for inbox notifications
  // List of all notifications, each containing its type and data
  static final List<InboxItem> _inboxNotifications = [];

  final Random _random = Random(); // For randomizing messages

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

    if (existingCode != null && _mockQuestions.containsKey(existingCode)) {
      // Simulate updating an existing question
      _mockQuestions[existingCode]!['username'] = username;
      _mockQuestions[existingCode]!['questionText'] = questionText;
      _mockQuestions[existingCode]!['styleId'] = styleId;
      codeToReturn = existingCode;
      debugPrint('  Backend simulated: Updated question for code=$codeToReturn');
    } else {
      // Simulate creating a new question
      String newCode;
      do {
        newCode = (_random.nextInt(900) + 100).toString(); // Random 3-digit code
      } while (_mockQuestions.containsKey(newCode)); // Ensure uniqueness in mock DB

      _mockQuestions[newCode] = {
        'username': username,
        'questionText': questionText,
        'styleId': styleId,
        'code': newCode, // Ensure code is stored
      };
      codeToReturn = newCode;
      debugPrint('  Backend simulated: Created new question with code=$codeToReturn');
    }
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
    await Future.delayed(const Duration(milliseconds: 500)); // Shorter delay for fetching

    final questionData = _mockQuestions[code];

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
    debugPrint('UserQuestionService: getAllQuestions called. Current _mockQuestions state: $_mockQuestions');
    return _mockQuestions.values.toList();
  }

  /// Adds an anonymous reply to a specific question.
  void addReplyToQuestion({
    required String questionCode,
    required String replyText,
  }) {
    debugPrint('UserQuestionService: addReplyToQuestion called');
    debugPrint('  Question Code: $questionCode');
    debugPrint('  Reply Text: $replyText');

    if (_mockQuestions.containsKey(questionCode)) {
      final questionOwnerUsername = _mockQuestions[questionCode]!['username'] as String;
      final questionText = _mockQuestions[questionCode]!['questionText'] as String;
      final styleId = _mockQuestions[questionCode]!['styleId'] as String;

      _inboxNotifications.add(
        InboxItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
          type: InboxItemType.questionReply,
          ownerUsername: questionOwnerUsername,
          senderIdentifier: 'Someone', // Anonymous sender
          title: 'Reply to your question:',
          content: replyText,
          timestamp: DateTime.now(),
          questionCode: questionCode,
          styleId: styleId,
        ),
      );
      debugPrint('  Reply added to inbox for $questionOwnerUsername. Current notifications: ${_inboxNotifications.length}');
      notifyListeners(); // Notify listeners of change
    } else {
      debugPrint('  Question with code $questionCode not found. Reply not added.');
    }
  }

  /// Adds a quiz answer notification to the inbox.
  void addQuizAnswerNotification({
    required String quizOwnerUsername,
    required String quizTakerUsername,
    required String quizName,
    required String quizId,
    required int score,
    required int totalQuestions,
  }) {
    debugPrint('UserQuestionService: addQuizAnswerNotification called');
    debugPrint('  Quiz Owner: $quizOwnerUsername');
    debugPrint('  Quiz Taker: $quizTakerUsername');
    debugPrint('  Quiz Name: $quizName');
    debugPrint('  Score: $score/$totalQuestions');

    final List<String> curiousTitles = [
      'Someone just answered your quiz!',
      'You won\'t believe who took your quiz!',
      'A new score is in for "$quizName"!',
      'Curiosity piqued: "$quizName" has a new result!',
      'Someone\'s been testing their knowledge of you!',
    ];

    final List<String> curiousContents = [
      'Find out how $quizTakerUsername did on your quiz!',
      'See what $quizTakerUsername scored on "$quizName"!',
      'A new challenger has emerged! Check $quizTakerUsername\'s score.',
      'Was it your best friend? Your crush? See $quizTakerUsername\'s result!',
      'The results are in for $quizTakerUsername on "$quizName".',
    ];

    final String randomTitle = curiousTitles[_random.nextInt(curiousTitles.length)];
    final String randomContent = curiousContents[_random.nextInt(curiousContents.length)];

    _inboxNotifications.add(
      InboxItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
        type: InboxItemType.quizAnswer,
        ownerUsername: quizOwnerUsername,
        senderIdentifier: quizTakerUsername, // Quiz taker is not anonymous
        title: randomTitle,
        content: randomContent,
        timestamp: DateTime.now(),
        quizId: quizId,
        score: score,
        totalQuestions: totalQuestions,
      ),
    );
    debugPrint('  Quiz answer added to inbox for $quizOwnerUsername. Current notifications: ${_inboxNotifications.length}');
    notifyListeners();
  }

  /// Gets all inbox notifications for a specific user.
  List<InboxItem> getInboxNotificationsForUser(String username) {
    final userNotifications = _inboxNotifications
        .where((item) => item.ownerUsername == username)
        .toList();
    // Sort by timestamp, newest first
    userNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    debugPrint('UserQuestionService: getInboxNotificationsForUser called for $username. Found ${userNotifications.length} notifications.');
    return userNotifications;
  }

  /// Clears the entire mock database. Use with caution.
  void clearDatabase() {
    _mockQuestions.clear();
    _inboxNotifications.clear();
    debugPrint('UserQuestionService: All mock data cleared.');
    notifyListeners();
  }
}
