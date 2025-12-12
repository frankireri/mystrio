import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GratitudeProvider with ChangeNotifier {
  static const _gratitudeItemsKey = 'gratitude_items_2023'; // Key for items
  static const _gratitudeHeaderKey = 'gratitude_header_2023'; // Key for custom header
  static const _gratitudeCustomImagePathKey = 'gratitude_custom_image_path_2023'; // Key for custom image
  static const _gratitudeHeaderOffsetXKey = 'gratitude_header_offset_x_2023';
  static const _gratitudeHeaderOffsetYKey = 'gratitude_header_offset_y_2023';
  static const _gratitudeHeaderScaleKey = 'gratitude_header_scale_2023';
  static const _gratitudeUsernameOffsetXKey = 'gratitude_username_offset_x_2023';
  static const _gratitudeUsernameOffsetYKey = 'gratitude_username_offset_y_2023';
  static const _gratitudeUsernameScaleKey = 'gratitude_username_scale_2023';

  List<String> _items = [];
  String _customHeader = 'Things I\'m Grateful For in 2023'; // Default header
  String? _customImagePath; // New property for custom background image
  double _headerOffsetX = 0.0;
  double _headerOffsetY = 0.0;
  double _headerScale = 1.0;
  double _usernameOffsetX = 0.0;
  double _usernameOffsetY = 0.0;
  double _usernameScale = 1.0;
  bool _isLoading = true;

  List<String> get items => _items;
  String get customHeader => _customHeader;
  String? get customImagePath => _customImagePath;
  double get headerOffsetX => _headerOffsetX;
  double get headerOffsetY => _headerOffsetY;
  double get headerScale => _headerScale;
  double get usernameOffsetX => _usernameOffsetX;
  double get usernameOffsetY => _usernameOffsetY;
  double get usernameScale => _usernameScale;
  bool get isLoading => _isLoading;

  GratitudeProvider() {
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    _items = prefs.getStringList(_gratitudeItemsKey) ?? [];
    _customHeader = prefs.getString(_gratitudeHeaderKey) ?? 'Things I\'m Grateful For in 2023';
    _customImagePath = prefs.getString(_gratitudeCustomImagePathKey);
    _headerOffsetX = prefs.getDouble(_gratitudeHeaderOffsetXKey) ?? 0.0;
    _headerOffsetY = prefs.getDouble(_gratitudeHeaderOffsetYKey) ?? 0.0;
    _headerScale = prefs.getDouble(_gratitudeHeaderScaleKey) ?? 1.0;
    _usernameOffsetX = prefs.getDouble(_gratitudeUsernameOffsetXKey) ?? 0.0;
    _usernameOffsetY = prefs.getDouble(_gratitudeUsernameOffsetYKey) ?? 0.0;
    _usernameScale = prefs.getDouble(_gratitudeUsernameScaleKey) ?? 1.0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(String item) async {
    _items.add(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_gratitudeItemsKey, _items);
    notifyListeners();
  }

  Future<void> removeItem(int index) async {
    _items.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_gratitudeItemsKey, _items);
    notifyListeners();
  }

  Future<void> setCustomHeader(String header) async {
    _customHeader = header;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gratitudeHeaderKey, header);
    notifyListeners();
  }

  Future<void> setCustomImagePath(String? path) async {
    _customImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_gratitudeCustomImagePathKey, path);
    } else {
      await prefs.remove(_gratitudeCustomImagePathKey);
    }
    notifyListeners();
  }

  Future<void> setHeaderOffset(Offset offset) async {
    _headerOffsetX = offset.dx;
    _headerOffsetY = offset.dy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_gratitudeHeaderOffsetXKey, offset.dx);
    await prefs.setDouble(_gratitudeHeaderOffsetYKey, offset.dy);
    notifyListeners();
  }

  Future<void> setHeaderScale(double scale) async {
    _headerScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_gratitudeHeaderScaleKey, scale);
    notifyListeners();
  }

  Future<void> setUsernameOffset(Offset offset) async {
    _usernameOffsetX = offset.dx;
    _usernameOffsetY = offset.dy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_gratitudeUsernameOffsetXKey, offset.dx);
    await prefs.setDouble(_gratitudeUsernameOffsetYKey, offset.dy);
    notifyListeners();
  }

  Future<void> setUsernameScale(double scale) async {
    _usernameScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_gratitudeUsernameScaleKey, scale);
    notifyListeners();
  }
}
