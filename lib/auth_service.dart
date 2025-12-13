import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

// Mock User class for our in-memory "database"
class MockUser {
  final String email;
  final String password;
  final String userId; // The device-based ID linked to this permanent account
  String username; // The chosen username
  String? chosenQuestionText; // New: User's chosen default question
  String? chosenQuestionStyleId; // New: User's chosen style for the question card
  String? profileImagePath; // New: User's chosen profile image path

  MockUser({
    required this.email,
    required this.password,
    required this.userId,
    required this.username,
    this.chosenQuestionText,
    this.chosenQuestionStyleId,
    this.profileImagePath,
  });
}

class AuthService with ChangeNotifier {
  static const _userIdKey = 'userId';
  static const _usernameKey = 'username';
  static const _hasPermanentAccountKey = 'hasPermanentAccount';
  static const _loggedInEmailKey = 'loggedInEmail';
  static const _chosenQuestionTextKey = 'chosenQuestionText';
  static const _chosenQuestionStyleIdKey = 'chosenQuestionStyleId';
  static const _profileImagePathKey = 'profileImagePath'; // New key

  String? _currentDeviceUserId;
  String? _currentDeviceUsername;
  bool _hasPermanentAccount = false;
  String? _loggedInEmail;
  String? _chosenQuestionText;
  String? _chosenQuestionStyleId;
  String? _profileImagePath; // New property
  bool _isLoading = true;

  // Our in-memory "database" of mock users
  final List<MockUser> _mockUsers = [];

  String? get userId => _currentDeviceUserId;
  String? get username => _currentDeviceUsername;
  bool get hasPermanentAccount => _hasPermanentAccount;
  String? get loggedInEmail => _loggedInEmail;
  String? get chosenQuestionText => _chosenQuestionText;
  String? get chosenQuestionStyleId => _chosenQuestionStyleId;
  String? get profileImagePath => _profileImagePath; // New getter
  bool get isLoading => _isLoading;

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
    _profileImagePath = prefs.getString(_profileImagePathKey); // Load profile image path

    if (_currentDeviceUserId == null) {
      _currentDeviceUserId = const Uuid().v4();
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
    }

    if (_loggedInEmail != null) {
      _hasPermanentAccount = true;
      // In a real app, you'd fetch user data from backend using _loggedInEmail
      // and update other properties from there.
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUsername(String newUsername) async {
    _currentDeviceUsername = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, newUsername);
    notifyListeners();
  }

  Future<void> setChosenQuestion(String questionText, String styleId) async {
    _chosenQuestionText = questionText;
    _chosenQuestionStyleId = styleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chosenQuestionTextKey, questionText);
    await prefs.setString(_chosenQuestionStyleIdKey, styleId);
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
    notifyListeners();
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_mockUsers.any((user) => user.email == email)) {
      return 'Email already in use.';
    }

    if (_currentDeviceUserId == null || _currentDeviceUsername == null) {
      return 'Device user ID or username not set.';
    }

    final newUser = MockUser(
      email: email,
      password: password,
      userId: _currentDeviceUserId!,
      username: _currentDeviceUsername!,
      chosenQuestionText: _chosenQuestionText,
      chosenQuestionStyleId: _chosenQuestionStyleId,
      profileImagePath: _profileImagePath,
    );
    _mockUsers.add(newUser);

    _hasPermanentAccount = true;
    _loggedInEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPermanentAccountKey, true);
    await prefs.setString(_loggedInEmailKey, email);

    print('Signed up: ${newUser.email} with device ID: ${newUser.userId}');
    notifyListeners();
    return null;
  }

  Future<String?> loginWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final user = _mockUsers.firstWhereOrNull(
      (user) => user.email == email && user.password == password,
    );

    if (user == null) {
      return 'Invalid email or password.';
    }

    if (_currentDeviceUserId != user.userId) {
      _currentDeviceUserId = user.userId;
      _currentDeviceUsername = user.username;
      _chosenQuestionText = user.chosenQuestionText;
      _chosenQuestionStyleId = user.chosenQuestionStyleId;
      _profileImagePath = user.profileImagePath; // Load profile image path

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, _currentDeviceUserId!);
      await prefs.setString(_usernameKey, _currentDeviceUsername!);
      if (_chosenQuestionText != null) await prefs.setString(_chosenQuestionTextKey, _chosenQuestionText!);
      if (_chosenQuestionStyleId != null) await prefs.setString(_chosenQuestionStyleIdKey, _chosenQuestionStyleId!);
      if (_profileImagePath != null) await prefs.setString(_profileImagePathKey, _profileImagePath!);
    } else {
      _currentDeviceUsername = user.username;
      _chosenQuestionText = user.chosenQuestionText;
      _chosenQuestionStyleId = user.chosenQuestionStyleId;
      _profileImagePath = user.profileImagePath; // Load profile image path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, _currentDeviceUsername!);
      if (_chosenQuestionText != null) await prefs.setString(_chosenQuestionTextKey, _chosenQuestionText!);
      if (_chosenQuestionStyleId != null) await prefs.setString(_chosenQuestionStyleIdKey, _chosenQuestionStyleId!);
      if (_profileImagePath != null) await prefs.setString(_profileImagePathKey, _profileImagePath!);
    }

    _hasPermanentAccount = true;
    _loggedInEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPermanentAccountKey, true);
    await prefs.setString(_loggedInEmailKey, email);

    print('Logged in: ${user.email}');
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _hasPermanentAccount = false;
    _loggedInEmail = null;
    _chosenQuestionText = null;
    _chosenQuestionStyleId = null;
    _profileImagePath = null; // Clear profile image on logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasPermanentAccountKey);
    await prefs.remove(_loggedInEmailKey);
    await prefs.remove(_chosenQuestionTextKey);
    await prefs.remove(_chosenQuestionStyleIdKey);
    await prefs.remove(_profileImagePathKey);
    print('Logged out.');
    notifyListeners();
  }

  bool get hasAccount => _currentDeviceUsername != null;
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
