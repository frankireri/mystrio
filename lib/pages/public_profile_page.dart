import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/question_selection_page.dart'; // For navigation after reply

class PublicProfilePage extends StatefulWidget {
  final String username;
  final String? questionCode;

  const PublicProfilePage({super.key, required this.username, this.questionCode});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Future<List<Map<String, dynamic>>>? _questionsFuture; // Changed to dynamic
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    if (widget.questionCode != null) {
      final specificQuestion = await userQuestionService.getQuestionByCode(username: widget.username, code: widget.questionCode!);
      setState(() {
        _questionsFuture = Future.value(specificQuestion != null ? [specificQuestion] : []);
      });
    } else {
      setState(() {
        _questionsFuture = Future.value(userQuestionService.getAllQuestions().where((q) => q['username'] == widget.username).toList());
      });
    }
  }

  void _showAnswerDialog(BuildContext context, Map<String, dynamic> questionData) {
    final answerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(questionData['questionText'] ?? 'Answer Question'),
        content: TextField(
          controller: answerController,
          decoration: const InputDecoration(hintText: 'Your anonymous answer...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (answerController.text.isNotEmpty) {
                // In a real app, you would send this answer to your backend.
                debugPrint('Answer submitted: ${answerController.text}');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your answer has been sent!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(BuildContext context, Map<String, dynamic> questionData) {
    if (_answerController.text.isNotEmpty) {
      // In a real app, you would send this anonymous answer to your backend
      // along with questionData['code'] and widget.username
      debugPrint('Anonymous answer submitted for question ${questionData['code']}: ${_answerController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your anonymous answer has been sent!')),
      );
      // Navigate to create your own card screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionSelectionPage(username: widget.username), // Assuming username is available
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: '@${widget.username}\'s Profile'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('This user hasn\'t created any question cards yet.'));
          } else {
            final questionsToDisplay = snapshot.data!;

            // If questionCode is provided, always display only the first (and only) question
            if (widget.questionCode != null && questionsToDisplay.isNotEmpty) {
              final questionData = questionsToDisplay.first;
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
            } else {
              // Original behavior: display all questions if no specific questionCode
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questionsToDisplay.length,
                itemBuilder: (context, index) {
                  final questionData = questionsToDisplay[index];
                  final style = questionStyleService.getStyleById(questionData['styleId']!);

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
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _showAnswerDialog(context, questionData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                            child: const Text('Type your answer...'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
