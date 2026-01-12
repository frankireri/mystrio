import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/premium_service.dart';
import 'package:mystrio/api/mystrio_api.dart';

const Duration _kInboxPollingInterval = Duration(seconds: 30);

enum InboxFilter { all, qa, quizzes }

class InboxProvider with ChangeNotifier {
  UserQuestionService? _userQuestionService;
  AuthService? _authService;
  PremiumService? _premiumService;
  final MystrioApi _api;

  List<InboxItem> _inboxItems = [];
  InboxFilter _currentFilter = InboxFilter.all;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;
  Timer? _pollingTimer;

  InboxProvider(this._api) {
    _startPolling();
  }

  void setAuthService(AuthService authService) {
    // Always update the reference and listener
    _authService?.removeListener(_onAuthStateChanged);
    _authService = authService;
    _authService?.addListener(_onAuthStateChanged);
    
    // Attempt to load inbox if we have everything we need
    _loadInbox();
  }

  void setUserQuestionService(UserQuestionService userQuestionService) {
    _userQuestionService = userQuestionService;
    _loadInbox();
  }

  void setPremiumService(PremiumService premiumService) {
    _premiumService = premiumService;
  }

  List<InboxItem> get inboxItems => _inboxItems;
  int get unseenItemCount => _inboxItems.where((item) => !item.isSeen).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  InboxFilter get currentFilter => _currentFilter;

  List<InboxItem> get filteredInboxItems {
    switch (_currentFilter) {
      case InboxFilter.qa:
        return _inboxItems
            .where((item) =>
                item.type == InboxItemType.anonymousQuestion ||
                item.type == InboxItemType.questionReply)
            .toList();
      case InboxFilter.quizzes:
        return _inboxItems
            .where((item) => item.type == InboxItemType.quizAnswer)
            .toList();
      case InboxFilter.all:
      default:
        return _inboxItems;
    }
  }

  void setFilter(InboxFilter newFilter) {
    if (_currentFilter != newFilter) {
      _currentFilter = newFilter;
      notifyListeners();
    }
  }

  void _onAuthStateChanged() {
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    if (_isDisposed) return;

    if (_authService == null || !_authService!.isFullyAuthenticated || _userQuestionService == null) {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUsername = _authService!.username;
      if (currentUsername != null) {
        final allItems = await _userQuestionService!.getInboxNotificationsForUser(currentUsername);
        _inboxItems = _groupQuizNotifications(allItems);
      } else {
        _inboxItems = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  List<InboxItem> _groupQuizNotifications(List<InboxItem> items) {
    final grouped = <String, List<InboxItem>>{};
    final nonQuizItems = <InboxItem>[];

    for (final item in items) {
      if (item.type == InboxItemType.quizAnswer && item.quizId != null) {
        grouped.putIfAbsent(item.quizId!, () => []).add(item);
      } else {
        nonQuizItems.add(item);
      }
    }

    final result = <InboxItem>[...nonQuizItems];

    grouped.forEach((quizId, quizItems) {
      if (quizItems.length > 1) {
        final firstItem = quizItems.first;
        final count = quizItems.length;
        final latestTimestamp = quizItems.map((i) => i.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

        result.add(InboxItem(
          id: 'grouped-$quizId',
          type: InboxItemType.quizAnswer,
          ownerUsername: firstItem.ownerUsername,
          senderIdentifier: '$count people',
          title: firstItem.title,
          content: '$count people took your quiz: "${firstItem.title}"',
          timestamp: latestTimestamp,
          quizId: quizId,
          isSeen: quizItems.every((i) => i.isSeen),
        ));
      } else {
        result.addAll(quizItems);
      }
    });

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<void> refresh() async {
    await _loadInbox();
  }

  Future<bool> deleteNotification(String notificationId) async {
    final token = _authService?.authToken;
    if (token == null) {
      debugPrint('Error: Cannot delete notification without auth token.');
      return false;
    }

    try {
      final response = await _api.delete('/notifications/$notificationId', token: token);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _inboxItems.removeWhere((item) => item.id == notificationId);
        notifyListeners();
        return true;
      } else {
        debugPrint('Error deleting notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception when deleting notification: $e');
      return false;
    }
  }

  void removeItem(String itemId) {
    _inboxItems.removeWhere((item) => item.id == itemId);
    if (!_isDisposed) notifyListeners();
    // Here you would also call an API to delete the item from the backend
  }

  Future<void> markQuizGroupAsSeen(String quizId) async {
    final List<String> notificationIdsToMark = _inboxItems
        .where((item) => item.quizId == quizId && !item.isSeen)
        .map((item) => item.id)
        .toList();

    if (notificationIdsToMark.isEmpty) return;

    // Mark as seen locally immediately for instant UI feedback
    for (var item in _inboxItems) {
      if (item.quizId == quizId) {
        item.isSeen = true;
      }
    }
    notifyListeners();

    try {
      await _api.post(
        '/notifications/mark-seen',
        token: _authService?.authToken,
        body: {'notificationIds': notificationIdsToMark},
      );
    } catch (e) {
      debugPrint('Error marking quiz group as seen: $e');
      // Optionally revert the local change if the API call fails
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(_kInboxPollingInterval, (timer) {
      if (_authService != null && _authService!.isFullyAuthenticated) {
        refresh();
      }
    });
  }

  Future<void> markItemAsSeen(String itemId) async {
    final index = _inboxItems.indexWhere((item) => item.id == itemId);
    if (index != -1 && !_inboxItems[index].isSeen) {
      _inboxItems[index].isSeen = true;
      if (!_isDisposed) notifyListeners();
      try {
        await _api.post(
          '/notifications/mark-seen',
          token: _authService?.authToken,
          body: {
            'notificationIds': [itemId]
          },
        );
      } catch (e) {
        debugPrint('Error marking notification as seen: $e');
      }
    }
  }

  Future<String?> getSenderHint(int questionId) async {
    if (_premiumService == null || !_premiumService!.isPremium) {
      return 'Premium required to reveal hints!';
    }
    if (_authService == null || !_authService!.isFullyAuthenticated) {
      return 'Log in to reveal hints!';
    }
    try {
      final hint = await _userQuestionService!.getQuestionSenderHint(questionId);
      return hint ?? 'No hint available.';
    } catch (e) {
      return 'Error revealing hint: $e';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _authService?.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
