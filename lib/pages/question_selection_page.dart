import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:mystrio/widgets/shareable_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:url_launcher/url_launcher.dart' as url_launcher; // Alias url_launcher
import 'package:mystrio/services/user_question_service.dart'; // Import the new service
import 'package:mystrio/widgets/custom_app_bar.dart'; // Reverted to standard import
import 'package:flutter/foundation.dart' show kIsWeb;

class QuestionSelectionPage extends StatefulWidget {
  final String username;

  const QuestionSelectionPage({super.key, required this.username});

  @override
  State<QuestionSelectionPage> createState() => _QuestionSelectionPageState();
}

class _QuestionSelectionPageState extends State<QuestionSelectionPage> {
  final TextEditingController _questionTextController = TextEditingController();
  String? _selectedStyleId;
  XFile? _backgroundImage;
  bool _isEditingQuestion = false;
  final FocusNode _questionFocusNode = FocusNode();
  
  String? _currentSharedQuestionCode; // New: Stores the persistent code for the current question
  late final UserQuestionService _userQuestionService;
  late PageController _pageController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _userQuestionService = UserQuestionService();

    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
    _selectedStyleId = questionStyleService.allStyles.first.id;
    _questionTextController.text = questionStyleService.getStyleById(_selectedStyleId!).defaultQuestion;

    _pageController = PageController(viewportFraction: 0.85);

