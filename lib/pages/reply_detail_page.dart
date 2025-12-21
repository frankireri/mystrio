import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ReplyDetailPage extends StatefulWidget {
  final String username;
  final String questionText;
  final String replyText;
  final String styleId;
  final String? questionCode;

  const ReplyDetailPage({
    super.key,
    required this.username,
    required this.questionText,
    required this.replyText,
    required this.styleId,
    this.questionCode,
  });

  @override
  State<ReplyDetailPage> createState() => _ReplyDetailPageState();
}

class _ReplyDetailPageState extends State<ReplyDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareReplyAsImage() async {
    final screenshot = await _screenshotController.capture(
      delay: const Duration(milliseconds: 10),
    );

    if (screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate share image.')),
      );
      return;
    }

    final shareLink = widget.questionCode != null
        ? 'https://mystrio.app/profile/${widget.username}/${widget.questionCode}'
        : 'https://mystrio.app';

    final shareText = 'Check out this anonymous reply to my question: "${widget.questionText}". Answer it yourself: $shareLink';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(screenshot, mimeType: 'image/png', name: 'reply.png')],
        text: shareText,
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/reply.png').create();
      await imagePath.writeAsBytes(screenshot);
      await Share.shareXFiles([XFile(imagePath.path)], text: shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final style = questionStyleService.getStyleById(widget.styleId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reply Details'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: style.gradientColors,
                            begin: style.begin,
                            end: style.end,
                          ),
                        ),
                        child: Text(
                          widget.questionText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.replyText,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.questionCode != null)
                ElevatedButton.icon(
                  onPressed: _shareReplyAsImage,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Reply'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
