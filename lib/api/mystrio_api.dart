import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mystrio/models/question.dart'; // Import the shared Question model

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

  // --- NEW: Generic HTTP Methods ---

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


  // --- Specific Methods (can be refactored to use generic methods later) ---

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

  // Method to get questions for the logged-in user
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

  // Method to post a new question for the logged-in user
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

  // Method to post an answer to a question (updates existing question)
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

  // Generic method to handle API responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      try {
        // Handle cases where the body might be empty (e.g., 204 No Content)
        if (response.body.isEmpty) {
          return {'success': true, 'data': null};
        }
        return {'success': true, 'data': json.decode(response.body)};
      } catch (e) {
        return {'success': false, 'message': 'Failed to parse server response.'};
      }
    } else {
      // Error
      String errorMessage = 'An unknown error occurred.';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['error'] ?? 'Server error: ${response.statusCode}';
      } catch (e) {
        errorMessage = 'Server error: ${response.statusCode}';
      }
      return {'success': false, 'message': errorMessage};
    }
  }
}
