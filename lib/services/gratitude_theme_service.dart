import 'package:flutter/material.dart';

class GratitudeTheme {
  final String id;
  final String name;
  final List<Color>? gradientColors; // Make nullable
  final String? backgroundImagePath; // New property
  final IconData icon;
  final Color iconColor;

  GratitudeTheme({
    required this.id,
    required this.name,
    this.gradientColors,
    this.backgroundImagePath, // Initialize new property
    required this.icon,
    required this.iconColor,
  }) : assert(gradientColors != null || backgroundImagePath != null,
            'Either gradientColors or backgroundImagePath must be provided.');
}

class GratitudeThemeService {
  final List<GratitudeTheme> _themes = [
    GratitudeTheme(
      id: 'serene',
      name: 'Serene',
      gradientColors: [const Color(0xFF1a237e), const Color(0xFF673ab7)],
      icon: Icons.star,
      iconColor: Colors.amber,
    ),
    GratitudeTheme(
      id: 'joyful',
      name: 'Joyful',
      gradientColors: [Colors.orange, Colors.pinkAccent],
      icon: Icons.favorite,
      iconColor: Colors.red.shade300,
    ),
    GratitudeTheme(
      id: 'cozy',
      name: 'Cozy',
      gradientColors: [Colors.brown.shade700, Colors.deepOrange.shade900],
      icon: Icons.coffee,
      iconColor: Colors.brown.shade200,
    ),
    // New image-based theme
    GratitudeTheme(
      id: 'note_1',
      name: 'Note 1',
      backgroundImagePath: 'assets/gratitude_backgrounds/note_1.png', // Placeholder, replace with your image
      icon: Icons.book,
      iconColor: Colors.pink.shade200,
    ),
    GratitudeTheme(
      id: 'note_2',
      name: 'Note 2',
      backgroundImagePath: 'assets/gratitude_backgrounds/note_2.png', // Placeholder, replace with your image
      icon: Icons.book,
      iconColor: Colors.pink.shade200,
    ),
    GratitudeTheme(
      id: 'note_3',
      name: 'Note 3',
      backgroundImagePath: 'assets/gratitude_backgrounds/note_3.png', // Placeholder, replace with your image
      icon: Icons.book,
      iconColor: Colors.pink.shade200,
    ),
    GratitudeTheme(
      id: 'sky_1',
      name: 'Sky 1',
      backgroundImagePath: 'assets/gratitude_backgrounds/sky_1.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'sky_2',
      name: 'Sky 2',
      backgroundImagePath: 'assets/gratitude_backgrounds/sky_2.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'sunset_1',
      name: 'Sunset 1',
      backgroundImagePath: 'assets/gratitude_backgrounds/sunset_1.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'islands_1',
      name: 'Islands 1',
      backgroundImagePath: 'assets/gratitude_backgrounds/islands_1.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'christmas_1',
      name: 'Christmas 1',
      backgroundImagePath: 'assets/gratitude_backgrounds/christmas_1.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'christmas_2',
      name: 'Christmas 2',
      backgroundImagePath: 'assets/gratitude_backgrounds/christmas_2.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'christmas_3',
      name: 'Christmas 3',
      backgroundImagePath: 'assets/gratitude_backgrounds/christmas_3.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'christmas_4',
      name: 'Christmas 4',
      backgroundImagePath: 'assets/gratitude_backgrounds/christmas_4.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
    GratitudeTheme(
      id: 'christmas_5',
      name: 'Christmas 5',
      backgroundImagePath: 'assets/gratitude_backgrounds/christmas_5.png', // Placeholder, replace with your image
      icon: Icons.auto_awesome,
      iconColor: Colors.yellow.shade700,
    ),
  ];

  List<GratitudeTheme> get allThemes => _themes;

  GratitudeTheme getThemeById(String id) {
    return _themes.firstWhere((theme) => theme.id == id, orElse: () => _themes.first);
  }
}
