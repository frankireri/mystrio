import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/premium_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/pages/inbox_page.dart';
import 'package:mystrio/pages/owner_profile_page.dart';
import 'package:mystrio/pages/signup_page.dart';
import 'package:mystrio/pages/login_page.dart';
import 'package:mystrio/pages/post_submit_page.dart';
import 'package:mystrio/pages/question_selection_page.dart';
import 'package:mystrio/pages/initial_page.dart';
import 'package:mystrio/quiz_provider.dart';
import 'package:mystrio/pages/create_quiz_page.dart';
import 'package:mystrio/pages/quiz_page.dart';
import 'package:mystrio/pages/game_selection_page.dart';
import 'package:mystrio/gratitude_provider.dart';
import 'package:mystrio/services/gratitude_theme_service.dart';
import 'package:mystrio/services/theme_service.dart';
import 'package:mystrio/pages/my_quizzes_page.dart';
import 'package:mystrio/pages/home_dashboard_page.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:mystrio/pages/public_profile_page.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/pages/my_cards_page.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'package:mystrio/inbox_provider.dart';
import 'package:mystrio/pages/answered_question_detail_page.dart';

class ComingSoonPage extends StatelessWidget {
  final String featureName;
  const ComingSoonPage({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              '$featureName Coming Soon!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'We\'re working hard to bring you this exciting feature.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => MystrioApi()),
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => PremiumService()),
        ChangeNotifierProvider(create: (context) => QuestionStyleService()),
        ChangeNotifierProxyProvider<AuthService, UserQuestionService>(
          create: (context) => UserQuestionService(
            Provider.of<MystrioApi>(context, listen: false),
          ),
          update: (context, auth, service) {
            service!.setAuthService(auth);
            return service;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, UserQuestionService, QuestionProvider>(
          create: (context) => QuestionProvider(),
          update: (context, auth, userQuestionService, provider) {
            provider!
              ..setAuthService(auth)
              ..setUserQuestionService(userQuestionService);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, UserQuestionService, QuizProvider>(
          create: (context) => QuizProvider(),
          update: (context, authService, userQuestionService, quizProvider) {
            quizProvider!
              ..setAuthService(authService)
              ..setUserQuestionService(userQuestionService);
            return quizProvider;
          },
        ),
        ChangeNotifierProxyProvider3<AuthService, UserQuestionService, PremiumService, InboxProvider>(
          create: (context) => InboxProvider(
            Provider.of<MystrioApi>(context, listen: false),
          ),
          update: (context, auth, userQuestionService, premiumService, inboxProvider) {
            inboxProvider!
              ..setAuthService(auth)
              ..setUserQuestionService(userQuestionService)
              ..setPremiumService(premiumService);
            return inboxProvider;
          },
        ),
        ChangeNotifierProvider(create: (context) => GratitudeProvider()),
        Provider(create: (context) => GratitudeThemeService()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? link) {
      _handleLink(link);
    });
  }

  void _handleLink(Uri? link) {
    if (link == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (link.pathSegments.isNotEmpty && link.pathSegments.first == 'profile') {
        final username = link.pathSegments[1];
        bool isAskingAnonymous = false;

        if (link.pathSegments.length > 2) {
          if (link.pathSegments[2] == 'ask') {
            isAskingAnonymous = true;
          }
        }
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PublicProfilePage(
              username: username,
              isAskingAnonymous: isAskingAnonymous,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Mystrio',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeService.themeMode,
          home: const InitialPage(),
          routes: {
            '/inbox': (context) => const InboxPage(),
            '/my-profile': (context) => const OwnerProfilePage(),
            '/signup': (context) => const SignUpPage(),
            '/login': (context) => const LoginPage(),
            '/post-submit': (context) => const PostSubmitPage(username: 'default'),
            '/create-quiz': (context) => const CreateQuizPage(),
            '/gratitude': (context) => const ComingSoonPage(featureName: 'Gratitude Jar'),
            '/my-quizzes': (context) => const MyQuizzesPage(),
            '/home-dashboard': (context) => const HomeDashboardPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == null) return null;
            final uri = Uri.parse(settings.name!);

            if (uri.pathSegments.isNotEmpty) {
              switch (uri.pathSegments.first) {
                case 'profile':
                  if (uri.pathSegments.length > 1) {
                    final username = uri.pathSegments[1];
                    bool isAskingAnonymous = uri.pathSegments.length > 2 && uri.pathSegments[2] == 'ask';
                    return MaterialPageRoute(
                      builder: (context) => PublicProfilePage(username: username, isAskingAnonymous: isAskingAnonymous),
                    );
                  }
                  break;
                case 'answered-q': // NEW: Handle answered question deep links
                  if (uri.pathSegments.length > 1) {
                    final shortCode = uri.pathSegments[1];
                    return MaterialPageRoute(
                      builder: (context) => FutureBuilder<AnsweredQuestion?>(
                        future: Provider.of<UserQuestionService>(context, listen: false).getAnsweredQuestionByShortCode(shortCode),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(body: Center(child: CircularProgressIndicator()));
                          } else if (snapshot.hasError) {
                            return Scaffold(body: Center(child: Text('Error loading answered question: ${snapshot.error}')));
                          } else if (!snapshot.hasData || snapshot.data == null) {
                            return const Scaffold(body: Center(child: Text('Answered question not found.')));
                          }
                          final answeredQuestion = snapshot.data!;
                          // Need to find the username associated with this answered question
                          return FutureBuilder<String?>(
                            future: Provider.of<UserQuestionService>(context, listen: false).getUsernameById(answeredQuestion.userId),
                            builder: (context, usernameSnapshot) {
                              if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                                return const Scaffold(body: Center(child: CircularProgressIndicator()));
                              } else if (usernameSnapshot.hasError) {
                                return Scaffold(body: Center(child: Text('Error loading username: ${usernameSnapshot.error}')));
                              } else if (!usernameSnapshot.hasData || usernameSnapshot.data == null) {
                                return const Scaffold(body: Center(child: Text('Username not found.')));
                              }
                              return AnsweredQuestionDetailPage(answeredQuestion: answeredQuestion, username: usernameSnapshot.data!);
                            },
                          );
                        },
                      ),
                    );
                  }
                  break;
                case 'select-question':
                  if (uri.pathSegments.length > 1) {
                    final username = uri.pathSegments[1];
                    return MaterialPageRoute(
                      builder: (context) => QuestionSelectionPage(username: username),
                    );
                  }
                  break;
                case 'quiz':
                  if (uri.pathSegments.length > 1) {
                    final username = uri.pathSegments[1];
                    final quizId = uri.queryParameters['id'];
                    if (quizId != null) {
                      return MaterialPageRoute(
                        builder: (context) => QuizPage(username: username, quizId: quizId),
                      );
                    }
                  }
                  break;
                case 'game-selection':
                  if (uri.pathSegments.length > 1) {
                    final username = uri.pathSegments[1];
                    return MaterialPageRoute(
                      builder: (context) => GameSelectionPage(username: username, isNewUser: true),
                    );
                  }
                  break;
                case 'my-cards':
                  if (uri.pathSegments.length > 1) {
                    final username = uri.pathSegments[1];
                    return MaterialPageRoute(
                      builder: (context) => MyCardsPage(username: username),
                    );
                  }
                  break;
              }
            }
            return MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Page not found'))));
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
        primary: Colors.deepPurple,
        onPrimary: Colors.white,
        secondary: Colors.pinkAccent,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
        error: Colors.red.shade700,
        onError: Colors.white,
      ).copyWith(
        background: Colors.grey.shade100,
        onBackground: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textTheme: _buildLightTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurple, width: 2)),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      ),
    );
  }

  TextTheme _buildLightTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins', color: Colors.black87),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
        primary: Colors.deepPurple.shade300,
        onPrimary: Colors.black,
        secondary: Colors.pinkAccent.shade100,
        onSecondary: Colors.black,
        surface: Colors.grey.shade900,
        error: Colors.red.shade400,
        onError: Colors.black,
      ).copyWith(
        background: Colors.black,
        onBackground: Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textTheme: _buildDarkTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade300,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.deepPurple.shade300,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade800,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade700,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2)),
        labelStyle: TextStyle(color: Colors.grey.shade300),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.deepPurple.shade300,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      ),
    );
  }

  TextTheme _buildDarkTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins', color: Colors.white70),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins', color: Colors.white70),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins', color: Colors.white70),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins', color: Colors.white),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins', color: Colors.white),
    );
  }
}
