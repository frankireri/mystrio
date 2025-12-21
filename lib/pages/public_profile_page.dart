import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/api/mystrio_api.dart';
import 'package:mystrio/pages/answered_question_detail_page.dart';
import 'package:mystrio/pages/response_sent_page.dart'; // NEW
import 'package:intl/intl.dart';
import 'dart:convert'; // Ensure this is imported
import 'dart:math'; // Import for Random

class PublicProfilePage extends StatefulWidget {
  final String username;
  final bool isAskingAnonymous;

  const PublicProfilePage({
    super.key,
    required this.username,
    this.isAskingAnonymous = false,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final TextEditingController _anonymousQuestionController = TextEditingController();
  int? _recipientUserId;
  bool _isSubmitting = false;

  Future<List<AnsweredQuestion>>? _answeredQuestionsFuture;

  final List<String> _predefinedAnonymousQuestions = [
    'What\'s one thing you wish people knew about you?',
    'What\'s a secret talent you have?',
    'What are you most passionate about?',
    'If you could travel anywhere, where would you go?',
    'What makes you happy?',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isAskingAnonymous) {
      _fetchRecipientUserId();
    } else {
      _loadAnsweredQuestions();
    }
  }

  Future<void> _fetchRecipientUserId() async {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    try {
      final userId = await userQuestionService.getUserIdByUsername(widget.username);
      if (mounted) {
        setState(() {
          _recipientUserId = userId;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recipient user ID: $e');
    }
  }

  void _loadAnsweredQuestions() {
    final userQuestionService = Provider.of<UserQuestionService>(context, listen: false);
    setState(() {
      _answeredQuestionsFuture = userQuestionService.getAnsweredQuestions(widget.username);
    });
  }

  Future<void> _submitAnonymousQuestion() async {
    if (_isSubmitting || _anonymousQuestionController.text.isEmpty) return;
    if (_recipientUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find user. Please try again later.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final api = Provider.of<MystrioApi>(context, listen: false);
    try {
      final httpResponse = await api.post( // Renamed to httpResponse to avoid confusion
        '/questions/anonymous',
        body: {
          'recipientUserId': _recipientUserId,
          'questionText': _anonymousQuestionController.text,
        },
      );

      if (mounted) {
        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
          final responseData = jsonDecode(httpResponse.body); // Correctly decode JSON
          if (responseData['success']) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ResponseSentPage(username: widget.username, isAnonymous: true),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send question: ${responseData['message']}')),
            );
          }
        } else {
          String errorMessage = 'Failed to send question. Server responded with status ${httpResponse.statusCode}';
          try {
            final errorData = jsonDecode(httpResponse.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            // If body is not JSON, use generic message
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAskingAnonymous) {
      return _buildAnonymousQuestionUI();
    } else {
      return _buildPublicProfileUI();
    }
  }

  Widget _buildPublicProfileUI() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: '@${widget.username}'),
      body: RefreshIndicator(
        onRefresh: () async => _loadAnsweredQuestions(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildAskQuestionHeader(theme),
            ),
            _buildAnsweredQuestionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAskQuestionHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Ask @${widget.username} anything!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PublicProfilePage(
                  username: widget.username,
                  isAskingAnonymous: true,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Send Anonymous Question'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweredQuestionsList() {
    return FutureBuilder<List<AnsweredQuestion>>(
      future: _answeredQuestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This user hasn\'t answered any questions yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          final answeredQuestions = snapshot.data!;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildAnsweredQuestionCard(answeredQuestions[index]);
              },
              childCount: answeredQuestions.length,
            ),
          );
        }
      },
    );
  }

  Widget _buildAnsweredQuestionCard(AnsweredQuestion item) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AnsweredQuestionDetailPage(
              answeredQuestionId: item.id,
              username: widget.username,
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.questionText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                item.answerText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Answered ${DateFormat.yMMMd().format(item.answeredAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousQuestionUI() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: 'Ask @${widget.username}'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Your question will be sent anonymously.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _anonymousQuestionController,
              decoration: InputDecoration(
                hintText: 'Type your question here...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final randomIndex = Random().nextInt(_predefinedAnonymousQuestions.length);
                    _anonymousQuestionController.text = _predefinedAnonymousQuestions[randomIndex];
                  });
                },
                icon: const Icon(Icons.casino),
                label: const Text('Dice Roll a Question'),
              ),
            ),
            const SizedBox(height: 20),
            if (_recipientUserId == null)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnonymousQuestion,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Send Question'),
              ),
          ],
        ),
      ),
    );
  }
}
