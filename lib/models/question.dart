class Question {
  final String id; // Assuming backend provides an ID for questions
  final String questionText;
  String? answerText;
  final bool isFromAI;
  final Map<String, String> hints;

  Question({
    required this.id,
    required this.questionText,
    this.answerText,
    this.isFromAI = false,
    this.hints = const {},
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      questionText: json['questionText'],
      answerText: json['answerText'],
      isFromAI: json['isFromAI'] ?? false,
      hints: Map<String, String>.from(json['hints'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'answerText': answerText,
      'isFromAI': isFromAI,
      'hints': hints,
    };
  }
}
