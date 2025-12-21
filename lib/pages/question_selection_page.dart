import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mystrio/auth_service.dart';
import 'package:mystrio/services/question_style_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:mystrio/services/user_question_service.dart';
import 'package:mystrio/widgets/custom_app_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mystrio/config/app_config.dart';
import 'package:mystrio/pages/login_page.dart';
import 'package:mystrio/pages/signup_page.dart';

class QuestionSelectionPage extends StatefulWidget {
  final String username;

  const QuestionSelectionPage({super.key, required this.username});

  @override
  State<QuestionSelectionPage> createState() => _QuestionSelectionPageState();
}

class _QuestionSelectionPageState extends State<QuestionSelectionPage> {
  final TextEditingController _questionTextController = TextEditingController();
  String? _selectedStyleId;
  bool _isEditingQuestion = false;
  final FocusNode _questionFocusNode = FocusNode();
  
  String? _currentSharedQuestionCode;
  late final UserQuestionService _userQuestionService;
  late PageController _pageController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isUploadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    _userQuestionService = Provider.of<UserQuestionService>(context, listen: false);

    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
    _selectedStyleId = questionStyleService.allStyles.first.id;
    _questionTextController.text = "send me anonymous messages!";

    _pageController = PageController(viewportFraction: 0.85);

    _questionFocusNode.addListener(_handleFocusChange);
    _generateLink();
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
      _generateLink();
    }
  }

  void _randomize() {
    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
    final allStyles = questionStyleService.allStyles;
    final randomIndex = Random().nextInt(allStyles.length);
    final randomStyle = allStyles[randomIndex];

    setState(() {
      _selectedStyleId = randomStyle.id;
      _isEditingQuestion = false;
      _questionFocusNode.unfocus();
    });

    _pageController.animateToPage(
      randomIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _generateLink();
  }

  Future<void> _pickProfileImage() async {
    if (_isUploadingProfileImage) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _isUploadingProfileImage = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.uploadAndSetProfileImage(image.path);

    if (mounted) {
      setState(() {
        _isUploadingProfileImage = false;
      });
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated!')),
        );
      }
    }
  }

  Future<void> _generateLink() async {
    if (_questionTextController.text.isEmpty) return;

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

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('See Responses to Your Card!'),
          content: const Text(
              'Create an account or log in to save your card and view anonymous responses.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Later'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            ElevatedButton(
              child: const Text('Sign In / Sign Up'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCard() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isFullyAuthenticated) {
      _showLoginPrompt();
      return;
    }

    await _generateLink();
    if (_currentSharedQuestionCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate share link. Please try again.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card saved successfully!')),
    );

    final questionStyleService = Provider.of<QuestionStyleService>(context, listen: false);
    final selectedStyle = questionStyleService.getStyleById(_selectedStyleId!);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final shareableWidget = _buildShareableContent(
      selectedStyle,
      theme,
      screenWidth,
      authService.profileImagePath,
    );

    final screenshot = await _screenshotController.captureFromWidget(
      shareableWidget,
      pixelRatio: 2.0,
      context: context,
    );

    if (screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate share image. Please try again.')),
      );
      return;
    }

    final shareText = 'Send me anonymous messages!\n${AppConfig.baseUrl}/profile/${widget.username}/$_currentSharedQuestionCode';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(screenshot, mimeType: 'image/png', name: 'card.png')],
        text: shareText,
      );
    } else {
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

  Widget _buildShareableContent(QuestionStyle style, ThemeData theme, double screenWidth, String? profileImagePath) {
    ImageProvider? profileImageProvider;
    if (profileImagePath != null) {
      final uri = Uri.tryParse(profileImagePath);
      if (uri != null && uri.isAbsolute) {
        profileImageProvider = NetworkImage(profileImagePath);
      } else {
        profileImageProvider = FileImage(File(profileImagePath));
      }
    }

    return Container(
      width: screenWidth,
      height: screenWidth * 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: style.gradientColors, begin: style.begin, end: style.end),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.5),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.transparent,
              backgroundImage: profileImageProvider,
              child: profileImagePath == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _questionTextController.text,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: style.fontFamily),
            ),
          ),
          const Spacer(flex: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "link below",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          const Column(
            children: [
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
            ],
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final questionStyleService = Provider.of<QuestionStyleService>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final selectedStyle = questionStyleService.getStyleById(_selectedStyleId!);
    final buttonGradient = LinearGradient(
      colors: selectedStyle.gradientColors.map((c) => _darkenColor(c, 0.2)).toList(),
      begin: selectedStyle.begin,
      end: selectedStyle.end,
    );

    final currentQuestionShareLink = _currentSharedQuestionCode != null
        ? '${AppConfig.baseUrl}/profile/${widget.username}/$_currentSharedQuestionCode'
        : 'Link will be generated automatically';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Anonymous Q&A',
        actions: [
          IconButton(
            icon: const Icon(Icons.casino),
            onPressed: _randomize,
            tooltip: 'Randomize',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Hidden widget for capturing screenshots
          Offstage(
            offstage: true,
            child: Screenshot(
              controller: _screenshotController,
              child: _buildShareableContent(selectedStyle, theme, screenWidth, authService.profileImagePath),
            ),
          ),
          // Main visible UI
          GestureDetector(
            onTap: () {
              if (_isEditingQuestion && _questionFocusNode.hasFocus) {
                _questionFocusNode.unfocus();
              }
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: questionStyleService.allStyles.length,
                      onPageChanged: (index) {
                        final style = questionStyleService.allStyles[index];
                        setState(() {
                          _selectedStyleId = style.id;
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
                                if (_questionFocusNode.hasFocus) _questionFocusNode.unfocus();
                                setState(() {
                                  _selectedStyleId = style.id;
                                  _isEditingQuestion = true;
                                  _questionFocusNode.requestFocus();
                                });
                                _generateLink();
                              } else if (_selectedStyleId == style.id && _isEditingQuestion && _questionFocusNode.hasFocus) {
                                _questionFocusNode.unfocus();
                              }
                            },
                            child: SizedBox(
                              width: screenWidth * 0.85,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: theme.cardTheme.elevation,
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              width: screenWidth * 0.85,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: style.gradientColors, begin: style.begin, end: style.end),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Consumer<AuthService>(
                                                    builder: (context, auth, child) {
                                                      final currentProfileImagePath = auth.profileImagePath;
                                                      ImageProvider? profileImageProvider;
                                                      if (currentProfileImagePath != null) {
                                                        final uri = Uri.tryParse(currentProfileImagePath);
                                                        if (uri != null && uri.isAbsolute) {
                                                          profileImageProvider = NetworkImage(currentProfileImagePath);
                                                        } else {
                                                          profileImageProvider = FileImage(File(currentProfileImagePath));
                                                        }
                                                      }
                                                      return GestureDetector(
                                                        onTap: _pickProfileImage,
                                                        child: Stack(
                                                          alignment: Alignment.center,
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 32,
                                                              backgroundColor: Colors.white.withOpacity(0.5),
                                                              child: CircleAvatar(
                                                                radius: 30,
                                                                backgroundColor: Colors.transparent,
                                                                backgroundImage: profileImageProvider,
                                                                child: currentProfileImagePath == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                                                              ),
                                                            ),
                                                            if (_isUploadingProfileImage) const CircularProgressIndicator(),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    child: _isEditingQuestion && isSelected
                                                        ? TextField(
                                                            controller: _questionTextController,
                                                            focusNode: _questionFocusNode,
                                                            textAlign: TextAlign.center,
                                                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: style.fontFamily, fontSize: 16),
                                                            decoration: const InputDecoration(
                                                              border: InputBorder.none,
                                                              focusedBorder: InputBorder.none,
                                                              enabledBorder: InputBorder.none,
                                                              errorBorder: InputBorder.none,
                                                              disabledBorder: InputBorder.none,
                                                              filled: true,
                                                              fillColor: Colors.transparent,
                                                              isDense: true,
                                                              contentPadding: EdgeInsets.zero,
                                                            ),
                                                            maxLines: 3,
                                                            minLines: 1,
                                                            keyboardType: TextInputType.multiline,
                                                            cursorColor: Colors.white,
                                                          )
                                                        : Text(
                                                            _questionTextController.text,
                                                            textAlign: TextAlign.center,
                                                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: style.fontFamily, fontSize: 16),
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
                                                (isSelected && _isEditingQuestion) ? 'Editing...' : 'Tap to Edit',
                                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7), fontStyle: FontStyle.italic),
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
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onBackground),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                                    if (!authService.isFullyAuthenticated) {
                                      _showLoginPrompt();
                                      return;
                                    }
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
        ],
      ),
    );
  }
}
