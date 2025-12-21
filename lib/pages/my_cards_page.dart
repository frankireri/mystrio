import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mystrio/pages/shared_question_landing_page.dart';
import 'package:flutter/foundation.dart';

class MyCardsPage extends StatefulWidget {
  final String username;

  const MyCardsPage({super.key, required this.username});

  @override
  State<MyCardsPage> createState() => _MyCardsPageState();
}

class _MyCardsPageState extends State<MyCardsPage> {
  Future<List<Map<String, dynamic>>>? _cardsFuture;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    setState(() {
      _cardsFuture = userQuestionService.getAllQuestionCards();
    });
  }

  Future<void> _deleteCard(String code) async {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    final success = await userQuestionService.deleteQuestionCard(code);
    if (success) {
      _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card deleted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete card.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MyCardsPage: Building for username: ${widget.username}');
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Question Cards',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final shareLink = 'https://mystrio.app/profile/${widget.username}';
              Share.share('Check out my profile on Mystrio! $shareLink');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You haven\'t created any question cards yet.'));
          } else {
            final allQuestions = snapshot.data!;
            debugPrint('MyCardsPage: Found ${allQuestions.length} questions in service.');
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allQuestions.length,
              itemBuilder: (context, index) {
                final questionData = allQuestions[index];
                final style = questionStyleService.getStyleById(questionData['styleId']!);
                final questionCode = questionData['code'];

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                final specificShareLink = 'https://mystrio.app/profile/${widget.username}/$questionCode';
                                Share.share('Answer my question on Mystrio! $specificShareLink');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SharedQuestionLandingPage(
                                      username: widget.username,
                                      questionCode: questionCode!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Card'),
                                    content: const Text('Are you sure you want to delete this card?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _deleteCard(questionCode!);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
