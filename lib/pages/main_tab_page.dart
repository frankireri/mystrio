import 'package:flutter/material.dart';
import 'package:mystrio/pages/inbox_page.dart';
import 'package:mystrio/pages/game_selection_page.dart';
import 'package:mystrio/pages/owner_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/pages/login_page.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/quiz_provider.dart';

class MainTabPage extends StatefulWidget {
  final int initialIndex;

  const MainTabPage({super.key, this.initialIndex = 0});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late int _selectedIndex;
  late final List<Widget> _pages;
  static bool _hasShownSignInPromptThisSession = false;
  
  late AuthService _authService;
  late QuestionProvider _questionProvider;
  late QuizProvider _quizProvider;
  bool _initialDataFetched = false; // Flag to ensure data is fetched only once after auth

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    _quizProvider = Provider.of<QuizProvider>(context, listen: false);

    _authService.addListener(_onAuthServiceChanged);

    // Initial check in case authService is already ready (e.g., hot restart)
    // Defer this call to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onAuthServiceChanged();
    });

    final username = _authService.username ?? 'user';

    _pages = <Widget>[
      const InboxPage(),
      GameSelectionPage(username: username),
      const OwnerProfilePage(),
    ];

    int newInitialIndex = 0;
    if (widget.initialIndex == 2) {
      newInitialIndex = 1;
    } else if (widget.initialIndex == 3) {
      newInitialIndex = 2;
    }
    _selectedIndex = newInitialIndex;

    if (!_authService.hasPermanentAccount && !_hasShownSignInPromptThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSignInDialog(context);
        _hasShownSignInPromptThisSession = true;
      });
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }

  void _onAuthServiceChanged() {
    debugPrint('MainTabPage: _onAuthServiceChanged triggered.');
    debugPrint('  isLoading: ${_authService.isLoading}');
    debugPrint('  isFullyAuthenticated: ${_authService.isFullyAuthenticated}');
    debugPrint('  authToken: ${_authService.authToken != null ? "present" : "null"}');
    debugPrint('  _initialDataFetched: $_initialDataFetched');

    // Only fetch if authService is not loading, is fully authenticated,
    // and we haven't fetched the initial data yet.
    if (!_authService.isLoading && _authService.isFullyAuthenticated && !_initialDataFetched) {
      debugPrint('MainTabPage: Fetching initial data (questions and quizzes).');
      // Defer fetching to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _questionProvider.fetchQuestions();
        _quizProvider.fetchQuizzes();
      });
      _initialDataFetched = true; // Mark as fetched
    } else if (!_authService.isFullyAuthenticated) {
      // If user logs out, reset the flag so data can be fetched again on next login
      debugPrint('MainTabPage: User not fully authenticated, resetting _initialDataFetched.');
      _initialDataFetched = false;
    }
  }

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unlock More Features!'),
          content: const Text(
              'Sign in or create an account to save your progress, customize your profile, and access all features.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Later'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Sign In / Sign Up'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
