import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/reply_detail_page.dart';
import 'package:mystrio/pages/quiz_results_page.dart'; // Import QuizResultsPage

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

    final inboxNotifications = userQuestionService.getInboxNotificationsForUser(currentUsername);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Inbox'),
      body: inboxNotifications.isEmpty
          ? Center(
              child: Text(
                'Your inbox is empty!',
                style: theme.textTheme.headlineSmall,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: inboxNotifications.length,
              itemBuilder: (context, index) {
                final item = inboxNotifications[index];
                return _buildInboxCard(context, item, theme);
              },
            ),
    );
  }

  Widget _buildInboxCard(BuildContext context, InboxItem item, ThemeData theme) {
    Color cardColor;
    IconData icon;
    String subtitlePrefix;
    VoidCallback onTap;

    switch (item.type) {
      case InboxItemType.questionReply:
        cardColor = theme.colorScheme.primary.withOpacity(0.1);
        icon = Icons.question_answer;
        subtitlePrefix = 'Reply to: ';
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReplyDetailPage(
                questionText: item.questionCode!, // Assuming questionCode is not null for replies
                replyText: item.content,
                styleId: item.styleId!, // Assuming styleId is not null for replies
                questionCode: item.questionCode,
              ),
            ),
          );
        };
        break;
      case InboxItemType.quizAnswer:
        cardColor = theme.colorScheme.secondary.withOpacity(0.1);
        icon = Icons.quiz;
        subtitlePrefix = 'Quiz: ';
        onTap = () {
          if (item.quizId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizResultsPage(quizId: item.quizId!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz details not available.')),
            );
          }
        };
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Icon(icon, color: theme.colorScheme.onPrimary),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${subtitlePrefix}${item.type == InboxItemType.questionReply ? item.questionCode : item.quizId}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            Text(
              '${item.timestamp.hour}:${item.timestamp.minute} - ${item.timestamp.day}/${item.timestamp.month}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
        onTap: onTap,
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      ),
    );
  }
}
