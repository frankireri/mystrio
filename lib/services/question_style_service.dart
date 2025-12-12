import 'package:flutter/material.dart';

class QuestionStyle {
  final String id;
  final String name;
  final String defaultQuestion;
  final List<Color> gradientColors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final String fontFamily;
  final String? backgroundImage;

  QuestionStyle({
    required this.id,
    required this.name,
    required this.defaultQuestion,
    required this.gradientColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.fontFamily = 'Poppins',
    this.backgroundImage,
  });
}

class QuestionStyleService extends ChangeNotifier {
  final List<QuestionStyle> _styles = [
    QuestionStyle(
      id: 'style1',
      name: 'Secret',
      defaultQuestion: 'What\'s your biggest secret?',
      gradientColors: [Colors.pinkAccent.shade400, Colors.deepPurpleAccent.shade400, Colors.blueAccent.shade400],
    ),
    QuestionStyle(
      id: 'style2',
      name: 'Happy',
      defaultQuestion: 'What makes you truly happy?',
      gradientColors: [Colors.red.shade700, Colors.orange.shade700],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    QuestionStyle(
      id: 'style3',
      name: 'Superpower',
      defaultQuestion: 'If you could have any superpower, what would it be?',
      gradientColors: [Colors.teal.shade400, Colors.green.shade700],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    QuestionStyle(
      id: 'style4',
      name: 'Challenge',
      defaultQuestion: 'What\'s a challenge you\'ve overcome recently?',
      gradientColors: [Colors.blueGrey.shade700, Colors.grey.shade900],
    ),
    QuestionStyle(
      id: 'style5',
      name: 'Memory',
      defaultQuestion: 'What\'s your favorite memory?',
      gradientColors: [Colors.purple.shade700, Colors.deepPurple.shade900],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    QuestionStyle(
      id: 'dare1',
      name: 'Dare',
      defaultQuestion: 'Give me a dare!',
      gradientColors: [Colors.red.shade900, Colors.black],
    ),
    QuestionStyle(
      id: 'ask1',
      name: 'Question',
      defaultQuestion: 'Ask me a question!',
      gradientColors: [Colors.blue.shade900, Colors.black],
    ),
  ];

  List<QuestionStyle> get allStyles => _styles;

  QuestionStyle getStyleById(String id) {
    return _styles.firstWhere(
      (style) => style.id == id,
      orElse: () => _styles.first, // Fallback to a default style
    );
  }
}
