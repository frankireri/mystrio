import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Corrected import
import 'package:flutter/material.dart';
import 'package:mystrio/api/mystrio_api.dart';

class User {
  final int id;
  final String username;
  final String? displayName; // NEW: Add display name
  final String email;
  final String? chosenQuestionText;
  final String? chosenQuestionStyleId;
  final String? profileImagePath;
  final String? premiumUntil;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    this.displayName, // NEW
    required this.email,
    this.chosenQuestionText,
    this.chosenQuestionStyleId,
    this.profileImagePath,
    this.premiumUntil,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'] ?? json['display_name'], // Handle both cases
      email: json['email'],
      chosenQuestionText: json['chosenQuestionText'],
      chosenQuestionStyleId: json['chosenQuestionStyleId'],
      profileImagePath: json['profileImagePath'],
      premiumUntil: json['premiumUntil'],
      isAdmin: json['isAdmin'] == 1 || json['isAdmin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName, // NEW
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
  static const _authTokenKey = 'authToken';
  static const _currentUserDataKey = 'currentUserData';
  static const _pendingQuestionTextKey = 'pendingQuestionText';
  static const _pendingQuestionStyleIdKey = 'pendingQuestionStyleId';
  static const _pendingQuestionCodeKey = 'pendingQuestionCode';
  static const _pendingQuizNameKey = 'pendingQuizName';
  static const _pendingQuizGameTypeKey = 'pendingQuizGameType';

  String? _currentDeviceUserId;
  String? _currentDeviceUsername;
  bool _hasPermanentAccount = false;
  String? _loggedInEmail;
  String? _chosenQuestionText;
  String? _chosenQuestionStyleId;
  String? _profileImagePath;
  String? _authToken;
  bool _isLoading = true;
  User? _currentUser;

  String? _pendingQuestionText;
  String? _pendingQuestionStyleId;
  String? _pendingQuestionCode;
  String? _pendingQuizName;
  String? _pendingQuizGameType;

  final MystrioApi _api = MystrioApi();

  String? get userId => _currentDeviceUserId;
  // Use display name if available, otherwise username
  String? get username => _currentUser?.displayName ?? _currentDeviceUsername;
  // Expose the unique username (handle) separately if needed
  String? get uniqueUsername => _currentUser?.username ?? _currentDeviceUsername;
  
  bool get hasPermanentAccount => _hasPermanentAccount;
  String? get loggedInEmail => _loggedInEmail;
  String? get chosenQuestionText => _chosenQuestionText;
  String? get chosenQuestionStyleId => _chosenQuestionStyleId;
  String? get profileImagePath => _profileImagePath;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  bool get isFullyAuthenticated => _currentDeviceUsername != null && _authToken != null;

  String? get pendingQuestionText => _pendingQuestionText;
  String? get pendingQuestionStyleId => _pendingQuestionStyleId;
  String? get pendingQuestionCode => _pendingQuestionCode;
  String? get pendingQuizName => _pendingQuizName;
  String? get pendingQuizGameType => _pendingQuizGameType;

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
    _authToken = prefs.getString(_authTokenKey);

    _pendingQuestionText = prefs.getString(_pendingQuestionTextKey);
    _pendingQuestionStyleId = prefs.getString(_pendingQuestionStyleIdKey);
    _pendingQuestionCode = prefs.getString(_pendingQuestionCodeKey);
    _pendingQuizName = prefs.getString(_pendingQuizNameKey);
    _pendingQuizGameType = prefs.getString(_pendingQuizGameTypeKey);

    final userDataString = prefs.getString(_currentUserDataKey);
    if (userDataString != null) {
      _currentUser = User.fromJson(jsonDecode(userDataString));
    }

    if (_currentDeviceUserId == null) {
      _currentDeviceUserId = Uuid().v4(); // Removed const
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
    }

    if (_authToken != null && _loggedInEmail != null && _currentUser != null) {
      _hasPermanentAccount = true;
    } else {
      _hasPermanentAccount = false;
      _loggedInEmail = null;
      _authToken = null;
      _currentUser = null;
      await prefs.remove(_hasPermanentAccountKey);
      await prefs.remove(_loggedInEmailKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_currentUserDataKey);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPendingQuestion(String text, String styleId, String code) async {
    _pendingQuestionText = text;
    _pendingQuestionStyleId = styleId;
    _pendingQuestionCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingQuestionTextKey, text);
    await prefs.setString(_pendingQuestionStyleIdKey, styleId);
    await prefs.setString(_pendingQuestionCodeKey, code);
    notifyListeners();
  }

  Future<void> clearPendingQuestion() async {
    _pendingQuestionText = null;
    _pendingQuestionStyleId = null;
    _pendingQuestionCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingQuestionTextKey);
    await prefs.remove(_pendingQuestionStyleIdKey);
    await prefs.remove(_pendingQuestionCodeKey);
    notifyListeners();
  }

