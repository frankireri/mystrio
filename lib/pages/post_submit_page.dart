import 'package:flutter/material.dart';

class PostSubmitPage extends StatefulWidget {
  final String username;
  final bool isAnonymous; // NEW: Flag to control the message

  const PostSubmitPage({
    super.key,
    required this.username,
    this.isAnonymous = true, // Default to true for backward compatibility
  });

  @override
  State<PostSubmitPage> createState() => _PostSubmitPageState();
}

class _PostSubmitPageState extends State<PostSubmitPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _iconBounceController;
  late Animation<double> _iconBounceAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconBounceAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _iconBounceController,
        curve: Curves.elasticOut,
      ),
    );
    _iconBounceController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // MODIFIED: Dynamically set the title and message
    final String titleText = widget.isAnonymous ? 'Question Sent!' : 'Reply Sent!';
    final String messageText = widget.isAnonymous
        ? 'Your anonymous question has been sent to @${widget.username}!'
        : 'Your reply has been sent to @${widget.username}!';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        titleTextStyle: theme.appBarTheme.titleTextStyle,
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _iconBounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _iconBounceAnimation.value,
                        child: Icon(
                          Icons.check_circle_outline,
                          color: theme.colorScheme.secondary,
                          size: 80,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    messageText, // Use the dynamic message
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    child: const Text('Create Your Own Link!'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Ask another question'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
