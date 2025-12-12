import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/theme_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

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
                  ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
                    onTap: () async {
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                    title: Text('Delete Account', style: TextStyle(color: theme.colorScheme.error)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account deletion functionality coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
