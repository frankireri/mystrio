import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/gratitude_provider.dart';
import 'package:mystrio/services/gratitude_theme_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:mystrio/widgets/custom_loading_indicator.dart';
import 'package:mystrio/widgets/gratitude_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class GratitudePage extends StatefulWidget {
  const GratitudePage({super.key});

  @override
  State<GratitudePage> createState() => _GratitudePageState();
}

class _GratitudePageState extends State<GratitudePage> {
  final _itemTextController = TextEditingController();
  final _headerTextController = TextEditingController();
  final _screenshotController = ScreenshotController();
  String _selectedThemeId = 'serene'; // Default theme

  final List<String> _predefinedHeaders = [
    'Things I\'m Grateful For in 2023',
    'Things I Wish For Christmas',
    'Things I Want For Next Year',
    'My New Year\'s Resolutions',
  ];

  @override
  void initState() {
    super.initState();
    final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
    _headerTextController.text = gratitudeProvider.customHeader;
    _headerTextController.addListener(_onHeaderChanged);
    // Initialize selected theme based on whether a custom image is present
    if (gratitudeProvider.customImagePath != null) {
      _selectedThemeId = 'custom_image';
    }
  }

  @override
  void dispose() {
    _itemTextController.dispose();
    _headerTextController.removeListener(_onHeaderChanged);
    _headerTextController.dispose();
    super.dispose();
  }

  void _onHeaderChanged() {
    Provider.of<GratitudeProvider>(context, listen: false).setCustomHeader(_headerTextController.text);
  }

  void _addItem() {
    if (_itemTextController.text.isNotEmpty) {
      Provider.of<GratitudeProvider>(context, listen: false).addItem(_itemTextController.text);
      _itemTextController.clear();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Provider.of<GratitudeProvider>(context, listen: false).setCustomImagePath(image.path);
      // Deselect any theme-based background when a custom image is picked
      setState(() {
        _selectedThemeId = 'custom_image'; // A dummy ID to indicate custom image is active
      });
    } else {
      // If user cancels image picking, clear custom image path
      Provider.of<GratitudeProvider>(context, listen: false).setCustomImagePath(null);
      // Revert to default theme if no custom image
      setState(() {
        _selectedThemeId = 'serene';
      });
    }
  }

  void _shareGratitudeList() async {
    final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final gratitudeThemeService = Provider.of<GratitudeThemeService>(context, listen: false);

    final username = authService.username ?? 'user';
    final selectedTheme = gratitudeThemeService.getThemeById(_selectedThemeId);

    final image = await _screenshotController.captureFromWidget(
      GratitudeCard(
        username: username,
        items: gratitudeProvider.items,
        theme: selectedTheme,
        customHeader: gratitudeProvider.customHeader,
        customImagePath: gratitudeProvider.customImagePath,
        initialHeaderOffset: Offset(gratitudeProvider.headerOffsetX, gratitudeProvider.headerOffsetY),
        initialHeaderScale: gratitudeProvider.headerScale,
      ),
      delay: const Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/gratitude_list.png').create();
    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Check out my gratitude list on Mystrio!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final gratitudeProvider = Provider.of<GratitudeProvider>(context);
    final gratitudeThemeService = Provider.of<GratitudeThemeService>(context);
    final theme = Theme.of(context);
    final selectedGratitudeTheme = gratitudeThemeService.getThemeById(_selectedThemeId);

    // Determine background for the page based on custom image or selected theme
    Decoration? pageDecoration;
    if (gratitudeProvider.customImagePath != null) {
      pageDecoration = BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(gratitudeProvider.customImagePath!)),
          fit: BoxFit.cover,
        ),
      );
    } else if (selectedGratitudeTheme.gradientColors != null) {
      pageDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: selectedGratitudeTheme.gradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Gratitude Jar',
        backgroundColor: gratitudeProvider.customImagePath != null
            ? Colors.transparent // AppBar background will be part of the image
            : selectedGratitudeTheme.gradientColors != null
                ? selectedGratitudeTheme.gradientColors![0]
                : Colors.transparent,
      ),
      body: Container(
        decoration: pageDecoration,
        child: gratitudeProvider.isLoading
            ? const CustomLoadingIndicator()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Header:',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _headerTextController,
                          decoration: InputDecoration(
                            labelText: 'Custom Header',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _predefinedHeaders.length,
                            itemBuilder: (context, index) {
                              final header = _predefinedHeaders[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(header),
                                  selected: _headerTextController.text == header,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _headerTextController.text = header;
                                    }
                                  },
                                  selectedColor: theme.colorScheme.secondary,
                                  labelStyle: TextStyle(
                                    color: _headerTextController.text == header ? Colors.black : Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(gratitudeProvider.customImagePath != null ? 'Change Custom Image' : 'Pick Custom Image'),
                        ),
                        if (gratitudeProvider.customImagePath != null)
                          TextButton.icon(
                            onPressed: () {
                              Provider.of<GratitudeProvider>(context, listen: false).setCustomImagePath(null);
                              setState(() {
                                _selectedThemeId = 'serene'; // Revert to default theme selection
                              });
                            },
                            icon: const Icon(Icons.clear, color: Colors.red),
                            label: const Text('Remove Custom Image', style: TextStyle(color: Colors.red)),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Choose a theme for your card:',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: gratitudeThemeService.allThemes.length,
                      itemBuilder: (context, index) {
                        final currentTheme = gratitudeThemeService.allThemes[index];
                        final isSelected = currentTheme.id == _selectedThemeId && gratitudeProvider.customImagePath == null;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedThemeId = currentTheme.id;
                              Provider.of<GratitudeProvider>(context, listen: false).setCustomImagePath(null); // Clear custom image
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: currentTheme.backgroundImagePath != null
                                  ? DecorationImage(
                                      image: AssetImage(currentTheme.backgroundImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: currentTheme.backgroundImagePath == null &&
                                      currentTheme.gradientColors != null
                                  ? LinearGradient(
                                      colors: currentTheme.gradientColors!,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              border: isSelected
                                  ? Border.all(color: theme.colorScheme.secondary, width: 3)
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                currentTheme.icon,
                                color: currentTheme.iconColor,
                                size: 40,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: gratitudeProvider.items.isEmpty
                        ? Center(
                            child: Text(
                              'Add items to your list!',
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: gratitudeProvider.items.length,
                            itemBuilder: (context, index) {
                              final item = gratitudeProvider.items[index];
                              return ListTile(
                                leading: Icon(selectedGratitudeTheme.icon, color: selectedGratitudeTheme.iconColor),
                                title: Text(item, style: const TextStyle(color: Colors.white)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    gratitudeProvider.removeItem(index);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemTextController,
                            decoration: const InputDecoration(
                              labelText: 'Add something you\'re grateful for...',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addItem,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  if (gratitudeProvider.items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ElevatedButton.icon(
                        onPressed: _shareGratitudeList,
                        icon: const Icon(Icons.share),
                        label: const Text('Share My Gratitude List'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
