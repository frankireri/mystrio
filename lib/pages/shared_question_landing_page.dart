import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/response_sent_page.dart'; // Import the new page
import 'package:flutter/foundation.dart'; // For debugPrint

class SharedQuestionLandingPage extends StatefulWidget {
  final String username;
  final String questionCode;

  const SharedQuestionLandingPage({super.key, required this.username, required this.questionCode});

  @override
  State<SharedQuestionLandingPage> createState() => _SharedQuestionLandingPageState();
}

class _SharedQuestionLandingPageState extends State<SharedQuestionLandingPage> {
  Future<Map<String, dynamic>?>? _questionFuture;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    setState(() {
      _questionFuture = userQuestionService.getQuestionByCode(username: widget.username, code: widget.questionCode);
    });
  }

  void _submitAnswer(BuildContext context, Map<String, dynamic> questionData) {
    if (_answerController.text.isNotEmpty) {
      final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
      userQuestionService.addReplyToQuestion(
        questionCode: questionData['code'],
        replyText: _answerController.text,
        styleId: questionData['styleId'],
      );

      debugPrint('SharedQuestionLandingPage: Anonymous answer submitted for question ${questionData['code']}: ${_answerController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your anonymous answer has been sent!')),
      );
      // Navigate to the response sent page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResponseSentPage(username: widget.username),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: '@${widget.username}\'s Question'),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _questionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Question not found.'));
          } else {
            final questionData = snapshot.data!;
            final style = questionStyleService.getStyleById(questionData['styleId']!);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Colored Top Section (Question)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: style.gradientColors,
                            begin: style.begin,
                            end: style.end,
                          ),
                        ),
                        child: Text(
                          questionData['questionText'] ?? 'No question text',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // White Bottom Section (Answer Input)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: Column(
                          children: [
                            TextField(
                              controller: _answerController,
                              decoration: InputDecoration(
                                hintText: 'Type your anonymous reply...',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                ),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _submitAnswer(context, questionData),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50), // Full width button
                              ),
                              child: const Text('Reply Anonymously'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
