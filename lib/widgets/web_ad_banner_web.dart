import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:js' as js; // Import dart:js
import 'package:flutter/material.dart';

class WebAdBanner extends StatefulWidget {
  final String adSlotId; // The specific ad unit ID from AdSense
  final String adFormat; // 'auto', 'rectangle', 'horizontal', etc.
  final bool isTest; // If true, uses a test ad ID (optional)

  const WebAdBanner({
    super.key,
    required this.adSlotId,
    this.adFormat = 'auto',
    this.isTest = false,
  });

  @override
  State<WebAdBanner> createState() => _WebAdBannerState();
}

class _WebAdBannerState extends State<WebAdBanner> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Create a unique ID for this ad view
    _viewId = 'ad-banner-${DateTime.now().millisecondsSinceEpoch}';

    // Register the view factory
    // This tells Flutter: "When asked for '_viewId', render this HTML element"
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final div = html.DivElement();

      // The AdSense <ins> tag
      final ins = html.Element.tag('ins');
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.dataset['ad-client'] = 'ca-pub-XXXXXXXXXXXXXXXX'; // REPLACE THIS with your Publisher ID
      ins.dataset['ad-slot'] = widget.adSlotId;
      ins.dataset['ad-format'] = widget.adFormat;
      ins.dataset['full-width-responsive'] = 'true';

      if (widget.isTest) {
        ins.dataset['ad-test'] = 'on';
      }

      div.append(ins);

      // Trigger the ad load
      // We use a small delay to ensure the element is in the DOM
      html.window.requestAnimationFrame((_) {
        try {
          // Use dart:js to access the global 'adsbygoogle' array
          final adsbygoogle = js.context['adsbygoogle'];
          if (adsbygoogle != null) {
            // Call .push({}) on the array
            adsbygoogle.callMethod('push', [{}]);
          } else {
             // If it doesn't exist, initialize it as an empty array and push
             // Note: This is rare if the script is in head, but good for safety
             final newArray = js.JsObject(js.context['Array']);
             newArray.callMethod('push', [{}]);
             js.context['adsbygoogle'] = newArray;
          }
        } catch (e) {
          print('AdSense Error: $e');
        }
      });

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AdSense banners are responsive, but we need to give the PlatformView some constraints
    // A height of 100-250px is standard for a banner.
    return SizedBox(
      height: 100, 
      width: double.infinity,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
