import 'dart:convert'; // NEW: Added for jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:mystrio/api/mystrio_api.dart'; // Import the new API client

// NEW: Define a User model to hold user data, including isAdmin
class User {
  final int id;
  final String username;
  final String email;
  final String? chosenQuestionText;
  final String? chosenQuestionStyleId;
  final String? profileImagePath;
  final String? premiumUntil;
  final bool isAdmin; // NEW: isAdmin field

  User({
    required this.id,
    required this.username,
    required this.email,
    this.chosenQuestionText,
    this.chosenQuestionStyleId,
    this.profileImagePath,
    this.premiumUntil,
    this.isAdmin = false, // NEW: Default to false
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      chosenQuestionText: json['chosenQuestionText'],
      chosenQuestionStyleId: json['chosenQuestionStyleId'],
      profileImagePath: json['profileImagePath'],
      premiumUntil: json['premiumUntil'],
      isAdmin: json['isAdmin'] == 1 || json['isAdmin'] == true, // NEW: Handle int or bool
    );
  }

  // NEW: Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'chosenQuestionText': chosenQuestionText,
      'chosenQuestionStyleId': chosenQuestionStyleId,
      'profileImagePath': profileImagePath,
      'premiumUntil': premiumUntil,
      'isAdmin': isAdmin,
    };
  }
}

class AuthService with ChangeNotifier {
  static const _userIdKey = 'userId';
  static const _usernameKey = 'username';
  static const _hasPermanentAccountKey = 'hasPermanentAccount';
  static const _loggedInEmailKey = 'loggedInEmail';
  static const _chosenQuestionTextKey = 'chosenQuestionText';
  static const _chosenQuestionStyleIdKey = 'chosenQuestionStyleId';
  static const _profileImagePathKey = 'profileImagePath';
  static const _authTokenKey = 'authToken'; // Key for storing auth token
  static const _currentUserDataKey = 'currentUserData'; // NEW: Key for storing full user data

  String? _currentDeviceUserId;
  String? _currentDeviceUsername;
  bool _hasPermanentAccount = false;
  String? _loggedInEmail;
  String? _chosenQuestionText;
  String? _chosenQuestionStyleId;
  String? _profileImagePath;
  String? _authToken; // Store authentication token
  bool _isLoading = true;
  User? _currentUser; // NEW: Store the current logged-in user object

  final MystrioApi _api = MystrioApi(); // Instantiate the API client

  String? get userId => _currentDeviceUserId;
  String? get username => _currentDeviceUsername;
  bool get hasPermanentAccount => _hasPermanentAccount;
  String? get loggedInEmail => _loggedInEmail;
  String? get chosenQuestionText => _chosenQuestionText;
  String? get chosenQuestionStyleId => _chosenQuestionStyleId;
  String? get profileImagePath => _profileImagePath;
  String? get authToken => _authToken; // Getter for auth token
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser; // NEW: Getter for current user object

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currentDeviceUserId = prefs.getString(_userIdKey);
    _currentDeviceUsername = prefs.getString(_usernameKey);
    _hasPermanentAccount = prefs.getBool(_hasPermanentAccountKey) ?? false;
    _loggedInEmail = prefs.getString(_loggedInEmailKey);
    _chosenQuestionText = prefs.getString(_chosenQuestionTextKey);
    _chosenQuestionStyleId = prefs.getString(_chosenQuestionStyleIdKey);
    _profileImagePath = prefs.getString(_profileImagePathKey);
    _authToken = prefs.getString(_authTokenKey); // Load auth token

    // NEW: Load currentUser data if available
    final userDataString = prefs.getString(_currentUserDataKey);
    if (userDataString != null) {
      _currentUser = User.fromJson(jsonDecode(userDataString));
    }

    if (_currentDeviceUserId == null) {
      _currentDeviceUserId = const Uuid().v4();
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
    }

