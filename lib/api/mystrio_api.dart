import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mystrio/models/question.dart'; // Import the shared Question model

// The Question class definition is now in lib/models/question.dart, so we remove it here.
// class Question {
//   final String id;
//   final String questionText;
//   String? answerText;
//   final bool isFromAI;
//   final Map<String, String> hints;

//   Question({
//     required this.id,
//     required this.questionText,
//     this.answerText,
//     this.isFromAI = false,
//     this.hints = const {},
//   });

//   factory Question.fromJson(Map<String, dynamic> json) {
//     return Question(
//       id: json['id'],
//       questionText: json['questionText'],
//       answerText: json['answerText'],
//       isFromAI: json['isFromAI'] ?? false,
//       hints: Map<String, String>.from(json['hints'] ?? {}),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'questionText': questionText,
//       'answerText': answerText,
//       'isFromAI': isFromAI,
//       'hints': hints,
//     };
//   }
// }

class MystrioApi {
  final String _baseUrl = 'https://api.mystrio.top'; // Your API base URL

  // Helper to get headers, including Authorization if token is provided
  Map<String, String> _getHeaders(String? authToken) {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // Method for user registration
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? chosenQuestionText,
    String? chosenQuestionStyleId,
    String? profileImagePath,
  }) async {
    final url = Uri.parse('$_baseUrl/api/signup');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(null),
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
          'chosenQuestionText': chosenQuestionText,
          'chosenQuestionStyleId': chosenQuestionStyleId,
          'profileImagePath': profileImagePath,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Method for user login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/login');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(null),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Method to update user profile fields
  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    required String authToken,
    String? username,
    String? email,
    String? chosenQuestionText,
    String? chosenQuestionStyleId,
    String? profileImagePath,
  }) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    final Map<String, dynamic> body = {};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (chosenQuestionText != null) body['chosenQuestionText'] = chosenQuestionText;
    if (chosenQuestionStyleId != null) body['chosenQuestionStyleId'] = chosenQuestionStyleId;
    if (profileImagePath != null) body['profileImagePath'] = profileImagePath;

    if (body.isEmpty) {
      return {'success': false, 'message': 'No fields provided for update.'};
    }

    try {
      final response = await http.put(
        url,
        headers: _getHeaders(authToken),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Method to get questions for the logged-in user
  Future<Map<String, dynamic>> getQuestions({
    required String authToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/questions'); // No userId in URL, uses JWT
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(authToken),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Method to post a new question for the logged-in user
  Future<Map<String, dynamic>> postQuestion({
    required String questionText,
    required bool isFromAI,
    required Map<String, String> hints,
    required String authToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/questions');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(authToken),
        body: json.encode({
          'questionText': questionText, // Server expects camelCase
          'isFromAI': isFromAI,         // Server expects camelCase
          'hints': hints,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Method to post an answer to a question (updates existing question)
  Future<Map<String, dynamic>> postAnswer({
    required String questionId,
    required String answerText,
    required String authToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/questions/$questionId'); // PUT to question ID
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(authToken),
        body: json.encode({
          'answerText': answerText, // Server expects camelCase
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Generic method to handle API responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      return {'success': true, 'data': json.decode(response.body)};
    } else {
      // Error
      String errorMessage = 'An unknown error occurred.';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        // If response body is not JSON or message field is missing
        errorMessage = 'Server error: ${response.statusCode}';
      }
      return {'success': false, 'message': errorMessage};
    }
  }
}
