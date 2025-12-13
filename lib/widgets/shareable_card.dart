import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/animated_background.dart';

class ShareableCard extends StatelessWidget {
  final String questionText;
  final QuestionStyle style;
  final String username;
  final String? backgroundImage;
  final String? profileImagePath; // New parameter

  const ShareableCard({
    super.key,
    required this.questionText,
    required this.style,
    required this.username,
    this.backgroundImage,
    this.profileImagePath, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileUrl = 'mystrio.app/$username'; // Your app's domain

    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: backgroundImage != null
            ? DecorationImage(
                image: FileImage(File(backgroundImage!)),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (backgroundImage == null) AnimatedBackground(colors: style.gradientColors),
          Container(
            color: Colors.black.withOpacity(0.4), // Add a dark overlay for text readability
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Profile Picture (positioned at the top)
                if (profileImagePath != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: FileImage(File(profileImagePath!)),
                    ),
                  ),
                const Spacer(),

                // Main Question Text
                Text(
                  questionText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    fontFamily: style.fontFamily,
                    height: 1.4,
                  ),
                ),
                const Spacer(),

                // Footer with URL
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        profileUrl,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
