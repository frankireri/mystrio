import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/pages/post_submit_page.dart';
import 'package:mystrio/widgets/share_bottom_sheet.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/widgets/empty_state_widget.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/question_style_service.dart'; // Import the service
import 'package:mystrio/models/question.dart'; // Import the Question model
import 'dart:math';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final TextEditingController _customQuestionController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Question> _answeredQuestions = [];

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  late AnimationController _cardAnimationController;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;

  // For pre-defined questions (still used by sender if they don't use custom)
  final List<String> _predefinedQuestions = [
    'What\'s your biggest dream?',
    'What makes you truly happy?',
    'If you could change one thing about the world, what would it be?',
    'What\'s a secret talent you have?',
    'What\'s your favorite memory?',
    'What do you value most in a friendship?',
    'What\'s a challenge you\'ve overcome recently?',
    'If you could meet anyone, living or dead, who would it be?',
    'What\'s a book or movie that changed your perspective?',
    'What\'s something you\'re passionate about?',
  ];
  int _currentQuestionIndex = 0;
  bool _isCustomQuestionMode = false;

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

    _currentQuestionIndex = Random().nextInt(_predefinedQuestions.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final questionProvider = Provider.of<QuestionProvider>(context);
    _answeredQuestions =
        questionProvider.questions.where((q) => q.answerText != null).toList();
    questionProvider.addListener(_onQuestionsChanged);
  }

  @override
  void dispose() {
    Provider.of<QuestionProvider>(context, listen: false)
        .removeListener(_onQuestionsChanged);
    _buttonAnimationController.dispose();
    _cardAnimationController.dispose();
    _customQuestionController.dispose();
    super.dispose();
  }

  void _onQuestionsChanged() {
    final newAnswered = Provider.of<QuestionProvider>(context, listen: false)
        .questions
        .where((q) => q.answerText != null)
        .toList();

    if (newAnswered.length > _answeredQuestions.length) {
      _listKey.currentState?.insertItem(newAnswered.length - 1);
    }
    _answeredQuestions = newAnswered;
  }

  void _submitQuestion() {
    String questionText;
    if (_isCustomQuestionMode) {
      questionText = _customQuestionController.text;
    } else {
      questionText = _predefinedQuestions[_currentQuestionIndex];
    }

    if (questionText.isNotEmpty) {
      Provider.of<QuestionProvider>(context, listen: false)
          .addQuestion(questionText);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostSubmitPage(username: widget.username),
        ),
      );
      _customQuestionController.clear();
    }
  }

  void _shareProfile() {
    final profileUrl = 'https://your-app.com/profile/${widget.username}';
    showModalBottomSheet(
      context: context,
      builder: (context) => ShareBottomSheet(
        shareText: 'Ask me anything anonymously on Mystrio!',
        shareUrl: profileUrl,
      ),
    );
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
    final authService = Provider.of<AuthService>(context);
    final questionStyleService = Provider.of<QuestionStyleService>(context); // Access the service

    // Get the chosen question and style for the profile owner
    final String displayQuestion = authService.chosenQuestionText ?? 'Ask @${widget.username} anything!';
    final QuestionStyle chosenStyle = questionStyleService.getStyleById(authService.chosenQuestionStyleId ?? 'default'); // Use service

    return Scaffold(
      appBar: CustomAppBar(
        title: '@${widget.username}',
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.secondary),
            onPressed: _shareProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          FadeTransition(
            opacity: _cardFadeAnimation,
            child: SlideTransition(
              position: _cardSlideAnimation,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.secondary, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Rectangle image on top - Enhanced with chosen style
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
                        displayQuestion, // Display chosen question
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Question display area with animation
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
                          key: ValueKey<int>(_currentQuestionIndex), // Key for AnimatedSwitcher
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isCustomQuestionMode
                              ? TextField(
                                  controller: _customQuestionController,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Type your custom question...',
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  style: const TextStyle(color: Colors.white),
                                )
                              : Text(
                                  _predefinedQuestions[_currentQuestionIndex],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Navigation and Custom Question buttons
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
                              foregroundColor: Colors.white,
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
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTapDown: (_) => _buttonAnimationController.forward(),
                        onTapUp: (_) => _buttonAnimationController.reverse(),
                        onTapCancel: () => _buttonAnimationController.reverse(),
                        onTap: _submitQuestion,
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: ElevatedButton(
                                onPressed: _submitQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Submit Question'),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Answered Questions',
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _answeredQuestions.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.question_answer_outlined,
                    message: 'No answers yet!',
                    subMessage: 'Answer questions in your inbox to see them here.',
                    buttonText: 'Go to Inbox',
                    onButtonPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                  )
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _answeredQuestions.length,
                    itemBuilder: (context, index, animation) {
                      final question = _answeredQuestions[index];
                      return FadeTransition(
                        opacity: animation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Q: ${question.questionText}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('A: ${question.answerText!}'),
                              ],
                            ),
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
}
