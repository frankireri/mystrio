import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'package:mystrio/auth_service.dart';
import 'package:uuid/uuid.dart'; // Corrected import

enum InboxItemType { questionReply, quizAnswer, anonymousQuestion }

class InboxItem {
  final String id;
  final InboxItemType type;
  final String ownerUsername;
  final String senderIdentifier;
  final String title;
  final String content;
  final DateTime timestamp;
  final int? questionId;
  final String? questionCode;
  final String? styleId;
  final String? quizId;
  final int? score;
  final int? totalQuestions;
  final bool isSentByMe;
  bool isSeen;

  InboxItem({
    required this.id,
    required this.type,
    required this.ownerUsername,
    required this.senderIdentifier,
    required this.title,
    required this.content,
    required this.timestamp,
    this.questionId,
    this.questionCode,
    this.styleId,
    this.quizId,
    this.score,
    this.totalQuestions,
    this.isSentByMe = false,
    this.isSeen = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last, // aries_test
        'ownerUsername': ownerUsername,
        'senderIdentifier': senderIdentifier,
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'questionId': questionId,
        'questionCode': questionCode,
        'styleId': styleId,
        'quizId': quizId,
        'score': score,
        'totalQuestions': totalQuestions,
        'isSentByMe': isSentByMe,
        'isSeen': isSeen,
      };

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    try {
      String typeString = (json['type'] as String?)?.replaceAll('_', '') ?? 'anonymousQuestion';
      return InboxItem(
        id: json['id']?.toString() ?? 'unknown_id',
        type: InboxItemType.values.firstWhere(
            (e) => e.toString().toLowerCase().contains(typeString.toLowerCase()),
            orElse: () => InboxItemType.anonymousQuestion),
        ownerUsername: json['ownerUsername'] ?? '',
        senderIdentifier: json['senderIdentifier'] ?? 'Someone',
        title: json['title'] ?? 'Notification',
        content: json['content'] ?? '',
        timestamp: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        questionId: json['questionId'],
        questionCode: json['relatedCode'],
        styleId: json['styleId'],
        quizId: json['quizId'],
        score: json['score'],
        totalQuestions: json['totalQuestions'],
        isSentByMe: json['isSentByMe'] ?? false,
        isSeen: json['isSeen'] == 1 || json['isSeen'] == true,
      );
    } catch (e) {
      debugPrint('Error parsing InboxItem: $e');
      debugPrint('JSON data: $json');
      // Return a placeholder item instead of crashing
      return InboxItem(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        type: InboxItemType.anonymousQuestion,
        ownerUsername: 'Error',
        senderIdentifier: 'Error',
        title: 'Error loading item',
        content: 'Could not parse notification data.',
        timestamp: DateTime.now(),
      );
    }
  }
}

class AnsweredQuestion {
  final int id;
  final int userId; // NEW: Add userId
  final String questionText;
  final String answerText;
  final DateTime answeredAt;
  final String? shortCode; // NEW: Add shortCode

  AnsweredQuestion({
    required this.id,
    required this.userId, // NEW: Require userId
    required this.questionText,
    required this.answerText,
    required this.answeredAt,
    this.shortCode, // NEW: Add shortCode
  });

  factory AnsweredQuestion.fromJson(Map<String, dynamic> json) {
    return AnsweredQuestion(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      questionText: json['question_text'] ?? '',
      answerText: json['answer_text'] ?? '',
      answeredAt: json['answered_at'] != null ? DateTime.tryParse(json['answered_at']) ?? DateTime.now() : DateTime.now(),
      shortCode: json['short_code'],
    );
  }
}

class UserQuestionService with ChangeNotifier {
  final MystrioApi _api;
  AuthService? _authService;

  AuthService? get authService => _authService;

  UserQuestionService(this._api);

  void setAuthService(AuthService authService) {
    _authService = authService;
    // Listen to auth state changes to save pending questions
    _authService?.addListener(_onAuthServiceChanged);
    _onAuthServiceChanged(); // Initial check
  }

