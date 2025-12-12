import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mystrio/services/gratitude_theme_service.dart';

class GratitudeCard extends StatefulWidget {
  final String username;
  final List<String> items;
  final GratitudeTheme theme;
  final String customHeader;
  final String? customImagePath;
  final Offset initialHeaderOffset;
  final double initialHeaderScale;
  final ValueChanged<Offset>? onHeaderOffsetChanged;
  final ValueChanged<double>? onHeaderScaleChanged;
  final Offset initialUsernameOffset;
  final double initialUsernameScale;
  final ValueChanged<Offset>? onUsernameOffsetChanged;
  final ValueChanged<double>? onUsernameScaleChanged;

  const GratitudeCard({
    super.key,
    required this.username,
    required this.items,
    required this.theme,
    required this.customHeader,
    this.customImagePath,
    this.initialHeaderOffset = Offset.zero,
    this.initialHeaderScale = 1.0,
    this.onHeaderOffsetChanged,
    this.onHeaderScaleChanged,
    this.initialUsernameOffset = Offset.zero,
    this.initialUsernameScale = 1.0,
    this.onUsernameOffsetChanged,
    this.onUsernameScaleChanged,
  });

  @override
  State<GratitudeCard> createState() => _GratitudeCardState();
}

class _GratitudeCardState extends State<GratitudeCard> {
  late Offset _headerOffset;
  late double _headerScale;
  late Offset _usernameOffset;
  late double _usernameScale;

  @override
  void initState() {
    super.initState();
    _headerOffset = widget.initialHeaderOffset;
    _headerScale = widget.initialHeaderScale;
    _usernameOffset = widget.initialUsernameOffset;
    _usernameScale = widget.initialUsernameScale;
  }

  @override
  void didUpdateWidget(covariant GratitudeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHeaderOffset != oldWidget.initialHeaderOffset) {
      _headerOffset = widget.initialHeaderOffset;
    }
    if (widget.initialHeaderScale != oldWidget.initialHeaderScale) {
      _headerScale = widget.initialHeaderScale;
    }
    if (widget.initialUsernameOffset != oldWidget.initialUsernameOffset) {
      _usernameOffset = widget.initialUsernameOffset;
    }
    if (widget.initialUsernameScale != oldWidget.initialUsernameScale) {
      _usernameScale = widget.initialUsernameScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 16,
        );

    return Container(
      width: 350,
      padding: const EdgeInsets.all(25.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: widget.customImagePath != null
            ? DecorationImage(
                image: FileImage(File(widget.customImagePath!)),
                fit: BoxFit.cover,
              )
            : widget.theme.backgroundImagePath != null
                ? DecorationImage(
                    image: AssetImage(widget.theme.backgroundImagePath!),
                    fit: BoxFit.cover,
                  )
                : null,
        gradient: widget.customImagePath == null && widget.theme.backgroundImagePath == null && widget.theme.gradientColors != null
            ? LinearGradient(
                colors: widget.theme.gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Stack(
          children: [
            // Draggable and Resizable Header
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _headerOffset += details.delta;
                    });
                    widget.onHeaderOffsetChanged?.call(_headerOffset);
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _headerScale = (_headerScale * details.scale).clamp(0.5, 3.0);
                    });
                    widget.onHeaderScaleChanged?.call(_headerScale);
                  },
                  child: Transform.translate(
                    offset: _headerOffset,
                    child: Transform.scale(
                      scale: _headerScale,
                      child: Text(
                        widget.customHeader,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Draggable and Resizable Username
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter, // Default position for username
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _usernameOffset += details.delta;
                    });
                    widget.onUsernameOffsetChanged?.call(_usernameOffset);
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _usernameScale = (_usernameScale * details.scale).clamp(0.5, 2.0); // Limit scale
                    });
                    widget.onUsernameScaleChanged?.call(_usernameScale);
                  },
                  child: Transform.translate(
                    offset: _usernameOffset,
                    child: Transform.scale(
                      scale: _usernameScale,
                      child: Text(
                        'by @${widget.username}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gratitude Items (not draggable/resizable yet)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 100, bottom: 100, left: 20, right: 20), // Adjust padding to avoid header/username
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Icon(widget.theme.icon, color: widget.theme.iconColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: textStyle,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
