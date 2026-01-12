import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

// NEW: This page is now a visual "Answer Studio" for creating and sharing stylish answers.
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

class _AnswerPageState extends State<AnswerPage> {
  final TextEditingController _answerController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSubmitting = false;

  late QuestionStyle _currentStyle;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    // Start with a random style
    _changeStyle();
  }

  void _changeStyle() {
    final styleService = Provider.of<QuestionStyleService>(context, listen: false);
    final allStyles = styleService.allStyles;
    setState(() {
      _currentStyle = allStyles[_random.nextInt(allStyles.length)];
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

// FULLY IMPLEMENTED: The submit and share logic is now complete.
  Future<void> _submitAndShare() async {
    if (_isSubmitting) return;

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type an answer before sharing.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Capture the image from the Screenshot controller
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Could not capture image.');
      }

      // 2. Use ShareXFiles to share the image
      final shareText = 'See my answer on Mystrio!';
      final imageFile = XFile.fromData(
        imageBytes,
        name: 'mystrio_answer.png',
        mimeType: 'image/png',
      );

      // The share result tells us if the user successfully shared.
      final shareResult = await Share.shareXFiles(
        [imageFile],
        text: shareText,
        subject: 'My Answer',
      );

      // 3. Only post the answer if the share was successful
      if (shareResult.status == ShareResultStatus.success) {
        final success = await Provider.of<UserQuestionService>(context, listen: false)
            .postAnswerToAnonymousQuestion(
          questionId: widget.questionId,
          answerText: _answerController.text,
          styleId: _currentStyle.id, // Pass the styleId
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your answer has been posted!')),
            );
            Navigator.of(context).pop(); // Go back to the inbox
          } else {
            throw Exception('Failed to post answer.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for contrast
      // Using a custom app bar to better fit the "studio" feel
      appBar: AppBar(
        title: const Text('Create Answer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                // The main interactive card for the answer
                child: _buildAnswerCard(),
              ),
            ),
            // Bottom control panel
            _buildControlPanel(theme),
          ],
        ),
      ),
    );
  }

  // The visual card that the user interacts with and will eventually share.
  Widget _buildAnswerCard() {
    return Screenshot(
      controller: _screenshotController,
      child: AspectRatio(
        aspectRatio: 9 / 16, // Common story aspect ratio
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentStyle.gradientColors,
              begin: _currentStyle.begin,
              end: _currentStyle.end,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Question text
              Text(
                widget.questionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _currentStyle.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  shadows: [const Shadow(blurRadius: 2, color: Colors.black26)],
                ),
              ),
              const SizedBox(height: 20),
              // Answer input field
              TextField(
                controller: _answerController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _currentStyle.fontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 3, color: Colors.black38)],
                ),
                maxLines: 5,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: 'Type your answer...',
                  hintStyle: TextStyle(
                    fontFamily: _currentStyle.fontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  counterText: '', // Hide the default counter
                ),
                cursorColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The bottom panel with the dice and share buttons.
  Widget _buildControlPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Dice Roll" button to change the style
          FloatingActionButton(
            heroTag: 'dice_button',
            onPressed: _changeStyle,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.casino, color: Colors.white, size: 28),
          ),
          // Share button
          FloatingActionButton.extended(
            heroTag: 'share_button',
            onPressed: _isSubmitting ? null : _submitAndShare,
            backgroundColor: theme.primaryColor,
            label: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                  )
                : const Text('Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
    );
  }
}