    _questionFocusNode.addListener(_handleFocusChange);
    _generateLink(); // Auto-generate link on initial load
  }

  @override
  void dispose() {
    _questionFocusNode.removeListener(_handleFocusChange);
    _questionTextController.dispose();
    _questionFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_questionFocusNode.hasFocus && _isEditingQuestion) {
      setState(() {
        _isEditingQuestion = false;
      });
      _generateLink(); // Auto-generate link when editing is finished
    }
  }

  void _randomize() {
    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
    final allStyles = questionStyleService.allStyles;
    final randomIndex = Random().nextInt(allStyles.length);
    final randomStyle = allStyles[randomIndex];

    setState(() {
      _selectedStyleId = randomStyle.id;
      _backgroundImage = null;
      _isEditingQuestion = false;
      _questionFocusNode.unfocus();
    });

    _pageController.animateToPage(
      randomIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _generateLink(); // Auto-generate link on randomize
  }

  Future<void> _pickCardBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _backgroundImage = image;
    });
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Provider.of<AuthService>(context, listen: false).setProfileImagePath(image.path);
    }
  }

  Future<void> _generateLink() async {
    if (_questionTextController.text.isEmpty) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final code = await _userQuestionService.saveOrUpdateQuestion(
        username: widget.username,
        questionText: _questionTextController.text,
        styleId: _selectedStyleId!,
        existingCode: _currentSharedQuestionCode,
      );

      if (mounted) {
        setState(() {
          _currentSharedQuestionCode = code;
        });
      }

      authService.setChosenQuestion(_questionTextController.text, _selectedStyleId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update link: $e')),
        );
      }
    }
  }

  Future<void> _shareCard() async {
    await _generateLink(); // Ensure the latest card is saved
    if (_currentSharedQuestionCode == null) return;

    final screenshot = await _screenshotController.capture();
    if (screenshot == null) return;

    final shareText = 'Send me anonymous messages!\nhttps://mystrio.app/profile/${widget.username}/$_currentSharedQuestionCode';

    if (kIsWeb) {
      // For web, share the image bytes directly
      await Share.shareXFiles(
        [XFile.fromData(screenshot, mimeType: 'image/png', name: 'card.png')],
        text: shareText,
      );
    } else {
      // For mobile, save to a file first
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/card.png').create();
      await imagePath.writeAsBytes(screenshot);
      await Share.shareXFiles([XFile(imagePath.path)], text: shareText);
    }
  }

  Color _darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final selectedStyle = questionStyleService.getStyleById(_selectedStyleId!);
    final buttonGradient = LinearGradient(
      colors: selectedStyle.gradientColors.map((c) => _darkenColor(c, 0.2)).toList(),
      begin: selectedStyle.begin,
      end: selectedStyle.end,
    );

    final currentQuestionShareLink = _currentSharedQuestionCode != null
        ? 'https://mystrio.app/profile/${widget.username}/$_currentSharedQuestionCode'
        : 'Link will be generated automatically';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Anonymous Q&A',
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.casino, color: theme.colorScheme.onSurface),
            onPressed: _randomize,
            tooltip: 'Randomize',
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: GestureDetector(
          onTap: () {
            if (_isEditingQuestion && _questionFocusNode.hasFocus) {
              _questionFocusNode.unfocus();
            }
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 30),
                Screenshot(
                  controller: _screenshotController,
                  child: SizedBox(
                    height: 280, // Increased height for the card carousel
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: questionStyleService.allStyles.length,
                      onPageChanged: (index) {
                        final style = questionStyleService.allStyles[index];
                        setState(() {
                          _selectedStyleId = style.id;
                          _backgroundImage = null;
                          _isEditingQuestion = false;
                          _questionFocusNode.unfocus();
                        });
                        _generateLink();
                      },
                      itemBuilder: (context, index) {
                        final style = questionStyleService.allStyles[index];
                        final isSelected = style.id == _selectedStyleId;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.9),
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedStyleId != style.id || !_isEditingQuestion) {
                                if (_questionFocusNode.hasFocus) {
                                  _questionFocusNode.unfocus();
                                }

                                setState(() {
                                  _selectedStyleId = style.id;
                                  _backgroundImage = null;
                                  _isEditingQuestion = true;
                                  _questionFocusNode.requestFocus();
                                });
                                _generateLink(); // Auto-generate link on style change
                              } else if (_selectedStyleId == style.id && _isEditingQuestion && _questionFocusNode.hasFocus) {
                                _questionFocusNode.unfocus();
                              }
                            },
                            child: SizedBox(
                              width: screenWidth * 0.85, // Card width as a percentage of screen width
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: theme.cardTheme.elevation,
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              width: screenWidth * 0.85,
                                              decoration: BoxDecoration(
                                                image: _backgroundImage != null && isSelected
                                                    ? DecorationImage(
                                                        image: FileImage(File(_backgroundImage!.path)),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                                gradient: _backgroundImage != null && isSelected
                                                    ? null
                                                    : LinearGradient(
                                                        colors: style.gradientColors,
                                                        begin: style.begin,
                                                        end: style.end,
                                                      ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Consumer<AuthService>(
                                                    builder: (context, authService, child) {
                                                      final currentProfileImagePath = authService.profileImagePath;
                                                      final selectedStyle = questionStyleService.getStyleById(_selectedStyleId!);

                                                      return GestureDetector(
                                                        onTap: _pickProfileImage,
                                                        child: Container(
                                                          width: 65,
                                                          height: 65,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 3),
                                                          ),
                                                          child: CircleAvatar(
                                                            radius: 30,
                                                            backgroundColor: Colors.transparent,
                                                            backgroundImage: currentProfileImagePath != null
                                                                ? FileImage(File(currentProfileImagePath))
                                                                : null,
                                                            child: currentProfileImagePath == null
                                                                ? Container(
                                                                    decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      gradient: LinearGradient(
                                                                        colors: selectedStyle.gradientColors,
                                                                        begin: Alignment.topLeft,
                                                                        end: Alignment.bottomRight,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    child: _isEditingQuestion && isSelected
                                                        ? Theme(
                                                            data: Theme.of(context).copyWith(
                                                              highlightColor: Colors.transparent,
                                                              splashColor: Colors.transparent,
                                                              hoverColor: Colors.transparent,
                                                              focusColor: Colors.transparent,
                                                            ),
                                                            child: TextField(
                                                              controller: _questionTextController,
                                                              focusNode: _questionFocusNode,
                                                              textAlign: TextAlign.center,
                                                              style: theme.textTheme.titleLarge?.copyWith(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontFamily: style.fontFamily,
                                                                fontSize: 16,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                border: InputBorder.none,
                                                                enabledBorder: InputBorder.none,
                                                                focusedBorder: InputBorder.none,
                                                                isDense: true,
                                                                contentPadding: EdgeInsets.zero,
                                                                filled: true,
                                                                fillColor: Colors.transparent,
                                                              ),
                                                              maxLines: 3,
                                                              minLines: 1,
                                                              keyboardType: TextInputType.multiline,
                                                              cursorColor: Colors.white,
                                                            ),
                                                          )
                                                        : Text(
                                                            _questionTextController.text,
                                                            textAlign: TextAlign.center,
                                                            style: theme.textTheme.titleLarge?.copyWith(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontFamily: style.fontFamily,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 50,
                                            width: screenWidth * 0.85,
                                            color: theme.colorScheme.surface,
                                            child: Center(
                                              child: Text(
                                                (isSelected && _isEditingQuestion)
                                                    ? 'Editing...'
                                                    : 'Tap to Edit',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    style.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickCardBackgroundImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Card Background Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Step 1: Copy Your Link',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentQuestionShareLink,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _generateLink();
                                if (_currentSharedQuestionCode != null) {
                                  await Clipboard.setData(ClipboardData(text: currentQuestionShareLink));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copied to clipboard!')),
                                  );
                                }
                              },
                              icon: Icon(Icons.copy, color: selectedStyle.gradientColors.first),
                              label: Text(
                                'Copy Link',
                                style: TextStyle(color: selectedStyle.gradientColors.first),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: selectedStyle.gradientColors.first),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Step 2: Share Link on Your Story',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: buttonGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _shareCard,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
