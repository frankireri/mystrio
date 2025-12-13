import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/pages/landing_page.dart';
import 'package:mystrio/pages/main_tab_page.dart';
import 'package:mystrio/widgets/custom_loading_indicator.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            body: const CustomLoadingIndicator(),
          );
        } else if (authService.hasAccount) {
          // For returning users, go to the new tabbed page.
          return const MainTabPage();
        } else {
          // For new users, show the landing page.
          return const LandingPage();
        }
      },
    );
  }
}
