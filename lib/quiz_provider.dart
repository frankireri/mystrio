import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        'question': question,
        'answers': answers,
        'correctAnswerIndex': correctAnswerIndex,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<String> answers;
    int correctAnswerIndex = json['correctAnswerIndex'] ?? 0;

    if (json.containsKey('answers')) {
      answers = List<String>.from(json['answers']);
    } else if (json.containsKey('correctAnswer')) {
      answers = [
        json['correctAnswer'],
        ...(json['dummyAnswers'] as List<dynamic>).cast<String>(),
      ];
    } else {
      answers = ['Default Answer 1', 'Default Answer 2', 'Default Answer 3'];
    }

    return QuizQuestion(
      question: json['question'] ?? 'Default Question',
      answers: answers,
      correctAnswerIndex: correctAnswerIndex,
    );
  }
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

  Map<String, dynamic> toJson() => {
        'username': username,
        'score': score,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        username: json['username'],
        score: json['score'],
      );
}

class Quiz {
  String id; // Unique ID for the quiz
  String name;
  String selectedThemeName;
  List<QuizQuestion> questions;
  List<LeaderboardEntry> leaderboard;

  Quiz({
    required this.id,
    required this.name,
    required this.selectedThemeName,
    required this.questions,
    required this.leaderboard,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selectedThemeName': selectedThemeName,
        'questions': questions.map((q) => q.toJson()).toList(),
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'],
        name: json['name'],
        selectedThemeName: json['selectedThemeName'],
        questions: (json['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
        leaderboard: (json['leaderboard'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList(),
      );
}

class QuizProvider with ChangeNotifier {
  static const _quizzesKey = 'user_quizzes';

  List<Quiz> _userQuizzes = [];
  Quiz? _currentQuiz; // The quiz currently being edited/viewed

  final List<QuizTheme> _themes = [
    QuizTheme(
      name: 'Friendship',
      gradientColors: [Colors.blue, Colors.lightBlueAccent],
      suggestedQuestions: [
        QuizQuestion(question: 'What is my favorite movie?', answers: ['The Shawshank Redemption', 'Pulp Fiction', 'Forrest Gump']),
        QuizQuestion(question: 'What is my biggest fear?', answers: ['Heights', 'Spiders', 'Public Speaking']),
        QuizQuestion(question: 'Where did we first meet?', answers: ['Coffee Shop', 'School', 'Party']),
        QuizQuestion(question: 'What\'s my go-to comfort food?', answers: ['Pizza', 'Ice Cream', 'Pasta']),
        QuizQuestion(question: 'What\'s my dream vacation spot?', answers: ['Maldives', 'Paris', 'Tokyo']),
        QuizQuestion(question: 'What\'s my favorite season?', answers: ['Autumn', 'Spring', 'Summer']),
        QuizQuestion(question: 'What\'s my favorite animal?', answers: ['Dog', 'Cat', 'Elephant']),
        QuizQuestion(question: 'What is my hidden talent?', answers: ['Juggling', 'Singing', 'Magic Tricks']),
        QuizQuestion(question: 'What is my favorite book?', answers: ['To Kill a Mockingbird', '1984', 'The Great Gatsby']),
        QuizQuestion(question: 'What is my favorite song?', answers: ['Bohemian Rhapsody', 'Stairway to Heaven', 'Hotel California']),
      ],
    ),
    QuizTheme(
      name: 'This or That',
      gradientColors: [Colors.purple, Colors.deepPurpleAccent],
      suggestedQuestions: [
        QuizQuestion(question: 'Coffee or Tea?', answers: ['Coffee', 'Tea', 'Both']),
        QuizQuestion(question: 'Movies or Books?', answers: ['Movies', 'Books', 'Both']),
        QuizQuestion(question: 'Cats or Dogs?', answers: ['Cats', 'Dogs', 'Both']),
        QuizQuestion(question: 'Beach or Mountains?', answers: ['Beach', 'Mountains', 'Both']),
        QuizQuestion(question: 'Sweet or Savory?', answers: ['Sweet', 'Savory', 'Both']),
        QuizQuestion(question: 'Early Bird or Night Owl?', answers: ['Early Bird', 'Night Owl', 'Neither']),
        QuizQuestion(question: 'Summer or Winter?', answers: ['Summer', 'Winter', 'Neither']),
        QuizQuestion(question: 'City or Countryside?', answers: ['City', 'Countryside', 'Both']),
        QuizQuestion(question: 'Android or iOS?', answers: ['Android', 'iOS', 'Neither']),
        QuizQuestion(question: 'Pizza or Tacos?', answers: ['Pizza', 'Tacos', 'Both']),
      ],
    ),
    QuizTheme(
      name: 'Spicy',
      gradientColors: [Colors.red, Colors.orange],
      suggestedQuestions: [
        QuizQuestion(question: 'What is my most embarrassing moment?', answers: ['Tripping on stage', 'Calling teacher "mom"', 'Forgetting lines']),
        QuizQuestion(question: 'What is my biggest turn-on?', answers: ['Confidence', 'Sense of humor', 'Intelligence']),
        QuizQuestion(question: 'What\'s my guilty pleasure?', answers: ['Reality TV', 'Bad pop music', 'Eating junk food']),
        QuizQuestion(question: 'What\'s the naughtiest thing I\'ve ever done?', answers: ['Sneaked out of house', 'Cheated on a test', 'Stole candy']),
        QuizQuestion(question: 'What\'s my biggest secret crush?', answers: ['Celebrity X', 'Friend Y', 'Teacher Z']),
        QuizQuestion(question: 'What\'s my most irrational fear?', answers: ['Clowns', 'Balloons', 'Buttons']),
        QuizQuestion(question: 'What\'s my favorite curse word?', answers: ['F***', 'S***', 'D***']),
        QuizQuestion(question: 'What is the most adventurous thing I\'ve ever done?', answers: ['Skydiving', 'Bungee jumping', 'Scuba diving']),
        QuizQuestion(question: 'What is my most controversial opinion?', answers: ['Pineapple on pizza is delicious', 'Cats are better than dogs', 'Star Wars is overrated']),
        QuizQuestion(question: 'What is my biggest regret?', answers: ['Not traveling more', 'Not learning an instrument', 'Not studying harder']),
      ],
    ),
    QuizTheme(
      name: 'Work Bestie',
      gradientColors: [Colors.green, Colors.teal],
      suggestedQuestions: [
        QuizQuestion(question: 'What is my go-to coffee order?', answers: ['Latte', 'Espresso', 'Cappuccino']),
        QuizQuestion(question: 'What is my dream job?', answers: ['Travel Blogger', 'Astronaut', 'Chef']),
        QuizQuestion(question: 'What\'s my biggest pet peeve at work?', answers: ['Loud chewers', 'Leaving dishes', 'Long meetings']),
        QuizQuestion(question: 'What\'s my favorite way to de-stress after work?', answers: ['Reading', 'Gym', 'Watching TV']),
        QuizQuestion(question: 'What\'s my preferred communication method?', answers: ['Slack', 'Email', 'Phone Call']),
        QuizQuestion(question: 'What\'s my favorite office snack?', answers: ['Granola Bar', 'Chips', 'Fruit']),
        QuizQuestion(question: 'What\'s my biggest career aspiration?', answers: ['CEO', 'Manager', 'Expert']),
        QuizQuestion(question: 'What is my most-used emoji?', answers: ['😂', '👍', '❤️']),
        QuizQuestion(question: 'What is my favorite lunch spot near the office?', answers: ['The Italian place', 'The sandwich shop', 'The sushi place']),
        QuizQuestion(question: 'What is my biggest work-related accomplishment?', answers: ['Leading a major project', 'Getting a promotion', 'Winning an award']),
      ],
    ),
  ];

  List<Quiz> get userQuizzes => _userQuizzes;
  Quiz? get currentQuiz => _currentQuiz;
  List<QuizTheme> get themes => _themes;
  QuizTheme get selectedQuizTheme => _themes.firstWhere((theme) => theme.name == (_currentQuiz?.selectedThemeName ?? 'Friendship'));

  QuizProvider() {
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesString = prefs.getString(_quizzesKey);
    if (quizzesString != null) {
      final List<dynamic> jsonList = json.decode(quizzesString);
      _userQuizzes = jsonList.map((json) => Quiz.fromJson(json)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesString = json.encode(_userQuizzes.map((quiz) => quiz.toJson()).toList());
    await prefs.setString(_quizzesKey, quizzesString);
  }

  void createNewQuiz(String name, {String gameType = 'Friendship'}) {
    final theme = _themes.firstWhere((t) => t.name == gameType, orElse: () => _themes.first);
    List<QuizQuestion> initialQuestions = List.from(theme.suggestedQuestions);

    _currentQuiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
      name: name,
      selectedThemeName: theme.name,
      questions: initialQuestions,
      leaderboard: [],
    );
    _userQuizzes.add(_currentQuiz!);
    _saveQuizzes();
    notifyListeners();
  }

  void selectQuiz(String quizId) {
    _currentQuiz = _userQuizzes.firstWhere((quiz) => quiz.id == quizId);
    notifyListeners();
  }

  void updateCurrentQuizName(String newName) {
    if (_currentQuiz != null) {
      _currentQuiz!.name = newName;
      _saveQuizzes();
      notifyListeners();
    }
  }

  void addQuestionToCurrentQuiz(QuizQuestion question) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions.add(question);
      _saveQuizzes();
      notifyListeners();
    }
  }

  void removeQuestionFromCurrentQuiz(int index) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions.removeAt(index);
      _saveQuizzes();
      notifyListeners();
    }
  }

  void updateQuestionInCurrentQuiz(int index, QuizQuestion question) {
    if (_currentQuiz != null) {
      _currentQuiz!.questions[index] = question;
      _saveQuizzes();
      notifyListeners();
    }
  }

  void addLeaderboardEntryToCurrentQuiz(LeaderboardEntry entry) {
    if (_currentQuiz != null) {
      _currentQuiz!.leaderboard.add(entry);
      _currentQuiz!.leaderboard.sort((a, b) => b.score.compareTo(a.score));
      _saveQuizzes();
      notifyListeners();
    }
  }

  void removeLeaderboardEntry(String quizId, int entryIndex) {
    final quiz = _userQuizzes.firstWhere((q) => q.id == quizId);
    if (entryIndex >= 0 && entryIndex < quiz.leaderboard.length) {
      quiz.leaderboard.removeAt(entryIndex);
      _saveQuizzes();
      notifyListeners();
    }
  }

  void removeQuiz(String quizId) {
    _userQuizzes.removeWhere((quiz) => quiz.id == quizId);
    if (_currentQuiz?.id == quizId) {
      _currentQuiz = null; // Clear current quiz if it was the one deleted
    }
    _saveQuizzes();
    notifyListeners();
  }

  void setSelectedQuizTheme(String themeName) {
    if (_currentQuiz != null) {
      _currentQuiz!.selectedThemeName = themeName;
      _saveQuizzes();
      notifyListeners();
    }
  }

  List<QuizQuestion> getSuggestedQuestions(String themeName) {
    return _themes.firstWhere((theme) => theme.name == themeName).suggestedQuestions;
  }
}