    // If an auth token exists, we can assume a permanent account is logged in
    if (_authToken != null && _loggedInEmail != null && _currentUser != null) { // NEW: Check _currentUser too
      _hasPermanentAccount = true;
      // In a real app, you'd validate the token with the backend
      // and fetch full user data here if needed.
    } else {
      _hasPermanentAccount = false;
      _loggedInEmail = null;
      _authToken = null;
      _currentUser = null; // NEW: Clear current user
      await prefs.remove(_hasPermanentAccountKey);
      await prefs.remove(_loggedInEmailKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_currentUserDataKey); // NEW: Clear user data
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUsername(String newUsername) async {
    _currentDeviceUsername = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, newUsername);
    // TODO: Consider updating username on backend if user is logged in
    if (_currentUser != null) { // NEW: Update current user object
      _currentUser = User(
        id: _currentUser!.id,
        username: newUsername,
        email: _currentUser!.email,
        chosenQuestionText: _currentUser!.chosenQuestionText,
        chosenQuestionStyleId: _currentUser!.chosenQuestionStyleId,
        profileImagePath: _currentUser!.profileImagePath,
        premiumUntil: _currentUser!.premiumUntil,
        isAdmin: _currentUser!.isAdmin,
      );
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson())); // NEW: Save updated user data
    }
    notifyListeners();
  }

  Future<void> setChosenQuestion(String questionText, String styleId) async {
    _chosenQuestionText = questionText;
    _chosenQuestionStyleId = styleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chosenQuestionTextKey, questionText);
    await prefs.setString(_chosenQuestionStyleIdKey, styleId);

    if (_hasPermanentAccount && _currentDeviceUserId != null && _authToken != null) {
      final response = await _api.updateUserProfile(
        userId: int.parse(_currentDeviceUserId!), // Assuming userId is int on backend
        authToken: _authToken!,
        chosenQuestionText: questionText,
        chosenQuestionStyleId: styleId,
      );
      if (!response['success']) {
        print('Error updating chosen question on backend: ${response['message']}');
      } else { // NEW: Update currentUser if successful
        final updatedUserData = response['data']['user'];
        if (updatedUserData != null) {
          _currentUser = User.fromJson(updatedUserData);
          await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));
        }
      }
    }
    notifyListeners();
  }

  Future<void> setProfileImagePath(String? path) async {
    _profileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_profileImagePathKey, path);
    } else {
      await prefs.remove(_profileImagePathKey);
    }

    if (_hasPermanentAccount && _currentDeviceUserId != null && _authToken != null) {
      final response = await _api.updateUserProfile(
        userId: int.parse(_currentDeviceUserId!), // Assuming userId is int on backend
        authToken: _authToken!,
        profileImagePath: path,
      );
      if (!response['success']) {
        print('Error updating profile image path on backend: ${response['message']}');
      } else { // NEW: Update currentUser if successful
        final updatedUserData = response['data']['user'];
        if (updatedUserData != null) {
          _currentUser = User.fromJson(updatedUserData);
          await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));
        }
      }
    }
    notifyListeners();
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    if (_currentDeviceUserId == null || _currentDeviceUsername == null) {
      return 'Device user ID or username not set.';
    }

    final response = await _api.register(
      email: email,
      password: password,
      username: _currentDeviceUsername!,
      chosenQuestionText: _chosenQuestionText,
      chosenQuestionStyleId: _chosenQuestionStyleId,
      profileImagePath: _profileImagePath,
    );

    print('API Register Response: $response'); // Debugging print

    if (response['success']) {
      _hasPermanentAccount = true;
      _loggedInEmail = email;
      _authToken = response['data']['token']; // Access token from 'data'
      
      // Update local state and SharedPreferences with data from API response
      final userData = response['data']['user']; // Access user from 'data' and 'user'
      
      // Check if userData is null before accessing its properties
      if (userData == null) {
        print('Error: User data is null in API response during signup.');
        return 'Failed to retrieve user data from server.';
      }

      _currentUser = User.fromJson(userData); // NEW: Set currentUser
      _currentDeviceUserId = _currentUser!.id.toString(); // Ensure it's a string
      _currentDeviceUsername = _currentUser!.username;
      _chosenQuestionText = _currentUser!.chosenQuestionText;
      _chosenQuestionStyleId = _currentUser!.chosenQuestionStyleId;
      _profileImagePath = _currentUser!.profileImagePath;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPermanentAccountKey, true);
      await prefs.setString(_loggedInEmailKey, email);
      await prefs.setString(_authTokenKey, _authToken!);
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
      await prefs.setString(_usernameKey, _currentDeviceUsername!);
      if (_chosenQuestionText != null) await prefs.setString(_chosenQuestionTextKey, _chosenQuestionText!);
      if (_chosenQuestionStyleId != null) await prefs.setString(_chosenQuestionStyleIdKey, _chosenQuestionStyleId!);
      if (_profileImagePath != null) await prefs.setString(_profileImagePathKey, _profileImagePath!);
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson())); // NEW: Save full user data

      print('Signed up: $email');
      notifyListeners();
      return null; // Success
    } else {
      return response['message']; // Return error message from API
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    final response = await _api.login(email: email, password: password);

    print('API Login Response: $response'); // Debugging print

    if (response['success']) {
      _hasPermanentAccount = true;
      _loggedInEmail = email;
      _authToken = response['data']['token']; // Access token from 'data'
      
      // Update local state and SharedPreferences with data from API response
      final userData = response['data']['user']; // Access user from 'data' and 'user'

      // Check if userData is null before accessing its properties
      if (userData == null) {
        print('Error: User data is null in API response during login.');
        return 'Failed to retrieve user data from server.';
      }

      _currentUser = User.fromJson(userData); // NEW: Set currentUser
      _currentDeviceUserId = _currentUser!.id.toString(); // Ensure it's a string
      _currentDeviceUsername = _currentUser!.username;
      _chosenQuestionText = _currentUser!.chosenQuestionText;
      _chosenQuestionStyleId = _currentUser!.chosenQuestionStyleId;
      _profileImagePath = _currentUser!.profileImagePath;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPermanentAccountKey, true);
      await prefs.setString(_loggedInEmailKey, email);
      await prefs.setString(_authTokenKey, _authToken!);
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
      await prefs.setString(_usernameKey, _currentDeviceUsername!);
      if (_chosenQuestionText != null) await prefs.setString(_chosenQuestionTextKey, _chosenQuestionText!);
      if (_chosenQuestionStyleId != null) await prefs.setString(_chosenQuestionStyleIdKey, _chosenQuestionStyleId!);
      if (_profileImagePath != null) await prefs.setString(_profileImagePathKey, _profileImagePath!);
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson())); // NEW: Save full user data

      print('Logged in: $email');
      notifyListeners();
      return null; // Success
    } else {
      return response['message']; // Return error message from API
    }
  }

  Future<void> logout() async {
    _hasPermanentAccount = false;
    _loggedInEmail = null;
    _chosenQuestionText = null;
    _chosenQuestionStyleId = null;
    _profileImagePath = null;
    _authToken = null; // Clear auth token on logout
    _currentUser = null; // NEW: Clear current user object

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasPermanentAccountKey);
    await prefs.remove(_loggedInEmailKey);
    await prefs.remove(_chosenQuestionTextKey);
    await prefs.remove(_chosenQuestionStyleIdKey);
    await prefs.remove(_profileImagePathKey);
    await prefs.remove(_authTokenKey); // Remove auth token from storage
    await prefs.remove(_currentUserDataKey); // NEW: Remove user data from storage

    print('Logged out.');
    notifyListeners();
  }

  bool get hasAccount => _currentDeviceUsername != null;
}
