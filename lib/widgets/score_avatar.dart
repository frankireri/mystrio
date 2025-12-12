import 'package:flutter/material.dart';

class ScoreAvatar extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ScoreAvatar({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = score / totalQuestions;
    String avatar;
    Color color;

    if (percentage >= 0.8) {
      avatar = '🏆';
      color = Colors.amber;
    } else if (percentage >= 0.5) {
      avatar = '👍';
      color = Colors.lightGreen;
    } else {
      avatar = '🤔';
      color = Colors.orange;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: color,
          child: Text(
            avatar,
            style: const TextStyle(fontSize: 50),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          percentage >= 0.8
              ? 'You\'re a true friend!'
              : percentage >= 0.5
                  ? 'Not bad!'
                  : 'There\'s room for improvement!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
