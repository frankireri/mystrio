import 'dart:html';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

class AdWidget extends StatefulWidget {
  const AdWidget({super.key});

  @override
  State<AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  final String _viewType = 'adView';

  @override
  void initState() {
    super.initState();
    
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final adElement = DivElement()
          ..className = 'adsbygoogle'
          ..style.display = 'block'
          ..dataset['adClient'] = 'ca-pub-9766563679079723'
          ..dataset['adSlot'] = '7739895731'
          ..dataset['adFormat'] = 'auto'
          ..dataset['fullWidthResponsive'] = 'true';

        final adPushScript = ScriptElement()..innerHtml = '(adsbygoogle = window.adsbygoogle || []).push({});';
        
        return DivElement()
          ..style.width = '100%'
          ..style.height = 'auto'
          ..append(adElement)
          ..append(adPushScript);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
