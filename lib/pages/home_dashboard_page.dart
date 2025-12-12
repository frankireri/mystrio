import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/gratitude_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final quizProvider = Provider.of<QuizProvider>(context);
    final gratitudeProvider = Provider.of<GratitudeProvider>(context);

    final String username = authService.username ?? 'MystrioUser';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome, @$username!',
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Activities',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // My Quizzes Card
              _buildActivityCard(
                context,
                icon: Icons.quiz_outlined,
                title: 'My Quizzes',
                subtitle: '${quizProvider.userQuizzes.length} quizzes created',
                onTap: () {
                  Navigator.of(context).pushNamed('/my-quizzes');
                },
                startColor: Colors.deepOrange.shade400,
                endColor: Colors.orange.shade700,
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),

              // My Gratitude Jar Card
              _buildActivityCard(
                context,
                icon: Icons.star_border_outlined,
                title: 'My Gratitude Jar',
                subtitle: '${gratitudeProvider.items.length} items of gratitude',
                onTap: () {
                  Navigator.of(context).pushNamed('/gratitude');
                },
                startColor: Colors.teal.shade400,
                endColor: Colors.green.shade700,
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),

              // Anonymous Q&A Summary
              _buildActivityCard(
                context,
                icon: Icons.question_answer_outlined,
                title: 'Anonymous Q&A',
                subtitle: 'Check your inbox for new questions!',
                onTap: () {
                  Navigator.of(context).pushNamed('/inbox');
                },
                startColor: Colors.indigo.shade400,
                endColor: Colors.blue.shade700,
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color startColor,
    required Color endColor,
    required Color iconColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Ensures the gradient respects the border radius
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: iconColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
