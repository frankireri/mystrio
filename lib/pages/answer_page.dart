import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';

// MODIFIED: This page now handles answering anonymous questions from the inbox.
class AnswerPage extends StatefulWidget {
  final int questionId;
  final String questionText;

  const AnswerPage({
    super.key,
    required this.questionId,
    required this.questionText,
  });

  @override
  State<AnswerPage> createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false; // To prevent multiple submissions

  int _characterCount = 0;
  static const int _maxCharacters = 280; // Increased character limit

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _answerController.text.length;
    });
  }

  @override
  void dispose() {
    _answerController.removeListener(_updateCharacterCount);
    _answerController.dispose();
    super.dispose();
  }

  // MODIFIED: Submits the answer using UserQuestionService
  Future<void> _submitAnswer() async {
    if (_isSubmitting) return;

    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type an answer.')),
      );
      return;
    }
    if (_characterCount > _maxCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your answer is too long.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await Provider.of<UserQuestionService>(context, listen: false)
        .postAnswerToAnonymousQuestion(
      questionId: widget.questionId,
      answerText: _answerController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your answer has been posted!')),
        );
        Navigator.of(context).pop(); // Go back to the inbox
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post answer. Please try again.')),
        );
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // NOTE: Sharing is temporarily disabled for this flow.
  // The previous implementation depended on a different data model.
  Future<void> _shareAnswer() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can share your answer after posting it! (Coming Soon)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Answer Question',
        // Sharing is disabled for now.
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
        //     onPressed: _shareAnswer,
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display the question
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anonymous Question:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.questionText, // Use questionText from the widget
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Input field for the answer
            Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: 'Type your public answer here...',
                        border: InputBorder.none,
                      ),
                      maxLines: 8,
                      maxLength: _maxCharacters,
                      keyboardType: TextInputType.multiline,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        // This builds the character counter inside the TextField decoration
                        return Text(
                          '$currentLength/$maxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: currentLength > _maxCharacters
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('Post Answer Publicly'),
            ),
          ],
        ),
      ),
    );
  }
}