  void _onAuthServiceChanged() async {
    if (_authService != null && _authService!.isFullyAuthenticated && _authService!.pendingQuestionCode != null) {
      debugPrint('UserQuestionService: Auth service changed, user is authenticated and has pending question. Saving...');
      final code = await saveOrUpdateQuestion(
        username: _authService!.username!,
        questionText: _authService!.pendingQuestionText!,
        styleId: _authService!.pendingQuestionStyleId!,
        existingCode: _authService!.pendingQuestionCode,
      );
      if (code != null) {
        debugPrint('UserQuestionService: Pending question saved to backend: $code');
        _authService!.clearPendingQuestion();
      } else {
        debugPrint('UserQuestionService: Failed to save pending question to backend.');
      }
    }
  }

  Future<int?> getUserIdByUsername(String username) async {
    try {
      final response = await _api.getUserIdByUsername(username);
      if (response['success'] && response['data'] != null) {
        return response['data']['id'];
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error getting user ID for $username: $e');
    }
    return null;
  }

  Future<List<InboxItem>> getInboxNotificationsForUser(String username) async {
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token available. Cannot fetch inbox notifications.');
      return [];
    }
    try {
      final response = await _api.get('/notifications', token: _authService!.authToken!);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('UserQuestionService: getInboxNotificationsForUser response data: $responseData');
        if (responseData['success'] == true) {
          var data = responseData['data'];
          if (data is Map && data.containsKey('data')) {
            data = data['data'];
          }
          if (data is List) {
            return data.whereType<Map<String, dynamic>>().map((item) => InboxItem.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error fetching inbox notifications: $e');
    }
    return [];
  }

  Future<List<AnsweredQuestion>> getAnsweredQuestions(String username) async {
    debugPrint('UserQuestionService: Attempting to fetch answered questions for $username');
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token available. Cannot fetch answered questions.');
      return [];
    }
    try {
      final response = await _api.get('/users/$username/answered-questions', token: _authService!.authToken);
      debugPrint('UserQuestionService: API call to /users/$username/answered-questions finished.');
      debugPrint('UserQuestionService: Status Code: ${response.statusCode}');
      debugPrint('UserQuestionService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> data = responseData['data'];
          debugPrint('UserQuestionService: Successfully parsed ${data.length} answered questions.');
          return data.map((item) => AnsweredQuestion.fromJson(item)).toList();
        } else {
          debugPrint('UserQuestionService: API response indicates failure or missing data: ${responseData['message']}');
          return [];
        }
      } else {
        debugPrint('UserQuestionService: API call failed with status ${response.statusCode}.');
        return [];
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error fetching answered questions: $e');
    }
    return [];
  }

  Future<bool> postAnswerToAnonymousQuestion({
    required int questionId,
    required String answerText,
  }) async {
    debugPrint('UserQuestionService: Attempting to post answer for questionId: $questionId');
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token available. Cannot post answer.');
      return false;
    }
    try {
      final response = await _api.post(
        '/questions/answer',
        token: _authService!.authToken,
        body: {'questionId': questionId, 'answerText': answerText},
      );
      debugPrint('UserQuestionService: API call to /questions/answer finished.');
      debugPrint('UserQuestionService: Status Code: ${response.statusCode}');
      debugPrint('UserQuestionService: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          notifyListeners();
          debugPrint('UserQuestionService: Answer posted successfully.');
          return true;
        } else {
          debugPrint('UserQuestionService: API response indicates failure: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('UserQuestionService: API call failed with status ${response.statusCode}.');
        return false;
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error posting answer: $e');
    }
    return false;
  }

  Future<String?> saveOrUpdateQuestion({
    required String username,
    required String questionText,
    required String styleId,
    String? existingCode,
  }) async {
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token. Storing pending question locally.');
      final newCode = existingCode ?? Uuid().v4().substring(0, 6); // Removed const
      await _authService!.setPendingQuestion(questionText, styleId, newCode);
      return newCode;
    }

    try {
      final response = await _api.post(
        '/questions/card',
        token: _authService!.authToken,
        body: {
          'questionText': questionText,
          'styleId': styleId,
          'existingCode': existingCode,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['code'];
        }
      }
    } catch (e) {
      debugPrint('Error saving question card: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQuestionByCode({
    required String username,
    required String code,
  }) async {
    // First, check if it's a pending question for the current user
    if (_authService != null && _authService!.pendingQuestionCode == code && _authService!.username == username) {
      debugPrint('UserQuestionService: Found pending question locally for code $code');
      return {
        'questionText': _authService!.pendingQuestionText,
        'styleId': _authService!.pendingQuestionStyleId,
        'code': _authService!.pendingQuestionCode,
        'username': username,
      };
    }

    try {
      final response = await _api.get('/questions/card/$code');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching question by code: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllQuestionCards() async {
    if (_authService?.authToken == null) {
      // If not authenticated, return only the pending question if it exists
      if (_authService?.pendingQuestionCode != null && _authService?.username != null) {
        return [{
          'questionText': _authService!.pendingQuestionText,
          'styleId': _authService!.pendingQuestionStyleId,
          'code': _authService!.pendingQuestionCode,
          'username': _authService!.username,
        }];
      }
      return [];
    }
    try {
      final response = await _api.get('/questions/cards/all', token: _authService!.authToken);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching all question cards: $e');
    }
    return [];
  }

  Future<bool> deleteQuestionCard(String code) async {
    final token = _authService?.authToken;
    if (token == null) {
      return false;
    }
    try {
      final response = await _api.delete('/questions/card/$code', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
    } catch (e) {
      debugPrint('Error deleting question card: $e');
    }
    return false;
  }

  Future<AnsweredQuestion?> getAnsweredQuestionById(int id) async {
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token available. Cannot fetch answered question by ID.');
      return null;
    }
    try {
      final response = await _api.get('/answered-questions/$id', token: _authService!.authToken);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return AnsweredQuestion.fromJson(responseData['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching answered question by ID: $e');
    }
    return null;
  }

  Future<AnsweredQuestion?> getAnsweredQuestionByShortCode(String shortCode) async {
    try {
      final response = await _api.get('/answered-questions/short/$shortCode');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return AnsweredQuestion.fromJson(responseData['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching answered question by short code: $e');
    }
    return null;
  }

  Future<void> addReplyToQuestion({
    required String questionCode,
    required String replyText,
    required String styleId,
  }) async {
    try {
      await _api.post(
        '/questions/card/reply',
        body: {
          'questionCode': questionCode,
          'replyText': replyText,
          'styleId': styleId,
        },
      );
    } catch (e) {
      debugPrint('Error submitting reply: $e');
    }
  }

  Future<void> addQuizAnswerNotification({
    required String quizOwnerUsername,
    required String quizTakerUsername,
    required String quizName,
    required String quizId,
    required int score,
    required int totalQuestions,
  }) async {
    // This would also be a call to the backend to create a notification
  }

  Future<String?> getUsernameById(int userId) async {
    try {
      final response = await _api.get('/users/$userId/username'); // Assuming a new backend endpoint
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data']['username'];
        }
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error getting username for ID $userId: $e');
    }
    return null;
  }

  Future<String?> getQuestionSenderHint(int questionId) async {
    if (_authService?.authToken == null) {
      debugPrint('UserQuestionService: No auth token available. Cannot fetch sender hint.');
      return null;
    }
    try {
      final response = await _api.get('/questions/$questionId/sender-hint', token: _authService!.authToken);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data']['hint'];
        } else {
          return responseData['message'];
        }
      }
    } catch (e) {
      debugPrint('UserQuestionService: Network error getting sender hint for question ID $questionId: $e');
      return 'Network error.';
    }
    return null;
  }
}
