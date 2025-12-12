import 'package:flutter/material.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/question_selection_page.dart'; // To navigate to create own card

class ResponseSentPage extends StatelessWidget {
  final String username; // The username of the person who received the answer

  const ResponseSentPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Response Sent!'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 30),
              Text(
                'Your anonymous response has been sent!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              Text(
                'Want to find out what your friends think about you?',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the anonymous card creation page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionSelectionPage(username: username),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Your Own Questions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst); // Go back to home/initial page
                },
                child: const Text('Go Back Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
