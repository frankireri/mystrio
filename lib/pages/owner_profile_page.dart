import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/theme_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/login_page.dart'; // Import LoginPage
import 'package:mystrio/pages/initial_page.dart'; // Import InitialPage for logout navigation

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);

    final String displayUsername = authService.username ?? 'MystrioUser';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings & Profile',
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Container(
        color: theme.colorScheme.background, // Use theme background color
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info Section
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username: @$displayUsername',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${authService.loggedInEmail ?? 'Not logged in'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit profile functionality coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ),

            // Theme Settings
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: theme.textTheme.titleMedium,
                    ),
                    Switch(
                      value: themeService.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),

            // Account Actions
            Card(
              child: Column(
                children: [
                  if (!authService.hasPermanentAccount)
                    ListTile(
                      leading: Icon(Icons.login, color: theme.colorScheme.primary),
                      title: Text('Sign In / Sign Up', style: TextStyle(color: theme.colorScheme.primary)),
                      onTap: () => _showSignInDialog(context),
                    ),
                  if (authService.hasPermanentAccount)
                    ListTile(
                      leading: Icon(Icons.logout, color: theme.colorScheme.error),
                      title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
                      onTap: () async {
                        await authService.logout();
                        if (context.mounted) {
                          // Navigate to InitialPage and remove all other routes
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const InitialPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  // The "Delete Account" ListTile has been removed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
