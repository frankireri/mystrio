import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus

class ReplyDetailPage extends StatelessWidget {
  final String questionText;
  final String replyText;
  final String styleId;
  final String? questionCode; // Added questionCode for sharing

  const ReplyDetailPage({
    super.key,
    required this.questionText,
    required this.replyText,
    required this.styleId,
    this.questionCode, // Made optional
  });

  @override
  Widget build(BuildContext context) {
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final style = questionStyleService.getStyleById(styleId);
    final theme = Theme.of(context);

    // Construct the shareable link if questionCode is available
    final shareLink = questionCode != null
        ? 'https://mystrio.app/profile/YOUR_USERNAME_HERE/$questionCode' // Placeholder for username
        : 'https://mystrio.app'; // Fallback link

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reply Details'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored Top Section (Question)
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
                    questionText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // White Bottom Section (Answer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centered text
                    children: [
                      Text(
                        replyText,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Larger and bold
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Share.share('Check out this anonymous reply: "$replyText" to my question "$questionText". Create your own: $shareLink');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Reply'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
