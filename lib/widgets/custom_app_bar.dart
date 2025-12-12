import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.backgroundColor,
    this.bottom,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _titleAnimation;
  late Animation<Offset> _actionsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _titleAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _actionsAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine foreground color based on background luminance
    final Color effectiveBackgroundColor = widget.backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final bool isLight = effectiveBackgroundColor.computeLuminance() > 0.5;
    final Color foregroundColor = isLight ? Colors.black : Colors.white;

    return AppBar(
      title: SlideTransition(
        position: _titleAnimation,
        child: Text(widget.title, style: theme.appBarTheme.titleTextStyle?.copyWith(color: foregroundColor)),
      ),
      actions: [
        SlideTransition(
          position: _actionsAnimation,
          child: IconTheme(
            data: IconThemeData(color: foregroundColor), // Apply foreground color to actions
            child: Row(
              children: widget.actions,
            ),
          ),
        ),
      ],
      backgroundColor: effectiveBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: foregroundColor), // Apply foreground color to back button
      bottom: widget.bottom,
    );
  }
}
