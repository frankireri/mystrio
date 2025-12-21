import 'package:flutter/material.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class QuizQuestion {
  String question;
  List<String> answers;
  int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.answers,
    this.correctAnswerIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'question_text': question,
        'options': answers,
        'correct_option_index': correctAnswerIndex,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question_text'] ?? json['question'],
        answers: json['options'] != null ? List<String>.from(json['options']) : List<String>.from(json['answers'] ?? []),
        correctAnswerIndex: json['correct_option_index'] ?? json['correctAnswerIndex'] ?? 0,
      );
}

class QuizTheme {
  final String name;
  final List<Color> gradientColors;
  final List<QuizQuestion> suggestedQuestions;

  QuizTheme({
    required this.name,
    required this.gradientColors,
    required this.suggestedQuestions,
  });
}

class LeaderboardEntry {
  final String username;
  final int score;

  LeaderboardEntry({required this.username, required this.score});

  Map<String, dynamic> toJson() => {'username': username, 'score': score};

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        username: json['username'],
        score: json['score'],
      );
}

class Quiz {
  String id;
  String name;
  String? description;
  String selectedThemeName;
  List<QuizQuestion> questions;
  List<LeaderboardEntry> leaderboard;

  Quiz({
    required this.id,
    required this.name,
    this.description,
    required this.selectedThemeName,
    required this.questions,
    required this.leaderboard,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': name, // Use 'title' for consistency
        'description': description,
        'selectedThemeName': selectedThemeName,
        'questions': questions.map((q) => q.toJson()).toList(),
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'].toString(),
        name: json['title'] ?? json['name'] ?? 'Untitled Quiz',
        description: json['description'],
        selectedThemeName: json['selectedThemeName'] ?? 'Friendship',
        questions: (json['questions'] as List? ?? []).map((q) => QuizQuestion.fromJson(q)).toList(),
        leaderboard: (json['leaderboard'] as List? ?? []).map((e) => LeaderboardEntry.fromJson(e)).toList(),
      );
}

class QuizProvider with ChangeNotifier {
  final MystrioApi _api = MystrioApi();
  late AuthService _authService;
  late UserQuestionService _userQuestionService;

  List<Quiz> _userQuizzes = [];
  Quiz? _currentQuiz;
  bool _isLoading = false;

  List<Quiz> get userQuizzes => _userQuizzes;
  Quiz? get currentQuiz => _currentQuiz;
  bool get isLoading => _isLoading;

  final List<QuizTheme> _themes = [
    QuizTheme(
      name: 'Friendship',
      gradientColors: [Colors.blue, Colors.lightBlueAccent],
      suggestedQuestions: [
        QuizQuestion(question: 'What is my favorite movie?', answers: ['The Shawshank Redemption', 'Pulp Fiction', 'Forrest Gump', 'The Godfather']),
        QuizQuestion(question: 'What is my biggest fear?', answers: ['Spiders', 'Heights', 'Public Speaking', 'Clowns']),
        QuizQuestion(question: 'What is my dream vacation destination?', answers: ['Paris', 'Tokyo', 'Bora Bora', 'Rome']),
        QuizQuestion(question: 'What is my favorite food?', answers: ['Pizza', 'Sushi', 'Tacos', 'Burgers']),
        QuizQuestion(question: 'What is my favorite hobby?', answers: ['Reading', 'Gaming', 'Hiking', 'Cooking']),
      ],
    ),
  ];
  List<QuizTheme> get themes => _themes;
  QuizTheme get selectedQuizTheme => _themes.firstWhere((theme) => theme.name == (_currentQuiz?.selectedThemeName ?? 'Friendship'));

  void setAuthService(AuthService authService) {
    _authService = authService;
    _authService.addListener(_onAuthServiceChanged);
    _onAuthServiceChanged(); // Initial check
  }

  void _onAuthServiceChanged() async {
    if (_authService.isFullyAuthenticated && _authService.pendingQuizName != null) {
      debugPrint('QuizProvider: Auth service changed, user is authenticated and has pending quiz. Saving...');
      final success = await createNewQuiz(
        _authService.pendingQuizName!,
        gameType: _authService.pendingQuizGameType!,
      );
      if (success) {
        debugPrint('QuizProvider: Pending quiz saved to backend.');
        _authService.clearPendingQuiz();
      } else {
        debugPrint('QuizProvider: Failed to save pending quiz to backend.');
      }
    }
  }

