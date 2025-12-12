import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService with ChangeNotifier {
  static const _isPremiumKey = 'isPremium';

  bool _isPremium = false;

  bool get isPremium => _isPremium;

  PremiumService() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_isPremiumKey) ?? false;
    notifyListeners();
  }

  Future<void> purchasePremium() async {
    // Simulate a purchase
    await Future.delayed(const Duration(seconds: 1));
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, true);
    notifyListeners();
    print('Premium purchased!');
  }
}
