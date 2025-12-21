import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/pages/post_submit_page.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/models/question.dart'; // Import the Question model
import 'dart:math';

class QuestionAskingPage extends StatefulWidget {
  final String username;
  final Question? questionToAnswer; // Changed from String? question

  const QuestionAskingPage({super.key, required this.username, this.questionToAnswer});

  @override
  State<QuestionAskingPage> createState() => _QuestionAskingPageState();
}

class _QuestionAskingPageState extends State<QuestionAskingPage> with TickerProviderStateMixin {
  final TextEditingController _customQuestionController = TextEditingController();

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  late AnimationController _cardAnimationController;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;

  final List<String> _predefinedQuestions = [
    'What\'s your biggest dream?',
    'What makes you truly happy?',
    'If you could change one thing about the world, what would it be?',
    'What\'s a secret talent you have?',
    'What\'s your favorite memory?',
  ];
  int _currentQuestionIndex = 0;
  bool _isCustomQuestionMode = false;
  bool _isLoading = false; // New state
  String? _errorMessage; // New state

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardFadeAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeIn,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _cardAnimationController.forward();

    if (widget.questionToAnswer == null) { // Check questionToAnswer
      _currentQuestionIndex = Random().nextInt(_predefinedQuestions.length);
    }
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _cardAnimationController.dispose();
    _customQuestionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String text;
    if (widget.questionToAnswer != null) { // Submitting an answer to an existing question
      text = _customQuestionController.text;
    } else { // Submitting a new question
      if (_isCustomQuestionMode) {
        text = _customQuestionController.text;
      } else {
        text = _predefinedQuestions[_currentQuestionIndex];
      }
    }

    if (text.isNotEmpty) {
      try {
        if (widget.questionToAnswer != null) {
          await Provider.of<QuestionProvider>(context, listen: false).addAnswer(widget.questionToAnswer!, text);
        } else {
          await Provider.of<QuestionProvider>(context, listen: false).addQuestion(text);
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostSubmitPage(username: widget.username),
            ),
          );
          _customQuestionController.clear();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a question or an answer.';
      });
    }
  }

  void _shuffleQuestion() {
    setState(() {
      _currentQuestionIndex = Random().nextInt(_predefinedQuestions.length);
      _isCustomQuestionMode = false;
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1) % _predefinedQuestions.length;
      _isCustomQuestionMode = false;
    });
  }

  void _previousQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex - 1 + _predefinedQuestions.length) % _predefinedQuestions.length;
      _isCustomQuestionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);

    final String displayQuestion = widget.questionToAnswer?.questionText ?? authService.chosenQuestionText ?? 'Ask @${widget.username} anything!';
    final QuestionStyle chosenStyle = questionStyleService.getStyleById(authService.chosenQuestionStyleId ?? 'default');

    return Scaffold(
      appBar: CustomAppBar(
        title: '@${widget.username}',
        backgroundColor: theme.colorScheme.surface, // Use theme surface color
      ),
      body: Container(
        color: theme.colorScheme.background, // Use theme background color
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: SlideTransition(
              position: _cardSlideAnimation,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: theme.cardTheme.elevation,
                color: theme.cardTheme.color,
                shape: theme.cardTheme.shape,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: chosenStyle.gradientColors,
                            begin: chosenStyle.begin,
                            end: chosenStyle.end,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mystrio',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayQuestion,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (widget.questionToAnswer == null) ...[ // Check questionToAnswer
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.5),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(_currentQuestionIndex),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isCustomQuestionMode
                                ? TextField(
                                    controller: _customQuestionController,
                                    decoration: InputDecoration.collapsed(
                                      hintText: 'Type your custom question...',
                                      hintStyle: theme.inputDecorationTheme.hintStyle,
                                    ),
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    style: theme.textTheme.bodyMedium,
                                    cursorColor: theme.colorScheme.secondary,
                                  )
                                : Text(
                                    _predefinedQuestions[_currentQuestionIndex],
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: _previousQuestion,
                              color: theme.colorScheme.secondary,
                            ),
                            ElevatedButton.icon(
                              onPressed: _shuffleQuestion,
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Shuffle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: _nextQuestion,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isCustomQuestionMode = !_isCustomQuestionMode;
                            });
                          },
                          child: Text(
                            _isCustomQuestionMode ? 'Use Pre-defined Questions' : 'Write Custom Question',
                            style: TextStyle(color: theme.colorScheme.secondary),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _customQuestionController,
                          decoration: InputDecoration.collapsed(
                            hintText: 'Type your answer...',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: theme.textTheme.bodyMedium,
                          cursorColor: theme.colorScheme.secondary,
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GestureDetector(
                              onTapDown: (_) => _buttonAnimationController.forward(),
                              onTapUp: (_) => _buttonAnimationController.reverse(),
                              onTapCancel: () => _buttonAnimationController.reverse(),
                              onTap: _submit,
                              child: AnimatedBuilder(
                                animation: _buttonScaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _buttonScaleAnimation.value,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.secondary,
                                        foregroundColor: theme.colorScheme.onSecondary,
                                      ),
                                      child: Text(widget.questionToAnswer == null ? 'Submit Question' : 'Submit Answer'),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
