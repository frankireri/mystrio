import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/widgets/shareable_story_card.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:confetti/confetti.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' as rendering;

class AnswerPage extends StatefulWidget {
  final Question question;

  const AnswerPage({super.key, required this.question});

  @override
  State<AnswerPage> createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late ConfettiController _confettiController;

  late AnimationController _submitButtonAnimationController;
  late Animation<double> _submitButtonScaleAnimation;

  int _characterCount = 0;
  static const int _maxCharacters = 200;

  @override
  void initState() {
    super.initState();
    _answerController.text = widget.question.answerText ?? '';
    _characterCount = _answerController.text.length;
    _answerController.addListener(_updateCharacterCount);

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _submitButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _submitButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _submitButtonAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _answerController.text.length;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _submitButtonAnimationController.dispose();
    _answerController.removeListener(_updateCharacterCount);
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    if (_answerController.text.isNotEmpty && _characterCount <= _maxCharacters) {
      Provider.of<QuestionProvider>(context, listen: false)
          .addAnswer(widget.question, _answerController.text);
      Navigator.of(context).pop();
    } else if (_characterCount > _maxCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Answer is too long!', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  Future<Uint8List?> _capturePng() async {
    try {
      rendering.RenderRepaintBoundary? boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject() as rendering.RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Error capturing image: $e");
      return null;
    }
  }

  Future<void> _shareAnswer() async {
    if (widget.question.answerText == null || widget.question.answerText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer the question before sharing!', style: Theme.of(context).textTheme.bodyMedium)),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final username = authService.username;

    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set a username to share!', style: Theme.of(context).textTheme.bodyMedium)),
      );
      return;
    }

    final Uint8List? bytes = await _capturePng();

    if (bytes != null) {
      final profileUrl = 'https://your-app.com/profile/$username';
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'mystrio_answer.png')],
        text: 'Check out my answer on Mystrio! Ask me anything: $profileUrl',
      );
      _confettiController.play();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate share image.', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Answer Question',
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
            onPressed: _shareAnswer,
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: theme.cardTheme.color,
                    elevation: theme.cardTheme.elevation,
                    shape: theme.cardTheme.shape,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question:',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.question.questionText,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your Answer:',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.cardTheme.color,
                    elevation: theme.cardTheme.elevation,
                    shape: theme.cardTheme.shape,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _answerController,
                            decoration: InputDecoration(
                              hintText: 'Type your answer here...',
                              border: InputBorder.none,
                              hintStyle: theme.inputDecorationTheme.hintStyle,
                            ),
                            maxLines: null,
                            maxLength: _maxCharacters,
                            keyboardType: TextInputType.multiline,
                            style: theme.textTheme.bodyMedium,
                            cursorColor: theme.colorScheme.secondary,
                          ),
                          Text(
                            '$_characterCount/$_maxCharacters',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _characterCount > _maxCharacters
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTapDown: (_) => _submitButtonAnimationController.forward(),
                    onTapUp: (_) => _submitButtonAnimationController.reverse(),
                    onTapCancel: () => _submitButtonAnimationController.reverse(),
                    onTap: _submitAnswer,
                    child: AnimatedBuilder(
                      animation: _submitButtonScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _submitButtonScaleAnimation.value,
                          child: ElevatedButton(
                            onPressed: _submitAnswer,
                            child: const Text('Submit Answer'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Hidden widget to be converted to image
            Offstage(
              offstage: true,
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: ShareableStoryCard(
                  question: widget.question,
                  username: Provider.of<AuthService>(context, listen: false).username ?? 'MystrioUser',
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                createParticlePath: (size) => Path(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
