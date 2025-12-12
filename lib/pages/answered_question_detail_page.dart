import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/question_provider.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/widgets/question_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class AnsweredQuestionDetailPage extends StatefulWidget {
  final Question question;

  const AnsweredQuestionDetailPage({super.key, required this.question});

  @override
  State<AnsweredQuestionDetailPage> createState() => _AnsweredQuestionDetailPageState();
}

class _AnsweredQuestionDetailPageState extends State<AnsweredQuestionDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  void _shareAnsweredQuestion() async {
    final image = await _screenshotController.captureFromWidget(
      QuestionCard(
        question: widget.question,
        isAnswered: true,
      ),
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/answered_question.png').create();
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Check out my answer on Mystrio!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Answer',
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
            onPressed: _shareAnsweredQuestion,
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: QuestionCard(
            question: widget.question,
            isAnswered: true,
            // No onTap here as it's already answered and on a detail page
          ),
        ),
      ),
    );
  }
}
