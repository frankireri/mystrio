import 'package:flutter/material.dart';
import 'package:mystrio/pages/inbox_page.dart';
import 'package:mystrio/pages/game_selection_page.dart';
import 'package:mystrio/pages/owner_profile_page.dart';
// import 'package:mystrio/pages/home_dashboard_page.dart'; // Removed HomeDashboardPage
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';

class MainTabPage extends StatefulWidget {
  final int initialIndex;

  const MainTabPage({super.key, this.initialIndex = 0});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late int _selectedIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final username = Provider.of<AuthService>(context, listen: false).username ?? 'user';

    // Define the new list of pages without HomeDashboardPage
    _pages = <Widget>[
      const InboxPage(),
      GameSelectionPage(username: username),
      const OwnerProfilePage(),
    ];

    // Adjust initialIndex based on the removal of the Home tab
    int newInitialIndex = 0; // Default to Inbox (new index 0)
    if (widget.initialIndex == 2) { // If old initialIndex was Create (index 2)
      newInitialIndex = 1; // New index for Create
    } else if (widget.initialIndex == 3) { // If old initialIndex was Profile (index 3)
      newInitialIndex = 2; // New index for Profile
    }
    _selectedIndex = newInitialIndex;
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
          // Removed Home BottomNavigationBarItem
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
