import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/pages/main_tab_page.dart'; // Import MainTabPage

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _gradientController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  final TextEditingController _usernameController = TextEditingController();
  bool _showGetStartedButton = false;

  final List<String> _funTexts = [
    'See what your friends really think.',
    'Ask me anything, anonymously.',
    'Unlock your secret inbox.',
    'The truth is waiting for you.',
  ];
  int _funTextIndex = 0;
  Timer? _funTextTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.deepPurple.shade900,
      end: Colors.pinkAccent.shade700,
    ).animate(_gradientController);

    _colorAnimation2 = ColorTween(
      begin: Colors.pinkAccent.shade700,
      end: Colors.deepPurple.shade900,
    ).animate(_gradientController);

    _funTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _funTextIndex = (_funTextIndex + 1) % _funTexts.length;
      });
    });

    _usernameController.addListener(_updateGetStartedButtonVisibility);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gradientController.dispose();
    _funTextTimer?.cancel();
    _usernameController.removeListener(_updateGetStartedButtonVisibility);
    _usernameController.dispose();
    super.dispose();
  }

  void _updateGetStartedButtonVisibility() {
    setState(() {
      _showGetStartedButton = _usernameController.text.isNotEmpty;
    });
  }

  void _getStarted() {
    if (_usernameController.text.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.setUsername(_usernameController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainTabPage(initialIndex: 2), // Navigate to Create tab (index 2)
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorAnimation1.value ?? theme.colorScheme.primary,
                  _colorAnimation2.value ?? theme.colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Get your own anonymous feedback link.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Enter your username',
                          labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.2),
                        ),
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                        cursorColor: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 24),
                      if (_showGetStartedButton)
                        ElevatedButton(
                          onPressed: _getStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          child: const Text('Get Started'),
                        ),
                      const SizedBox(height: 64),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Text(
                          _funTexts[_funTextIndex],
                          key: ValueKey<int>(_funTextIndex),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      HowItWorksStep(
                        icon: Icons.link,
                        text: '1. Get your unique link.',
                        iconColor: theme.colorScheme.secondary,
                        textColor: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      HowItWorksStep(
                        icon: Icons.share,
                        text: '2. Share it with friends.',
                        iconColor: theme.colorScheme.secondary,
                        textColor: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      HowItWorksStep(
                        icon: Icons.question_answer,
                        text: '3. See their anonymous replies.',
                        iconColor: theme.colorScheme.secondary,
                        textColor: Colors.white70,
                      ),
                      const SizedBox(height: 64),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                            child: const Text('App Store'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                            child: const Text('Google Play'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HowItWorksStep extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  const HowItWorksStep({
    super.key,
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ],
    );
  }
}
