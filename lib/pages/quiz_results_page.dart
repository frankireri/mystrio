import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class QuizResultsPage extends StatelessWidget {
  final String quizId;
  final ScreenshotController _screenshotController = ScreenshotController();

  QuizResultsPage({super.key, required this.quizId});

  Future<void> _shareQuizWithImage(BuildContext context, Quiz quiz, String shareLink) async {
    final Uint8List? imageBytes = await _screenshotController.capture();

    if (imageBytes != null) {
      final shareText =
          'I just created a quiz on Mystrio! Can you beat my score?\n\n"${quiz.name}"\n\nPlay it here: $shareLink';

      final imageFile = XFile.fromData(
        imageBytes,
        name: 'quiz_card.png',
        mimeType: 'image/png',
      );

      if (kIsWeb) {
        await Share.shareXFiles(
          [imageFile],
          text: shareText,
          subject: 'Check out my new quiz!',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/quiz_card.png';
        await File(imagePath).writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
          subject: 'Check out my new quiz!',
        );
      }
    } else {
      final shareText =
          'I just created a quiz on Mystrio! Can you beat my score?\n\n"${quiz.name}"\n\nPlay it here: $shareLink';
      Share.share(shareText, subject: 'Check out my new quiz!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);

    Quiz? quiz;
    try {
      quiz = quizProvider.userQuizzes.firstWhere((q) => q.id == quizId);
    } catch (e) {
      quiz = null;
    }

    if (quiz == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Error'),
        body: const Center(child: Text('Quiz not found. Please go back and try again.')),
      );
    }
    
    // Create a final, non-nullable variable after the null check.
    final finalQuiz = quiz;

    final quizTheme = quizProvider.themes.firstWhere(
      (t) => t.name == finalQuiz.selectedThemeName,
      orElse: () => quizProvider.themes.first,
    );

    final shareLink = 'https://mystrio.app/play?quizId=${finalQuiz.id}';

    return Scaffold(
      appBar: const CustomAppBar(title: 'Results & Share'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _shareQuizWithImage(context, finalQuiz, shareLink),
        label: const Text('Share Quiz'),
        icon: const Icon(Icons.share),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Screenshot(
            controller: _screenshotController,
            child: _buildShareCard(
              context,
              finalQuiz,
              quizTheme,
              theme,
              authService.profileImagePath,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Leaderboard',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          finalQuiz.leaderboard.isEmpty
              ? _buildEmptyLeaderboard(theme)
              : _buildLeaderboard(finalQuiz.leaderboard, theme),
        ],
      ),
    );
  }

  Widget _buildShareCard(
    BuildContext context,
    Quiz quiz,
    QuizTheme quizTheme,
    ThemeData theme,
    String? profileImagePath,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: quizTheme.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.8),
              backgroundImage: (profileImagePath != null && profileImagePath.isNotEmpty)
                  ? NetworkImage(profileImagePath)
                  : null,
              child: (profileImagePath == null || profileImagePath.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              quiz.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [const Shadow(blurRadius: 3, color: Colors.black38)],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${quiz.questions.length} Questions',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              'Click the link to play!',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Icon(Icons.arrow_downward, color: Colors.white, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard(ThemeData theme) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No one has taken this quiz yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share it and see who gets the high score!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> leaderboard, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: leaderboard.asMap().entries.map((entry) {
          int index = entry.key;
          LeaderboardEntry item = entry.value;
          return ListTile(
            leading: _buildRankIcon(index),
            title: Text(item.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${item.score}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankIcon(int index) {
    IconData icon;
    Color color;
    switch (index) {
      case 0:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 1:
        icon = Icons.emoji_events;
        color = Colors.grey.shade400;
        break;
      case 2:
        icon = Icons.emoji_events;
        color = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        return CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        );
    }
    return Icon(icon, color: color, size: 36);
  }
}
