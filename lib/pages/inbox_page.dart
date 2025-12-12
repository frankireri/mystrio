import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/auth_service.dart'; // To get the current username
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/reply_detail_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userQuestionService = Provider.of<UserQuestionService>(context);
    final theme = Theme.of(context);

    final currentUsername = authService.username ?? 'default';

    final userReplies = userQuestionService.getRepliesForUser(currentUsername);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Inbox'),
      body: userReplies.isEmpty
          ? Center(
              child: Text(
                'No replies yet!',
                style: theme.textTheme.headlineSmall,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: userReplies.length,
              itemBuilder: (context, index) {
                final replyData = userReplies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      replyData['replyText'] ?? 'No reply text',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'To: ${replyData['questionText'] ?? 'Unknown Question'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReplyDetailPage(
                            questionText: replyData['questionText']!,
                            replyText: replyData['replyText']!,
                            styleId: replyData['styleId']!,
                            questionCode: replyData['questionCode'], // Pass questionCode
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
