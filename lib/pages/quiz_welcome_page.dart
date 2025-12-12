import 'package:flutter/material.dart';
import 'package:mystrio/pages/game_type_selection_page.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';

class QuizWelcomePage extends StatelessWidget {
  const QuizWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create a Quiz',
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              "Let's create your first quiz!",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildInstructionStep(
              context,
              '1',
              'Answer 10 questions about yourself.',
            ),
            _buildInstructionStep(
              context,
              '2',
              'Share your quiz link with your friends.',
            ),
            _buildInstructionStep(
              context,
              '3',
              "Your friends will try to answer your questions.",
            ),
            _buildInstructionStep(
              context,
              '4',
              'Find out how well your friends know you!',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameTypeSelectionPage()),
                );
              },
              child: const Text('Create Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