  void setUserQuestionService(UserQuestionService service) {
    _userQuestionService = service;
  }

  Future<void> fetchQuizzes() async {
    if (_authService.authToken == null) {
      debugPrint('QuizProvider: No auth token available. Cannot fetch quizzes.');
      return;
    }
    _isLoading = true;
    notifyListeners();

    final response = await _api.getQuizzes(_authService.authToken!);
    if (response['success']) {
      var data = response['data'];
      debugPrint('QuizProvider: fetchQuizzes response data type: ${data.runtimeType}');
      debugPrint('QuizProvider: fetchQuizzes response data: $data');

      // Handle double wrapping: {success: true, data: {success: true, data: [...]}}
      if (data is Map && data.containsKey('data')) {
         data = data['data'];
      }

      if (data is List) {
        _userQuizzes = data.map((json) => Quiz.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('quizzes') && data['quizzes'] is List) {
        // Handle case where list is wrapped in an object like {quizzes: [...]}
        final quizzesList = data['quizzes'] as List;
        _userQuizzes = quizzesList.map((json) => Quiz.fromJson(json)).toList();
      } else {
         debugPrint('QuizProvider: Error fetching quizzes: response data is not a list or recognized format.');
        _userQuizzes = [];
      }
    } else {
      debugPrint('QuizProvider: Error fetching quizzes: ${response['message']}');
      _userQuizzes = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createNewQuiz(String name, {String gameType = 'Friendship'}) async {
    debugPrint('QuizProvider: Attempting to create new quiz "$name" with game type "$gameType".');
    if (_authService.authToken == null) {
      debugPrint('QuizProvider: createNewQuiz failed - Auth token is null. Storing pending quiz locally.');
      await _authService.setPendingQuiz(name, gameType);
      // Create a local mock quiz for immediate display
      final theme = _themes.firstWhere((t) => t.name == gameType, orElse: () => _themes.first);
      _currentQuiz = Quiz(
        id: 'pending_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
        name: name,
        description: '',
        selectedThemeName: theme.name,
        questions: theme.suggestedQuestions,
        leaderboard: [],
      );
      notifyListeners();
      return true;
    }
    debugPrint('QuizProvider: Auth token is available.');

    final theme = _themes.firstWhere((t) => t.name == gameType, orElse: () => _themes.first);
    final newQuizData = {
      'title': name,
      'description': 'A new quiz about $gameType!', // Use the gameType in the description
      'selectedThemeName': theme.name,
      'questions': theme.suggestedQuestions.map((q) => q.toJson()).toList(),
    };
    debugPrint('QuizProvider: Creating quiz payload: $newQuizData');

    final response = await _api.createQuiz(_authService.authToken!, newQuizData);
    if (response['success']) {
      // Handle potential double wrapping in create response as well
      var responseData = response['data'];
      if (responseData is Map && responseData.containsKey('data')) {
        responseData = responseData['data'];
      }

      final quizId = responseData['quizId'] ?? responseData['id']; // Handle both potential ID fields
      
      if (quizId != null) {
         final newQuiz = Quiz(
          id: quizId.toString(),
          name: name,
          description: newQuizData['description'] as String?, // use the generated description
          selectedThemeName: theme.name,
          questions: theme.suggestedQuestions,
          leaderboard: [],
        );
        _userQuizzes.add(newQuiz);
        _currentQuiz = newQuiz;
        debugPrint('QuizProvider: Successfully created quiz with ID: ${newQuiz.id}');
        notifyListeners();
        return true;
      } else {
         debugPrint('QuizProvider: API error creating quiz: Quiz ID missing in response.');
      }
    } else {
      final errorMessage = response['error'] ?? response['message'];
      debugPrint('QuizProvider: API error creating quiz: $errorMessage');
    }
    return false;
  }

  void selectQuiz(String quizId) {
    _currentQuiz = _userQuizzes.firstWhere((quiz) => quiz.id == quizId);
    notifyListeners();
  }

  Future<void> _updateQuizOnBackend() async {
    if (_currentQuiz == null || _authService.authToken == null) {
      debugPrint('QuizProvider: Cannot update quiz on backend - currentQuiz or authToken is null.');
      return;
    }
    final response = await _api.updateQuiz(_authService.authToken!, _currentQuiz!.id, _currentQuiz!.toJson());
    if (!response['success']) {
      debugPrint('QuizProvider: Error updating quiz on backend: ${response['message']}');
    }
    notifyListeners();
  }

  void updateCurrentQuizName(String newName) {
    if (_currentQuiz != null) {
      _currentQuiz!.name = newName;
      _updateQuizOnBackend();
    }
  }

  void updateCurrentQuizDescription(String newDescription) {
    if (_currentQuiz != null) {
      _currentQuiz!.description = newDescription;
      _updateQuizOnBackend();
    }
  }

  void addQuestionToCurrentQuiz(QuizQuestion question) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions.add(question);
      _updateQuizOnBackend();
    }
  }

  void removeQuestionFromCurrentQuiz(int index) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions.removeAt(index);
      _updateQuizOnBackend();
    }
  }

