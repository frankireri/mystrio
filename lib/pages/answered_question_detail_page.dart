import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mystrio/config/app_config.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/widgets/shareable_story_card.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'package:mystrio/auth_service.dart';

class AnsweredQuestionDetailPage extends StatefulWidget {
  final int? answeredQuestionId;
  final AnsweredQuestion? answeredQuestion;
  final String? username;

  const AnsweredQuestionDetailPage({
    super.key,
    this.answeredQuestionId,
    this.answeredQuestion,
    this.username,
  }) : assert(answeredQuestionId != null || answeredQuestion != null,
            'Either answeredQuestionId or answeredQuestion must be provided');

  @override
  State<AnsweredQuestionDetailPage> createState() => _AnsweredQuestionDetailPageState();
}

class _AnsweredQuestionDetailPageState extends State<AnsweredQuestionDetailPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  Future<AnsweredQuestion?>? _answeredQuestionFuture;
  String? _username; // Store username once fetched
  int _selectedGradientIndex = 0; // NEW: State for selected gradient

  final List<List<Color>> _predefinedGradients = [ // NEW: Predefined gradients
    [Colors.deepPurple, Colors.purpleAccent],
    [Colors.red, Colors.pink],
    [Colors.green, Colors.lightGreen],
    [Colors.blue, Colors.lightBlue],
    [Colors.orange, Colors.amber],
  ];

  @override
  void initState() {
    super.initState();
    if (widget.answeredQuestion != null) {
      _answeredQuestionFuture = Future.value(widget.answeredQuestion);
      _username = widget.username;
    } else {
      _fetchAnsweredQuestion();
    }
  }

  Future<void> _fetchAnsweredQuestion() async {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    setState(() {
      _answeredQuestionFuture = userQuestionService.getAnsweredQuestionById(widget.answeredQuestionId!).then((question) async {
        if (question != null) {
          _username = await userQuestionService.getUsernameById(question.userId);
        } else {
           _username = 'unknown_user';
        }
        return question;
      });
    });
  }

  Future<void> _shareAnswer(AnsweredQuestion answeredQuestion) async {
    try {
      final RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final api = Provider.of<MystrioApi>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final authToken = authService.authToken;

        if (authToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to share.')),
          );
          return;
        }

        final response = await api.post(
          '/share/answered-question/${answeredQuestion.id}',
          token: authToken,
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final shortCode = responseData['data']['shortCode'];
            final shareLink = '${AppConfig.baseUrl}/answered-q/$shortCode';
            await Share.shareXFiles(
              [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'mystrio_answer.png')],
              text: 'See my answer on Mystrio! $shareLink',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to generate share link: ${responseData['message']}')),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to generate share link. Status: ${response.statusCode}')),
            );
        }
      }
    } catch (e) {
      debugPrint('Error sharing answer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate share image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Answer',
        actions: [
          FutureBuilder<AnsweredQuestion?>(
            future: _answeredQuestionFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareAnswer(snapshot.data!),
                );
              }
              return const SizedBox.shrink(); // Hide share button while loading
            },
          ),
        ],
      ),
      body: FutureBuilder<AnsweredQuestion?>(
        future: _answeredQuestionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Answered question not found.'));
          }

                      final answeredQuestion = snapshot.data!;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Anonymous asked:',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      answeredQuestion.questionText,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    Text(
                                      answeredQuestion.answerText,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        'Answered on ${DateFormat.yMMMd().format(answeredQuestion.answeredAt)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20), // NEW: Spacing
                            Text(
                              'Choose a background for your shareable card:', // NEW: Title
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10), // NEW: Spacing
                            SizedBox( // NEW: Gradient selection
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _predefinedGradients.length,
                                itemBuilder: (context, index) {
                                  final gradient = _predefinedGradients[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                    child: ChoiceChip(
                                      label: Container(
                                        width: 40,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: gradient),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      selected: _selectedGradientIndex == index,
                                      selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedGradientIndex = index;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),                Offstage(
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: ShareableStoryCard(
                      question: answeredQuestion,
                      username: _username ?? (widget.answeredQuestionId?.toString() ?? 'Unknown'),
                      gradientColors: _predefinedGradients[_selectedGradientIndex], // NEW
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
