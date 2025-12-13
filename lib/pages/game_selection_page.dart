import 'package:flutter/material.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/my_quizzes_page.dart';
import 'package:mystrio/pages/my_cards_page.dart'; // Import the new page

class GameSelectionPage extends StatelessWidget {
  final String username;
  final bool isNewUser;

  const GameSelectionPage({
    super.key,
    required this.username,
    this.isNewUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: isNewUser ? 'Welcome, @$username!' : 'Create New',
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              if (isNewUser) ...[
                Text(
                  'What would you like to create first?',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
              _buildGameButton(
                context,
                icon: Icons.question_answer_outlined,
                title: 'Anonymous Q&A',
                subtitle: 'Share a link to get anonymous questions.',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).pushNamed('/select-question/$username');
                },
              ),
              const SizedBox(height: 24),
              _buildGameButton(
                context,
                icon: Icons.quiz_outlined,
                title: 'How Much Do You Know Me?',
                subtitle: 'Create a quiz for your friends to take.',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).pushNamed('/my-quizzes');
                },
              ),
              const SizedBox(height: 24),
              _buildGameButton(
                context,
                icon: Icons.star_border_outlined,
                title: 'My 2023 Gratitude Jar',
                subtitle: 'Reflect on your year and share your gratitude.',
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).pushNamed('/gratitude');
                },
              ),
              const SizedBox(height: 24),
              // Temporary button for testing
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyCardsPage(username: username),
                    ),
                  );
                },
                child: const Text('My Question Cards (Test)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
