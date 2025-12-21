import 'package:flutter/foundation.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/premium_service.dart';
import 'package:mystrio/api/mystrio_api.dart';

class InboxProvider with ChangeNotifier {
  UserQuestionService? _userQuestionService;
  AuthService? _authService;
  PremiumService? _premiumService;
  final MystrioApi _api;

  List<InboxItem> _inboxItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  InboxProvider(this._api);

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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onAuthStateChanged() {
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    if (_isDisposed) return;

    // Check if we have all necessary dependencies and authentication
    if (_authService == null || !_authService!.isFullyAuthenticated || _userQuestionService == null) {
      // Don't clear items immediately to avoid flickering, but stop loading
      // _inboxItems = []; 
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
        _inboxItems = await _userQuestionService!.getInboxNotificationsForUser(currentUsername);
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

  Future<void> refresh() async {
    await _loadInbox();
  }

  void removeItem(String itemId) {
    _inboxItems.removeWhere((item) => item.id == itemId);
    if (!_isDisposed) notifyListeners();
    // Here you would also call an API to delete the item from the backend
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
    _authService?.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