  Future<void> setPendingQuiz(String name, String gameType) async {
    _pendingQuizName = name;
    _pendingQuizGameType = gameType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingQuizNameKey, name);
    await prefs.setString(_pendingQuizGameTypeKey, gameType);
    notifyListeners();
  }

  Future<void> clearPendingQuiz() async {
    _pendingQuizName = null;
    _pendingQuizGameType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingQuizNameKey);
    await prefs.remove(_pendingQuizGameTypeKey);
    notifyListeners();
  }

  Future<void> setUsername(String newUsername) async {
    _currentDeviceUsername = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, newUsername);
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username, // Keep original username
        displayName: newUsername, // Update display name
        email: _currentUser!.email,
        chosenQuestionText: _currentUser!.chosenQuestionText,
        chosenQuestionStyleId: _currentUser!.chosenQuestionStyleId,
        profileImagePath: _currentUser!.profileImagePath,
        premiumUntil: _currentUser!.premiumUntil,
        isAdmin: _currentUser!.isAdmin,
      );
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));
    }
    notifyListeners();
  }

  Future<void> setChosenQuestion(String questionText, String styleId) async {
    _chosenQuestionText = questionText;
    _chosenQuestionStyleId = styleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chosenQuestionTextKey, questionText);
    await prefs.setString(_chosenQuestionStyleIdKey, styleId);

    if (_hasPermanentAccount && _currentUser != null && _authToken != null) {
      final response = await _api.updateUserProfile(
        userId: _currentUser!.id,
        authToken: _authToken!,
        chosenQuestionText: questionText,
        chosenQuestionStyleId: styleId,
      );
      if (response['success']) {
        final updatedUserData = response['data']['user'];
        if (updatedUserData != null) {
          _currentUser = User.fromJson(updatedUserData);
          await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));
        }
      }
    }
    notifyListeners();
  }

  Future<String?> uploadAndSetProfileImage(String imagePath) async {
    if (_authToken == null) {
      _profileImagePath = imagePath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, imagePath);
      notifyListeners();
      return null;
    }

    final response = await _api.uploadProfileImage(_authToken!, imagePath);

    if (response['success']) {
      final newImagePath = response['data']['filePath'];
      _profileImagePath = newImagePath;
      
      if (_currentUser != null) {
        _currentUser = User(
          id: _currentUser!.id,
          username: _currentUser!.username,
          displayName: _currentUser!.displayName,
          email: _currentUser!.email,
          chosenQuestionText: _currentUser!.chosenQuestionText,
          chosenQuestionStyleId: _currentUser!.chosenQuestionStyleId,
          profileImagePath: newImagePath,
          premiumUntil: _currentUser!.premiumUntil,
          isAdmin: _currentUser!.isAdmin,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImagePathKey, newImagePath);
        await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));
      }
      
      notifyListeners();
      return null;
    } else {
      return response['message'];
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    if (_currentDeviceUsername == null) {
      return 'Username not set.';
    }

    final response = await _api.register(
      email: email,
      password: password,
      username: _currentDeviceUsername!,
      chosenQuestionText: _chosenQuestionText,
      chosenQuestionStyleId: _chosenQuestionStyleId,
      profileImagePath: _profileImagePath,
    );

    if (response['success']) {
      final userData = response['data']['user'];
      if (userData == null) {
        return 'Failed to retrieve user data from server.';
      }

      _currentUser = User.fromJson(userData);
      _authToken = response['data']['token'];
      _hasPermanentAccount = true;
      _loggedInEmail = email;
      _currentDeviceUserId = _currentUser!.id.toString();
      _currentDeviceUsername = _currentUser!.username; // This will be the unique username from backend

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
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));

      await clearPendingQuestion();
      await clearPendingQuiz();

      notifyListeners();
      return null;
    } else {
      return response['message'];
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    final response = await _api.login(email: email, password: password);

    if (response['success']) {
      final userData = response['data']['user'];
      if (userData == null) {
        return 'Failed to retrieve user data from server.';
      }

      _currentUser = User.fromJson(userData);
      _authToken = response['data']['token'];
      _hasPermanentAccount = true;
      _loggedInEmail = email;
      _currentDeviceUserId = _currentUser!.id.toString();
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
      await prefs.setString(_currentUserDataKey, jsonEncode(_currentUser!.toJson()));

      await clearPendingQuestion();
      await clearPendingQuiz();

      notifyListeners();
      return null;
    } else {
      return response['message'];
    }
  }

  Future<void> logout() async {
    _hasPermanentAccount = false;
    _loggedInEmail = null;
    _chosenQuestionText = null;
    _chosenQuestionStyleId = null;
    _profileImagePath = null;
    _authToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  bool get hasAccount => _currentDeviceUsername != null;
}