  void updateQuestionInCurrentQuiz(int index, QuizQuestion question) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions[index] = question;
      _updateQuizOnBackend();
    }
  }

  Future<void> removeQuiz(String quizId) async {
    if (_authService.authToken == null) {
      debugPrint('QuizProvider: Cannot remove quiz - Auth token is null.');
      return;
    }
    final response = await _api.deleteQuiz(_authService.authToken!, quizId);
    if (response['success']) {
      _userQuizzes.removeWhere((quiz) => quiz.id == quizId);
      if (_currentQuiz?.id == quizId) {
        _currentQuiz = null;
      }
      notifyListeners();
    } else {
      debugPrint('QuizProvider: API error removing quiz: ${response['message']}');
    }
  }
  
  Future<void> addLeaderboardEntryToCurrentQuiz(LeaderboardEntry entry, String quizOwnerUsername) async {
    if (_currentQuiz == null) {
      debugPrint('QuizProvider: Cannot add leaderboard entry - currentQuiz is null.');
      return;
    }
    if (_authService.authToken == null) {
      debugPrint('QuizProvider: Cannot add leaderboard entry - authToken is null.');
      return;
    }
    
    final response = await _api.addLeaderboardEntry(_authService.authToken!, _currentQuiz!.id, entry.toJson());
    if (response['success']) {
      _currentQuiz!.leaderboard.add(entry);
      _currentQuiz!.leaderboard.sort((a, b) => b.score.compareTo(a.score));
      
      _userQuestionService.addQuizAnswerNotification(
        quizOwnerUsername: quizOwnerUsername,
        quizTakerUsername: entry.username,
        quizName: _currentQuiz!.name,
        quizId: _currentQuiz!.id,
        score: entry.score,
        totalQuestions: _currentQuiz!.questions.length,
      );
      notifyListeners();
    } else {
      debugPrint('QuizProvider: API error adding leaderboard entry: ${response['message']}');
    }
  }

  Future<void> removeLeaderboardEntry(String quizId, int entryIndex) async {
    if (_authService.authToken == null) {
      debugPrint('QuizProvider: Cannot remove leaderboard entry - Auth token is null.');
      return;
    }

    final quiz = _userQuizzes.firstWhere((q) => q.id == quizId);
    if (entryIndex >= 0 && entryIndex < quiz.leaderboard.length) {
      quiz.leaderboard.removeAt(entryIndex);
      final response = await _api.updateQuiz(_authService.authToken!, quiz.id, quiz.toJson());
      if (!response['success']) {
        debugPrint('QuizProvider: Error updating quiz after removing leaderboard entry: ${response['message']}');
      }
      notifyListeners();
    }
  }

  void setSelectedQuizTheme(String themeName) {
    if (_currentQuiz != null) {
      _currentQuiz!.selectedThemeName = themeName;
      _updateQuizOnBackend();
    }
  }

  List<QuizQuestion> getSuggestedQuestions(String themeName) {
    return _themes.firstWhere((theme) => theme.name == themeName).suggestedQuestions;
  }
}
