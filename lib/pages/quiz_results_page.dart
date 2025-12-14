import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:mystrio/pages/main_tab_page.dart'; // Import MainTabPage

class QuizResultsPage extends StatelessWidget {
  final String quizId;

  const QuizResultsPage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: QuizResultsPage received quizId: $quizId'); // Debug print
    final quizProvider = Provider.of<QuizProvider>(context);

    final quiz = quizProvider.userQuizzes.firstWhere(
      (q) => q.id == quizId,
      orElse: () => Quiz(
        id: 'error',
        name: 'Error Quiz',
        selectedThemeName: 'Friendship',
        questions: [],
        leaderboard: [],
      ),
    );

    if (quiz.id == 'error') {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Error'),
        body: Center(
          child: Text(
            'Quiz not found. It might have been deleted or never created.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final shareLink = 'https://mystrio.app/quiz/$quizId';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Results',
          backgroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Share'),
              Tab(text: 'Scoreboard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildShareTab(context, quiz, shareLink),
            _buildScoreboardTab(context, quiz, quizProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTab(BuildContext context, Quiz quiz, String shareLink) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            quiz.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Congrats, your quiz is ready!',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(shareLink),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Share on Socials', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialIcon(context, Icons.message, 'WhatsApp', shareLink),
                        _buildSocialIcon(context, Icons.camera_alt, 'Instagram', shareLink),
                        _buildSocialIcon(context, Icons.snapchat, 'Snapchat', shareLink),
                        _buildSocialIcon(context, Icons.messenger, 'Messenger', shareLink),
                        _buildSocialIcon(context, Icons.close, 'X', shareLink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30), // Spacing below social sharing
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back to the MainTabPage and remove all other routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainTabPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardTab(BuildContext context, Quiz quiz, QuizProvider quizProvider) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Who Knows You Best?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: quiz.leaderboard.isEmpty
                ? Center(
                    child: Text(
                      'No one has taken this quiz yet!',
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: quiz.leaderboard.length,
                    itemBuilder: (context, index) {
                      final entry = quiz.leaderboard[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Text(
                            '#${index + 1}',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          title: Text(entry.username),
                          subtitle: Text('${entry.score} Points'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              quizProvider.removeLeaderboardEntry(quiz.id, index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon, String label, String shareLink) {
    return GestureDetector(
      onTap: () {
        Share.share('Check out my quiz: $shareLink');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
