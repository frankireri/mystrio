import 'package:flutter/material.dart';

class WebAdBanner extends StatelessWidget {
  final String adSlotId;
  final String adFormat;
  final bool isTest;

  const WebAdBanner({
    super.key,
    required this.adSlotId,
    this.adFormat = 'auto',
    this.isTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Render nothing on mobile
  }
}
