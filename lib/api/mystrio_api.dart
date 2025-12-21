import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mystrio/models/question.dart';
import 'package:http_parser/http_parser.dart'; // NEW: For multipart file content type
import 'package:flutter/foundation.dart'; // Import for debugPrint

class MystrioApi {
  final String _baseUrl = 'https://api.mystrio.top';

  Map<String, String> _getHeaders(String? authToken) {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // --- Generic HTTP Methods ---
  // (get, post, put, delete methods remain the same)
  Future<http.Response> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl/api$endpoint');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> post(String endpoint, {String? token, Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl/api$endpoint');
    return await http.post(url, headers: _getHeaders(token), body: json.encode(body));
  }

  Future<http.Response> put(String endpoint, {required String token, Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl/api$endpoint');
    return await http.put(url, headers: _getHeaders(token), body: json.encode(body));
  }

  Future<http.Response> delete(String endpoint, {required String token}) async {
    final url = Uri.parse('$_baseUrl/api$endpoint');
    return await http.delete(url, headers: _getHeaders(token));
  }

  // --- User & Auth Methods ---
  // (register, login, getUserIdByUsername, updateUserProfile remain the same)
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

  Future<Map<String, dynamic>> getUserIdByUsername(String username) async {
    final url = Uri.parse('$_baseUrl/api/users/by-username/$username');
    try {
      final response = await http.get(url, headers: _getHeaders(null));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    required String authToken,
    String? username,
    String? email,
    String? chosenQuestionText,
    String? chosenQuestionStyleId,
    String? profileImagePath,
  }) async {
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
      final response = await put('/users/$userId', token: authToken, body: body);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // NEW: Method to upload a profile image
  Future<Map<String, dynamic>> uploadProfileImage(String authToken, String imagePath) async {
    final url = Uri.parse('$_baseUrl/api/users/profile-image');
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $authToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage', // This 'field' name must match your backend's expectation
          imagePath,
          contentType: MediaType('image', 'jpeg'), // Or 'png', etc.
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error during image upload: $e'};
    }
  }

  // --- Styled Question Methods ---
  // (getQuestions, postQuestion, postAnswer remain the same)
  Future<Map<String, dynamic>> getQuestions({
    required String authToken,
  }) async {
    try {
      final response = await get('/questions', token: authToken);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> postQuestion({
    required String questionText,
    required bool isFromAI,
    required Map<String, String> hints,
    required String authToken,
  }) async {
    try {
      final response = await post('/questions', token: authToken, body: {
        'questionText': questionText,
        'isFromAI': isFromAI,
        'hints': hints,
      });
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> postAnswer({
    required String questionId,
    required String answerText,
    required String authToken,
  }) async {
    try {
      final response = await put('/questions/$questionId', token: authToken, body: {
        'answerText': answerText,
      });
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Quiz Methods ---
  // (getQuizzes, createQuiz, updateQuiz, deleteQuiz remain the same)
  Future<Map<String, dynamic>> getQuizzes(String authToken) async {
    try {
      final response = await get('/quizzes', token: authToken);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createQuiz(String authToken, Map<String, dynamic> quizData) async {
    try {
      final response = await post('/quizzes', token: authToken, body: quizData);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateQuiz(String authToken, String quizId, Map<String, dynamic> quizData) async {
    try {
      final response = await put('/quizzes/$quizId', token: authToken, body: quizData);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteQuiz(String authToken, String quizId) async {
    try {
      final response = await delete('/quizzes/$quizId', token: authToken);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Leaderboard Methods ---
  // (getLeaderboard, addLeaderboardEntry remain the same)
  Future<Map<String, dynamic>> getLeaderboard(String quizId) async {
    try {
      final response = await get('/quizzes/$quizId/leaderboard');
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addLeaderboardEntry(String authToken, String quizId, Map<String, dynamic> entryData) async {
    try {
      final response = await post('/quizzes/$quizId/leaderboard', token: authToken, body: entryData);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Generic Response Handler ---
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true, 'data': null};
        }
        return {'success': true, 'data': json.decode(response.body)};
      } catch (e) {
        return {'success': false, 'message': 'Failed to parse server response.'};
      }
    } else {
      debugPrint('API Error: Raw response body: ${response.body}'); // Log raw response
      String errorMessage = 'An unknown error occurred.';
      String? errorDetails;
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? 'Server error: ${response.statusCode}';
        errorDetails = errorData['error'];
      } catch (e) {
        errorMessage = 'Server error: ${response.statusCode}';
      }
      return {'success': false, 'message': errorMessage, 'error': errorDetails};
    }
  }
}
