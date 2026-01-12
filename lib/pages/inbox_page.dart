import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/pages/reply_detail_page.dart';
import 'package:mystrio/pages/quiz_results_page.dart';
import 'package:mystrio/pages/answer_page.dart';
import 'package:mystrio/inbox_provider.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:intl/intl.dart'; // Ensure you have intl in pubspec, or use basic formatting
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mystrio/widgets/ad_banner.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final inboxProvider = Provider.of<InboxProvider>(context, listen: false);
      switch (_tabController.index) {
        case 0:
          inboxProvider.setFilter(InboxFilter.all);
          break;
        case 1:
          inboxProvider.setFilter(InboxFilter.qa);
          break;
        case 2:
          inboxProvider.setFilter(InboxFilter.quizzes);
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inbox',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Q&A'),
            Tab(text: 'Quizzes'),
          ],
        ),
      ),
      body: Consumer<InboxProvider>(
        builder: (context, inboxProvider, child) {
          if (inboxProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (inboxProvider.errorMessage != null) {
            return Center(child: Text('Error: ${inboxProvider.errorMessage}'));
          }

          final authService = Provider.of<AuthService>(context, listen: false);
          if (!authService.isFullyAuthenticated) {
            return Center(
              child: Text(
                'Please log in to view your inbox.',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          }

          final inboxNotifications = inboxProvider.filteredInboxItems;

          if (inboxNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'Your inbox is empty!',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your link to get messages.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => inboxProvider.refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: inboxNotifications.length + (kIsWeb ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (kIsWeb && index == 0) {
                  return const WebAdBanner(adSlotId: 'YOUR_AD_SLOT_ID');
                }
                final itemIndex = kIsWeb ? index - 1 : index;
                if (itemIndex < 0 || itemIndex >= inboxNotifications.length) {
                  return const SizedBox.shrink();
                }
                final item = inboxNotifications[itemIndex];
                return _buildNGLStyleCard(context, item, theme, inboxProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNGLStyleCard(BuildContext context, InboxItem item, ThemeData theme, InboxProvider inboxProvider) {
    // 1. Determine Colors and Gradients
    Gradient? backgroundGradient;
    Color backgroundColor = theme.cardColor; // Default for seen items
    Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    Color iconColor = theme.iconTheme.color ?? Colors.black;
    IconData iconData = Icons.email_outlined;
    String headerText = "Message";
    VoidCallback? onTap;

    // NGL-like Gradients (Keep these for unseen items as they are signature "new" indicators)
    const Gradient anonymousGradient = LinearGradient(
      colors: [Color(0xFFFF512F), Color(0xFFDD2476)], // Orange to Pink
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    const Gradient quizGradient = LinearGradient(
      colors: [Color(0xFF4568DC), Color(0xFFB06AB3)], // Blue to Purple
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // 2. Configure based on Item Type
    switch (item.type) {
      case InboxItemType.anonymousQuestion:
        if (item.isSentByMe) {
          backgroundColor = theme.colorScheme.surfaceVariant;
          headerText = "Sent by you";
          iconData = Icons.arrow_upward;
        } else {
          if (!item.isSeen) {
            backgroundGradient = anonymousGradient;
            textColor = Colors.white;
            iconColor = Colors.white;
          }
          headerText = "Anonymous Message";
          iconData = Icons.mark_email_unread_outlined;
          
          onTap = () {
            inboxProvider.markItemAsSeen(item.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnswerPage(
                  questionId: item.questionId!,
                  questionText: item.content,
                ),
              ),
            ).then((_) => inboxProvider.refresh());
          };
        }
        break;

      case InboxItemType.questionReply:
        headerText = "New Reply";
        iconData = Icons.question_answer_outlined;

        if (item.styleId != null) {
          final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
          final style = questionStyleService.getStyleById(item.styleId!);
          
          if (!item.isSeen) {
             backgroundGradient = LinearGradient(
              colors: style.gradientColors,
              begin: style.begin,
              end: style.end,
            );
            textColor = Colors.white; // Assuming gradients are dark/vibrant
            iconColor = Colors.white;
          }
        } else {
           if (!item.isSeen) {
             backgroundGradient = anonymousGradient;
             textColor = Colors.white;
             iconColor = Colors.white;
           }
        }

        onTap = () {
          inboxProvider.markItemAsSeen(item.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReplyDetailPage(
                username: item.ownerUsername,
                questionText: item.title.replaceFirst('Reply to your question:', '').trim(),
                replyText: item.content,
                styleId: item.styleId ?? 'default',
                questionCode: item.questionCode,
              ),
            ),
          );
        };
        break;

      case InboxItemType.quizAnswer:
        headerText = "Quiz Result";
        iconData = Icons.emoji_events_outlined;
        if (!item.isSeen) {
          backgroundGradient = quizGradient;
          textColor = Colors.white;
          iconColor = Colors.white;
        }
        
        onTap = () {
          if (item.id.startsWith('grouped-')) {
            inboxProvider.markQuizGroupAsSeen(item.quizId!);
          } else {
            inboxProvider.markItemAsSeen(item.id);
          }
          if (item.quizId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizResultsPage(quizId: item.quizId!),
              ),
            );
          }
        };
        break;
    }

    // 3. Build the Card
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: backgroundGradient == null ? backgroundColor : null,
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Icon (Watermark style)
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                iconData,
                size: 80,
                color: iconColor.withOpacity(0.1),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        headerText.toUpperCase(),
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      if (!item.isSeen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Main Content
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (item.type == InboxItemType.anonymousQuestion && !item.isSentByMe)
              Positioned(
                top: 8,
                right: 8,
                child: _buildPopupMenu(context, item, inboxProvider),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, InboxItem item, InboxProvider inboxProvider) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _confirmDelete(context, item, inboxProvider);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert, color: Colors.white),
    );
  }

  void _confirmDelete(BuildContext context, InboxItem item, InboxProvider inboxProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to permanently delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await inboxProvider.deleteNotification(item.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted.')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete message.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
