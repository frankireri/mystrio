import 'package:flutter/material.dart';

class PostSubmitPage extends StatefulWidget {
  final String username;

  const PostSubmitPage({super.key, required this.username});

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

    // Fade animation for the whole page content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Bounce animation for the checkmark icon
    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconBounceAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _iconBounceController,
        curve: Curves.elasticOut, // A nice bouncy curve
      ),
    );
    _iconBounceController.forward(); // Play the animation once
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Sent!'),
        automaticallyImplyLeading: false, // Hide back button
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
                    'Your anonymous question has been sent to @${widget.username}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the landing page to create their own link
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
                      // Go back to the profile page to ask another question
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
