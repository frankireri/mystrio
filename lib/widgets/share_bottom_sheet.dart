import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:share_plus/share_plus.dart';

class ShareBottomSheet extends StatelessWidget {
  final String shareText;
  final String shareUrl;

  const ShareBottomSheet({
    super.key,
    required this.shareText,
    required this.shareUrl,
  });

  void _shareToPlatform(BuildContext context, String platform) {
    // In a real app, you'd use platform-specific sharing logic here.
    // For example, using share_plus with specific app identifiers or deep links.
    print('Sharing to $platform: $shareText $shareUrl');
    Share.share('$shareText $shareUrl', subject: 'Mystrio Share');
    Navigator.of(context).pop(); // Close the bottom sheet
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share Your Mystrio Link',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildShareOption(context, 'Instagram', Icons.camera_alt, () => _shareToPlatform(context, 'Instagram')),
              _buildShareOption(context, 'WhatsApp', Icons.chat, () => _shareToPlatform(context, 'WhatsApp')),
              _buildShareOption(context, 'Facebook', Icons.facebook, () => _shareToPlatform(context, 'Facebook')),
              _buildShareOption(context, 'Twitter', Icons.alternate_email, () => _shareToPlatform(context, 'Twitter')),
              _buildShareOption(context, 'Copy Link', Icons.copy, () {
                Clipboard.setData(ClipboardData(text: shareUrl)); // Copy link to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
                Navigator.of(context).pop(); // Close the bottom sheet
              }),
              // Add more social media options as needed
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, String name, IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: theme.colorScheme.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
