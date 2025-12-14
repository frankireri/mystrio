import 'package:flutter/material.dart';
import 'package:mystrio/pages/inbox_page.dart';
import 'package:mystrio/pages/game_selection_page.dart';
import 'package:mystrio/pages/owner_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/pages/login_page.dart'; // Import LoginPage

class MainTabPage extends StatefulWidget {
  final int initialIndex;

  const MainTabPage({super.key, this.initialIndex = 0});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late int _selectedIndex;
  late final List<Widget> _pages;
  // Using a static variable or a more persistent storage (like SharedPreferences)
  // would be needed if you want this to persist across app restarts.
  // For now, it's once per app session.
  static bool _hasShownSignInPromptThisSession = false; 

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = authService.username ?? 'user';

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

    // Show sign-in prompt if user is a guest and it hasn't been shown yet this session
    if (!authService.hasPermanentAccount && !_hasShownSignInPromptThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSignInDialog(context);
        _hasShownSignInPromptThisSession = true; // Mark as shown for this session
      });
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
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            ElevatedButton(
              child: const Text('Sign In / Sign Up'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
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
