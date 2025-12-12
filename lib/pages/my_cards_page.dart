import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mystrio/pages/shared_question_landing_page.dart'; // Import SharedQuestionLandingPage
import 'package:flutter/foundation.dart'; // For debugPrint

class MyCardsPage extends StatelessWidget {
  final String username;

  const MyCardsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyCardsPage: Building for username: $username');
    final userQuestionService = Provider.of<UserQuestionService>(context);
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final allQuestions = userQuestionService.getAllQuestions();
    final theme = Theme.of(context);

    debugPrint('MyCardsPage: Found ${allQuestions.length} questions in service.');

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Question Cards',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final shareLink = 'https://mystrio.app/profile/$username';
              Share.share('Check out my profile on Mystrio! $shareLink');
            },
          ),
        ],
      ),
      body: allQuestions.isEmpty
          ? const Center(child: Text('You haven\'t created any question cards yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allQuestions.length,
              itemBuilder: (context, index) {
                final questionData = allQuestions[index];
                final style = questionStyleService.getStyleById(questionData['styleId']!);
                final questionCode = questionData['code']; // Assuming 'code' is stored in questionData

                debugPrint('MyCardsPage: Displaying card for question: ${questionData['questionText']} with code: $questionCode');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: style.gradientColors,
                        begin: style.begin,
                        end: style.end,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          questionData['questionText'] ?? 'No question text',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Simulate sharing and then navigating to the landing page for this specific card
                            final specificShareLink = 'https://mystrio.app/profile/$username/$questionCode';
                            Share.share('Answer my question on Mystrio! $specificShareLink');

                            // Navigate to the shared question landing page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SharedQuestionLandingPage(
                                  username: username,
                                  questionCode: questionCode!, // Pass the specific question code
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share This Card'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
