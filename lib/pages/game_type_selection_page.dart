import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/pages/create_quiz_page.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:mystrio/pages/login_page.dart';
import 'package:mystrio/pages/signup_page.dart';

class GameTypeSelectionPage extends StatelessWidget {
  const GameTypeSelectionPage({super.key});

  void _promptForQuizName(BuildContext context, String gameType) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Quiz'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'e.g., "How well do you know me?"'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final authService = Provider.of<AuthService>(context, listen: false);
                debugPrint('GameTypeSelectionPage: Auth token before createNewQuiz: ${authService.authToken}');
                
                final success = await Provider.of<QuizProvider>(context, listen: false).createNewQuiz(nameController.text, gameType: gameType);
                Navigator.pop(context); // Close dialog

                if (success) {
                  if (!authService.isFullyAuthenticated) {
                    _showLoginPrompt(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateQuizPage()),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create quiz. Please try again.')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Your Quiz!'),
          content: const Text(
              'Create an account or log in to save your quiz and view results.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Later'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            ElevatedButton(
              child: const Text('Sign In / Sign Up'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Choose Game Type',
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildGameTypeCard(
              context,
              'True Friends',
              () => _promptForQuizName(context, 'Friendship'),
            ),
            _buildGameTypeCard(
              context,
              'This or That',
              () => _promptForQuizName(context, 'This or That'),
            ),
            _buildGameTypeCard(context, 'Would You Rather', null, comingSoon: true),
            _buildGameTypeCard(context, 'Lie Detector', null, comingSoon: true),
            _buildGameTypeCard(context, 'Never Have I Ever', null, comingSoon: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTypeCard(BuildContext context, String title, VoidCallback? onTap, {bool comingSoon = false}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: comingSoon ? Colors.grey.shade300 : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: comingSoon ? Colors.white : theme.textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (comingSoon)
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
